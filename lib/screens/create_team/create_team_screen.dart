import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/common/widgets/team_type_cards.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_team/create_team_test_ids.dart';

/// Team basics (native `NewTeamFragment`): name, type, sports, player ranking
/// and the creator's own roles. The creator is always the captain.
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(createTeamFlowProvider).name,
  );
  List<TeamDetailsError> _errors = const [];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createTeamFlowProvider);
    final flow = ref.read(createTeamFlowProvider.notifier);
    final profile = ref.watch(userProfileProvider).value;
    // The creator can only play or coach with that role on the account (an
    // unknown profile shows both).
    bool hasRole(String role) =>
        profile == null || profile.roleOf(role) != null;
    final errorColor = Theme.of(context).colorScheme.error;

    Widget error(String id, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TestId(
        id,
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: TextStyle(color: errorColor)),
        ),
      ),
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );

    return StepScaffold(
      rootId: CreateTeamTestIds.root,
      titleId: CreateTeamTestIds.title,
      title: ref.msg(MessageKeys.teamCreateNavTitle, l10n.createTeamTitle),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateTeamTestIds.next,
      onPrimary: () {
        final errors = validateTeamDetails(draft);
        setState(() => _errors = errors);
        if (errors.isEmpty) context.push(AppRoutes.createTeamMembers);
      },
      onBack: () => context.pop(),
      children: [
        TestId(
          CreateTeamTestIds.name,
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: ref.msg(
                MessageKeys.teamCreateNameLabel,
                l10n.createTeamNameLabel,
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              flow.setName(v);
              if (_errors.contains(TeamDetailsError.nameRequired)) {
                setState(
                  () => _errors = [
                    for (final e in _errors)
                      if (e != TeamDetailsError.nameRequired) e,
                  ],
                );
              }
            },
          ),
        ),
        if (_errors.contains(TeamDetailsError.nameRequired))
          error(CreateTeamTestIds.nameError, l10n.createTeamNameRequired),
        heading(
          ref.msg(MessageKeys.teamCreateTypeLabel, l10n.createTeamTypeLabel),
        ),
        TeamTypeCards(
          selected: draft.teamType,
          testIdFor: CreateTeamTestIds.type,
          onSelect: (key) {
            flow.setType(key);
            setState(
              () => _errors = [
                for (final e in _errors)
                  if (e != TeamDetailsError.typeRequired) e,
              ],
            );
          },
        ),
        if (_errors.contains(TeamDetailsError.typeRequired))
          error(CreateTeamTestIds.typeError, l10n.createTeamTypeRequired),
        heading(
          ref.msg(
            MessageKeys.teamCreateSportsLabel,
            l10n.createTeamSportsLabel,
          ),
        ),
        for (final sport in SportKey.values)
          TestId(
            CreateTeamTestIds.sport(sport.key),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sportLabel(l10n, sport)),
              value: draft.sports.contains(sport),
              onChanged: (_) {
                flow.toggleSport(sport);
                setState(
                  () => _errors = [
                    for (final e in _errors)
                      if (e != TeamDetailsError.sportRequired) e,
                  ],
                );
              },
            ),
          ),
        if (_errors.contains(TeamDetailsError.sportRequired))
          error(CreateTeamTestIds.sportError, l10n.createTeamSportRequired),
        const SizedBox(height: 8),
        TestId(
          CreateTeamTestIds.ranking,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              ref.msg(
                MessageKeys.teamCreateRankingLabel,
                l10n.createTeamRankingLabel,
              ),
            ),
            subtitle: Text(
              ref.msg(
                MessageKeys.teamCreateRankingSubText,
                l10n.createTeamRankingHint,
              ),
            ),
            value: draft.enablePlayerRanking,
            onChanged: (v) => flow.setRanking(value: v),
          ),
        ),
        heading(l10n.createTeamParticipatingLabel),
        Text(l10n.createTeamParticipatingHint),
        if (hasRole(RoleKeys.player))
          TestId(
            CreateTeamTestIds.selfPlayer,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.teamRolePlayer),
              value: draft.selfPlayer,
              onChanged: (v) => flow.setSelfPlayer(value: v),
            ),
          ),
        if (hasRole(RoleKeys.coach))
          TestId(
            CreateTeamTestIds.selfCoach,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.teamRoleCoach),
              value: draft.selfCoach,
              onChanged: (v) => flow.setSelfCoach(value: v),
            ),
          ),
      ],
    );
  }
}
