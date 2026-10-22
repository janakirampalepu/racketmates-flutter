import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/billing_platform.dart';
import 'package:racketmates/common/billing/billing_sync.dart';

class PlansUnavailable implements Exception {
  const PlansUnavailable();
}

class SubscriptionState {
  const SubscriptionState({
    this.plans = const AsyncLoading(),
    this.selected = PlanPeriod.yearly,
    this.busy = false,
    this.restoreMessage,
  });

  final AsyncValue<List<StorePlan>> plans;

  /// The yearly plan is preselected (native).
  final PlanPeriod selected;

  /// A purchase or a restore is in progress.
  final bool busy;

  /// Result of the last restore, for the user (null = none yet).
  final RestoreResult? restoreMessage;

  StorePlan? plan(PlanPeriod period) =>
      plans.value?.where((p) => p.period == period).firstOrNull;

  StorePlan? get selectedPlan => plan(selected);

  /// Percent saved by the yearly plan against twelve months of the monthly one.
  int? get savingPercent {
    final monthly = plan(PlanPeriod.monthly)?.priceMicros;
    final yearly = plan(PlanPeriod.yearly)?.priceMicros;
    if (monthly == null || yearly == null || monthly <= 0 || yearly <= 0) {
      return null;
    }
    final saved = ((monthly * 12 - yearly) / (monthly * 12) * 100).round();
    return saved > 0 ? saved : null;
  }

  SubscriptionState copyWith({
    AsyncValue<List<StorePlan>>? plans,
    PlanPeriod? selected,
    bool? busy,
    RestoreResult? restoreMessage,
  }) => SubscriptionState(
    plans: plans ?? this.plans,
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
    restoreMessage: restoreMessage ?? this.restoreMessage,
  );
}

enum RestoreResult { restored, nothingToRestore, failed }

/// The subscription screen's state: the store's plans, the choice, buying
/// and restoring. The purchase result itself arrives through
/// [purchaseOutcomeProvider].
class SubscriptionController extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    Future.microtask(load);
    return const SubscriptionState();
  }

  BillingPlatform get _platform => ref.read(billingPlatformProvider);

  Future<void> load() async {
    state = state.copyWith(plans: const AsyncLoading());
    try {
      if (!ref.read(billingSupportedProvider) ||
          !await _platform.isAvailable()) {
        throw const PlansUnavailable();
      }
      final ids = ref.read(productIdsProvider);
      final plans = await _platform.plans([ids.monthly, ids.yearly]);
      if (!ref.mounted) return;
      if (plans.isEmpty) throw const PlansUnavailable();
      state = state.copyWith(plans: AsyncData(plans));
    } on Object catch (error, stack) {
      if (ref.mounted) {
        state = state.copyWith(plans: AsyncError(error, stack));
      }
    }
  }

  void select(PlanPeriod period) => state = state.copyWith(selected: period);

  /// Starts the store's purchase sheet for the chosen plan.
  Future<void> buy() async {
    final plan = state.selectedPlan;
    final session = ref.read(sessionControllerProvider);
    if (plan == null || state.busy || session is! SignedIn) return;
    ref.read(purchaseOutcomeProvider.notifier).set(null);
    state = state.copyWith(busy: true);
    await _platform.purchase(
      plan.id,
      accountId: session.token.user?.uuid ?? '',
    );
    // The outcome (success, cancelled, ...) clears `busy` through
    // [purchaseDone].
  }

  /// The store answered: the screen may be used again.
  void purchaseDone() {
    if (ref.mounted && state.busy) state = state.copyWith(busy: false);
  }

  /// iOS "Restore purchases": syncs with the store and links what it finds.
  Future<void> restore() async {
    if (state.busy || !storeHasRestore(defaultTargetPlatform)) return;
    state = state.copyWith(busy: true);
    var result = RestoreResult.failed;
    try {
      final records = await _platform.restore();
      if (records.isEmpty) {
        result = RestoreResult.nothingToRestore;
      } else {
        final linked = await ref
            .read(billingServiceProvider)
            .handle(records.last);
        result = linked ? RestoreResult.restored : RestoreResult.failed;
      }
    } on Object {
      result = RestoreResult.failed;
    }
    if (ref.mounted) {
      state = SubscriptionState(
        plans: state.plans,
        selected: state.selected,
        restoreMessage: result,
      );
    }
  }

  Future<void> redeemCode() => _platform.redeemCode();
}

final subscriptionControllerProvider =
    NotifierProvider.autoDispose<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );
