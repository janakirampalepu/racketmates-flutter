import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_access.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_schedule_tab.dart';

/// The team's full schedule (native `TeamHomeFragment`'s own schedule list),
/// reached from Team Home's "See all" on the Upcoming-events section —
/// the same pattern Home uses to reach the main Schedule tab. Carries the
/// team's "Add event" entry point (native/the global Schedule tab's own
/// FAB), which Team Home itself does not have.
class TeamScheduleScreen extends ConsumerWidget {
  const TeamScheduleScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final team = ref.watch(teamDetailsProvider(teamId));
    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        title: Text(l10n.teamTabSchedule),
      ),
      floatingActionButton: team.whenOrNull(
        data: (t) =>
            memberAccess(
                  t,
                  TeamSettingsPermissions.createEvent,
                  subscribed: true,
                ) ==
                AccessDecision.hidden
            ? null
            : TestId(
                TeamDetailsTestIds.scheduleCreateEvent,
                child: FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.teamCreateEvent),
                  onPressed: () => startTeamCreateEvent(context, ref, t),
                ),
              ),
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TestId(
                TeamDetailsTestIds.error,
                child: Text(l10n.teamDetailsLoadError),
              ),
              TestId(
                TeamDetailsTestIds.retry,
                child: TextButton(
                  onPressed: () => ref.invalidate(teamDetailsProvider(teamId)),
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        ),
        data: (t) =>
            TeamScheduleTab(teamId: teamId, archived: t.archived ?? false),
      ),
    );
  }
}
