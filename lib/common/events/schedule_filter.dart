import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner/sport filter for the Schedule and Team Schedule lists (native
/// `EventFilterPicker`/`EventsFilterSheet`), persisted separately per
/// context (native `GLOBAL_SCHEDULE_LIST_FILTER_*` vs
/// `TEAM_SCHEDULE_LIST_FILTER_*` — one shared setting for every team, not
/// per team id, matching native).
const ownershipManaging = 'managing';
const ownershipParticipant = 'participant';

class ScheduleFilter {
  const ScheduleFilter({
    this.ownerships = const {ownershipManaging, ownershipParticipant},
    this.sportTypes = const {},
  });

  /// Never empty in practice (native resets to both when it would be);
  /// enforced by [ScheduleFilterNotifier.setOwnerships].
  final Set<String> ownerships;

  /// Empty means no sport filter is sent (native: an empty `sport_types[]`
  /// is never attached to the request at all).
  final Set<String> sportTypes;

  List<String> get eventRoles => ownerships.toList()..sort();

  List<String>? get sportTypesOrNull =>
      sportTypes.isEmpty ? null : (sportTypes.toList()..sort());

  ScheduleFilter copyWith({Set<String>? ownerships, Set<String>? sportTypes}) =>
      ScheduleFilter(
        ownerships: ownerships ?? this.ownerships,
        sportTypes: sportTypes ?? this.sportTypes,
      );
}

abstract class ScheduleFilterStore {
  Future<ScheduleFilter?> read();
  Future<void> write(ScheduleFilter filter);
}

class PrefsScheduleFilterStore implements ScheduleFilterStore {
  PrefsScheduleFilterStore(this.isTeamContext, [SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final bool isTeamContext;
  final SharedPreferencesAsync _prefs;

  String get _ownershipKey => isTeamContext
      ? 'team_schedule_filter_ownerships'
      : 'global_schedule_filter_ownerships';
  String get _sportsKey => isTeamContext
      ? 'team_schedule_filter_sport_types'
      : 'global_schedule_filter_sport_types';

  @override
  Future<ScheduleFilter?> read() async {
    final ownerships = await _prefs.getStringList(_ownershipKey);
    if (ownerships == null) return null;
    final sportTypes = await _prefs.getStringList(_sportsKey) ?? const [];
    return ScheduleFilter(
      ownerships: ownerships.isEmpty
          ? const {ownershipManaging, ownershipParticipant}
          : ownerships.toSet(),
      sportTypes: sportTypes.toSet(),
    );
  }

  @override
  Future<void> write(ScheduleFilter filter) => Future.wait([
    _prefs.setStringList(_ownershipKey, filter.ownerships.toList()),
    _prefs.setStringList(_sportsKey, filter.sportTypes.toList()),
  ]);
}

final scheduleFilterStoreProvider = Provider.family<ScheduleFilterStore, bool>(
  (ref, isTeamContext) => PrefsScheduleFilterStore(isTeamContext),
);

/// Sports the signed-in account plays (player or coach role), used to decide
/// which sport chips the filter sheet offers (native `getSportsForAccount`,
/// computed here off the signed-in user's own roles rather than every
/// selected family member's — a documented scope simplification). The sport
/// filter is only meaningful, and only shown, when there is more than one.
final accountSportsProvider = FutureProvider<Set<SportKey>>((ref) async {
  final user = await ref.watch(userProfileProvider.future);
  final sports = <SportKey>{};
  for (final role in user?.userRoles ?? const <UserRole>[]) {
    for (final roleSport in role.userRoleSports ?? const <UserRoleSport>[]) {
      final sport = SportKey.fromKey(roleSport.sportType);
      if (sport != null) sports.add(sport);
    }
  }
  return sports;
});

/// One filter per context (`false` = global Schedule, `true` = Team
/// Schedule). Starts with the default (both ownerships, no sport filter)
/// and is replaced once the persisted value (if any) and the account's
/// sports are known — native `setDefaultFilterParams`/`getFilterAppliedData`.
class ScheduleFilterNotifier extends Notifier<ScheduleFilter> {
  ScheduleFilterNotifier(this.isTeamContext);

  final bool isTeamContext;

  @override
  ScheduleFilter build() {
    Future.microtask(_load);
    return const ScheduleFilter();
  }

  ScheduleFilterStore get _store =>
      ref.read(scheduleFilterStoreProvider(isTeamContext));

  Future<void> _load() async {
    final stored = await _store.read();
    if (!ref.mounted) return;
    if (stored != null) {
      state = stored;
      return;
    }
    // No stored choice yet: default to every sport the account plays, same
    // as native's first-run default — but only when there is more than one,
    // otherwise no sport filter is sent at all.
    final sports = await ref.read(accountSportsProvider.future);
    if (!ref.mounted) return;
    if (sports.length > 1) {
      state = state.copyWith(sportTypes: sports.map((s) => s.key).toSet());
    }
  }

  void setOwnerships(Set<String> ownerships) {
    final next = ownerships.isEmpty ? state.ownerships : ownerships;
    state = state.copyWith(ownerships: next);
    unawaited(_store.write(state));
  }

  void setSportTypes(Set<String> sportTypes) {
    state = state.copyWith(sportTypes: sportTypes);
    unawaited(_store.write(state));
  }
}

final scheduleFilterProvider =
    NotifierProvider.family<ScheduleFilterNotifier, ScheduleFilter, bool>(
      ScheduleFilterNotifier.new,
    );
