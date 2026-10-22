import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/billing_platform.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/billing/subscription_controller.dart';
import 'package:racketmates/common/billing/subscription_prompt.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';

/// The subscription offer (native `SubscriptionPicker` / `SubscriptionPaywallView`):
/// what a subscription gives, the monthly and yearly plan with the store's
/// prices, and the purchase. Access is never granted here: it comes from
/// `session_info` once the backend has linked the purchase.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _benefits = PageController();
  int _benefit = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    // A leftover result from an earlier visit must not show here.
    Future.microtask(() {
      if (mounted) ref.read(purchaseOutcomeProvider.notifier).set(null);
    });
  }

  @override
  void dispose() {
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final kind = ref.read(shownPromptProvider);
    final userId = ref.read(sessionControllerProvider) is SignedIn
        ? (ref.read(sessionControllerProvider) as SignedIn).token.user?.id
        : null;
    if (kind != null && userId != null) {
      ref.read(shownPromptProvider.notifier).set(null);
      await ref.read(subscriptionPromptStoreProvider).markSeen(kind, userId);
    }
    if (mounted) context.pop();
  }

  Future<void> _open(Uri uri) => ref.read(externalLinksProvider).open(uri);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final apple = defaultTargetPlatform == TargetPlatform.iOS;

    ref.listen(purchaseOutcomeProvider, (_, outcome) {
      if (outcome == null) return;
      controller.purchaseDone();
      ref.read(purchaseOutcomeProvider.notifier).set(null);
      switch (outcome) {
        case PurchaseOutcome.success:
          context.pushReplacement(AppRoutes.subscriptionSuccess);
        case PurchaseOutcome.pending:
          setState(() => _message = l10n.subscriptionPending);
        case PurchaseOutcome.cancelled:
          setState(() => _message = l10n.subscriptionCancelled);
        case PurchaseOutcome.failed:
          setState(() => _message = l10n.subscriptionFailed);
        case PurchaseOutcome.linkFailed:
          setState(() => _message = l10n.subscriptionLinkFailed);
      }
    });
    ref.listen(subscriptionControllerProvider.select((s) => s.restoreMessage), (
      _,
      result,
    ) {
      if (result == null) return;
      setState(
        () => _message = switch (result) {
          RestoreResult.restored => l10n.subscriptionRestored,
          RestoreResult.nothingToRestore => l10n.subscriptionNothingToRestore,
          RestoreResult.failed => l10n.subscriptionRestoreFailed,
        },
      );
    });

    final benefits = [
      (
        ref.msg(MessageKeys.subBenefit1Title, l10n.subscriptionBenefit1Title),
        ref.msg(MessageKeys.subBenefit1Text, l10n.subscriptionBenefit1Text),
        Icons.groups_outlined,
      ),
      (
        ref.msg(MessageKeys.subBenefit2Title, l10n.subscriptionBenefit2Title),
        ref.msg(MessageKeys.subBenefit2Text, l10n.subscriptionBenefit2Text),
        Icons.diversity_3_outlined,
      ),
      (
        ref.msg(MessageKeys.subBenefit3Title, l10n.subscriptionBenefit3Title),
        ref.msg(MessageKeys.subBenefit3Text, l10n.subscriptionBenefit3Text),
        Icons.support_agent,
      ),
    ];

    Widget plans() => state.plans.when(
      loading: () => Center(
        child: TestId(
          SubscriptionTestIds.loading,
          child: Semantics(
            label: l10n.chatConnecting,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, _) => Column(
        children: [
          TestId(
            SubscriptionTestIds.error,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.subscriptionUnavailable,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TestId(
            SubscriptionTestIds.retry,
            child: TextButton(
              onPressed: controller.load,
              child: Text(l10n.retryAction),
            ),
          ),
        ],
      ),
      data: (list) => Column(
        children: [
          for (final period in [PlanPeriod.yearly, PlanPeriod.monthly])
            if (state.plan(period) != null)
              _PlanCard(
                plan: state.plan(period)!,
                selected: state.selected == period,
                badge:
                    period == PlanPeriod.yearly && state.savingPercent != null
                    ? l10n.subscriptionSave(state.savingPercent!)
                    : null,
                perMonth: period == PlanPeriod.yearly
                    ? _perMonth(state.plan(period)!, l10n)
                    : null,
                onTap: () => controller.select(period),
              ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TestId(
            SubscriptionTestIds.close,
            child: IconButton(
              tooltip: l10n.subscriptionClose,
              icon: const Icon(Icons.close),
              onPressed: _close,
            ),
          ),
        ],
      ),
      body: TestId(
        SubscriptionTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TestId(
              SubscriptionTestIds.title,
              child: Semantics(
                header: true,
                child: Text(
                  ref.msg(MessageKeys.subProTitle, l10n.subscriptionTitle),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TestId(
              SubscriptionTestIds.benefits,
              child: SizedBox(
                height: 150,
                child: PageView(
                  controller: _benefits,
                  onPageChanged: (i) => setState(() => _benefit = i),
                  children: [
                    for (final (title, text, icon) in benefits)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Icon(icon, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(text, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < benefits.length; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _benefit
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            plans(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              TestId(
                SubscriptionTestIds.message,
                child: Semantics(
                  liveRegion: true,
                  child: Text(_message!, textAlign: TextAlign.center),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TestId(
              SubscriptionTestIds.upgrade,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: state.busy || state.selectedPlan == null
                    ? null
                    : () {
                        setState(() => _message = null);
                        unawaited(controller.buy());
                      },
                child: state.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        ref.msg(
                          MessageKeys.subUpgrade,
                          l10n.subscriptionUpgrade,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TestId(
                  SubscriptionTestIds.redeem,
                  child: TextButton(
                    onPressed: () => apple
                        ? controller.redeemCode()
                        : _open(SubscriptionLinks.redeemAndroid),
                    child: Text(
                      ref.msg(MessageKeys.subRedeem, l10n.subscriptionRedeem),
                    ),
                  ),
                ),
                if (storeHasRestore(defaultTargetPlatform))
                  TestId(
                    SubscriptionTestIds.restore,
                    child: TextButton(
                      onPressed: state.busy ? null : controller.restore,
                      child: Text(
                        ref.msg(
                          MessageKeys.subRestore,
                          l10n.subscriptionRestore,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              apple
                  ? l10n.subscriptionPaymentIos
                  : ref.msg(
                      MessageKeys.subPaymentAndroid,
                      l10n.subscriptionPaymentAndroid,
                    ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TestId(
                  SubscriptionTestIds.terms,
                  child: TextButton(
                    onPressed: () => _open(
                      apple
                          ? SubscriptionLinks.termsApple
                          : SubscriptionLinks.termsAndroid,
                    ),
                    child: Text(
                      ref.msg(MessageKeys.subTerms, l10n.subscriptionTerms),
                    ),
                  ),
                ),
                TestId(
                  SubscriptionTestIds.privacy,
                  child: TextButton(
                    onPressed: () => _open(SubscriptionLinks.privacy),
                    child: Text(
                      ref.msg(MessageKeys.subPrivacy, l10n.subscriptionPrivacy),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The yearly price spread over twelve months, when the store gave one.
  String? _perMonth(StorePlan plan, AppLocalizations l10n) {
    final micros = plan.priceMicros;
    if (micros == null || micros <= 0) return null;
    final money = NumberFormat.simpleCurrency(
      name: plan.currencyCode,
      locale: Localizations.localeOf(context).toString(),
    ).format(micros / 12 / 1000000);
    return l10n.subscriptionPerMonth(money);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
    this.perMonth,
  });

  final StorePlan plan;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final String? perMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final yearly = plan.period == PlanPeriod.yearly;
    final name = plan.title.isNotEmpty
        ? plan.title
        : (yearly ? l10n.subscriptionYearly : l10n.subscriptionMonthly);
    return TestId(
      yearly ? SubscriptionTestIds.yearly : SubscriptionTestIds.monthly,
      child: Semantics(
        button: true,
        selected: selected,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (perMonth != null) Text(perMonth!),
                        if (badge != null)
                          TestId(
                            SubscriptionTestIds.saveBadge,
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    plan.price,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
