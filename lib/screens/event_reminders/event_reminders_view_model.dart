import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:racketmates/common/settings/settings_repository.dart';

class RemindersState {
  const RemindersState({
    this.reminders = const AsyncLoading(),
    this.busy = false,
    this.failed = false,
  });

  final AsyncValue<List<ReminderPreference>> reminders;

  /// A reminder is being added or removed.
  final bool busy;

  /// The last add/remove was rejected.
  final bool failed;

  RemindersState copyWith({
    AsyncValue<List<ReminderPreference>>? reminders,
    bool? busy,
    bool? failed,
  }) => RemindersState(
    reminders: reminders ?? this.reminders,
    busy: busy ?? this.busy,
    failed: failed ?? this.failed,
  );
}

/// The user's reminder preferences (native `PushNotificationViewModel`).
class EventRemindersViewModel extends Notifier<RemindersState> {
  @override
  RemindersState build() {
    Future.microtask(load);
    return const RemindersState();
  }

  int? get _userId {
    final session = ref.read(sessionControllerProvider);
    return session is SignedIn ? session.token.user?.id : null;
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    state = state.copyWith(reminders: const AsyncLoading(), failed: false);
    try {
      final list = await ref.read(settingsRepositoryProvider).reminders(userId);
      if (ref.mounted) state = state.copyWith(reminders: AsyncData(list));
    } on AppFailure catch (failure, stack) {
      if (ref.mounted) {
        state = state.copyWith(reminders: AsyncError(failure, stack));
      }
    }
  }

  Future<bool> add({required int value, required String unit}) => _change(
    (repo, userId) => repo.addReminder(userId, value: value, unit: unit),
  );

  Future<bool> remove(int reminderId) =>
      _change((repo, userId) => repo.removeReminder(userId, reminderId));

  /// Runs a change, then reloads the list (native reloads after each change).
  Future<bool> _change(
    Future<void> Function(SettingsRepository repo, int userId) action,
  ) async {
    final userId = _userId;
    if (userId == null || state.busy) return false;
    state = state.copyWith(busy: true, failed: false);
    try {
      await action(ref.read(settingsRepositoryProvider), userId);
      if (!ref.mounted) return true;
      final list = await ref.read(settingsRepositoryProvider).reminders(userId);
      if (ref.mounted) {
        state = state.copyWith(reminders: AsyncData(list), busy: false);
      }
      return true;
    } on AppFailure {
      if (ref.mounted) state = state.copyWith(busy: false, failed: true);
      return false;
    }
  }
}

final eventRemindersViewModelProvider =
    NotifierProvider.autoDispose<EventRemindersViewModel, RemindersState>(
      EventRemindersViewModel.new,
    );
