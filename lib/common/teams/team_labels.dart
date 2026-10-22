import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Fallback label of a team type key (server labels come from reference data).
String teamTypeLabel(AppLocalizations l10n, String? key) => switch (key) {
  TeamTypes.casual => l10n.teamTypeCasual,
  TeamTypes.competitive => l10n.teamTypeCompetitive,
  _ => humanizeKey(key),
};

/// "Tennis, Padel" for a team's sport keys.
String teamSportsText(AppLocalizations l10n, Team team) => [
  for (final key in team.sportKeys)
    if (SportKey.fromKey(key) case final sport?) sportLabel(l10n, sport),
].join(', ');

/// "Captain, Player" for the roles of one member.
String memberRolesText(AppLocalizations l10n, TeamPlayer member) => [
  if (member.isCaptain ?? false) l10n.teamRoleCaptain,
  if (member.isPlayer ?? false) l10n.teamRolePlayer,
  if (member.isCoach ?? false) l10n.teamRoleCoach,
].join(', ');
