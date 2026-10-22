import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/users/models/app_user.dart';

enum TeamRole { captain, player, coach }

/// Roles one invited person holds in the new team.
class MemberRoles {
  const MemberRoles(
    this.user, {
    this.captain = false,
    this.player = false,
    this.coach = false,
  });

  final AppUser user;
  final bool captain;
  final bool player;
  final bool coach;

  bool get any => captain || player || coach;

  bool has(TeamRole role) => switch (role) {
    TeamRole.captain => captain,
    TeamRole.player => player,
    TeamRole.coach => coach,
  };

  MemberRoles toggled(TeamRole role) => MemberRoles(
    user,
    captain: role == TeamRole.captain ? !captain : captain,
    player: role == TeamRole.player ? !player : player,
    coach: role == TeamRole.coach ? !coach : coach,
  );
}

enum TeamDetailsError { nameRequired, typeRequired, sportRequired }

/// Everything collected by the create-team screens.
class TeamDraft {
  const TeamDraft({
    this.name = '',
    this.teamType,
    this.sports = const [],
    this.enablePlayerRanking = false,
    this.selfPlayer = false,
    this.selfCoach = false,
    this.members = const [],
  });

  final String name;

  /// `tt_casual` or `tt_competitive`.
  final String? teamType;
  final List<SportKey> sports;
  final bool enablePlayerRanking;

  /// The creator is always a captain and may also play or coach.
  final bool selfPlayer;
  final bool selfCoach;

  /// People invited, in the order added.
  final List<MemberRoles> members;

  TeamDraft copyWith({
    String? name,
    String? Function()? teamType,
    List<SportKey>? sports,
    bool? enablePlayerRanking,
    bool? selfPlayer,
    bool? selfCoach,
    List<MemberRoles>? members,
  }) => TeamDraft(
    name: name ?? this.name,
    teamType: teamType != null ? teamType() : this.teamType,
    sports: sports ?? this.sports,
    enablePlayerRanking: enablePlayerRanking ?? this.enablePlayerRanking,
    selfPlayer: selfPlayer ?? this.selfPlayer,
    selfCoach: selfCoach ?? this.selfCoach,
    members: members ?? this.members,
  );
}

/// Native `NewTeamFragment.checkValidation`: a name, a type and a sport.
List<TeamDetailsError> validateTeamDetails(TeamDraft draft) => [
  if (draft.name.trim().isEmpty) TeamDetailsError.nameRequired,
  if (draft.teamType == null) TeamDetailsError.typeRequired,
  if (draft.sports.isEmpty) TeamDetailsError.sportRequired,
];

/// Body of `POST teams` (native `TeamViewModel.createTeam`): the creator as
/// captain plus every invited person with at least one role.
Map<String, dynamic> buildCreateTeamBody(TeamDraft draft, int selfUserId) {
  if (validateTeamDetails(draft).isNotEmpty) {
    throw StateError('incomplete team draft');
  }
  return {
    'team': {
      'name': draft.name.trim(),
      'team_type': draft.teamType,
      'enable_player_ranking': draft.enablePlayerRanking,
      'team_sports_attributes': [
        for (final sport in draft.sports) {'sport_type': sport.key},
      ],
      'team_players_attributes': [
        {
          'user_id': selfUserId,
          'is_captain': true,
          'is_player': draft.selfPlayer,
          'is_coach': draft.selfCoach,
        },
        for (final m in draft.members)
          if (m.any && m.user.id != selfUserId)
            {
              'user_id': m.user.id,
              'is_captain': m.captain,
              'is_player': m.player,
              'is_coach': m.coach,
            },
      ],
    },
  };
}

class CreateTeamFlow extends Notifier<TeamDraft> {
  @override
  TeamDraft build() => const TeamDraft();

  void reset() => state = const TeamDraft();

  void setName(String name) => state = state.copyWith(name: name);

  void setType(String type) => state = state.copyWith(teamType: () => type);

  void toggleSport(SportKey sport) {
    final sports = state.sports;
    state = state.copyWith(
      sports: sports.contains(sport)
          ? [
              for (final s in sports)
                if (s != sport) s,
            ]
          : [...sports, sport],
    );
  }

  void setRanking({required bool value}) =>
      state = state.copyWith(enablePlayerRanking: value);

  void setSelfPlayer({required bool value}) =>
      state = state.copyWith(selfPlayer: value);

  void setSelfCoach({required bool value}) =>
      state = state.copyWith(selfCoach: value);

  /// Flips one role of [user]; a person left with no role is removed.
  void toggleMemberRole(AppUser user, TeamRole role) {
    final members = state.members;
    final index = members.indexWhere((m) => m.user.id == user.id);
    final next = (index < 0 ? MemberRoles(user) : members[index]).toggled(role);
    state = state.copyWith(
      members: [
        for (var i = 0; i < members.length; i++)
          if (i != index) members[i] else if (next.any) next,
        if (index < 0 && next.any) next,
      ],
    );
  }
}

final createTeamFlowProvider = NotifierProvider<CreateTeamFlow, TeamDraft>(
  CreateTeamFlow.new,
);

class CreateTeamSubmission {
  const CreateTeamSubmission({this.loading = false, this.failure});

  final bool loading;
  final AppFailure? failure;
}

/// Creates the team and refreshes the teams list.
class CreateTeamSubmitter extends Notifier<CreateTeamSubmission> {
  @override
  CreateTeamSubmission build() => const CreateTeamSubmission();

  /// True when the team was created.
  Future<bool> submit() async {
    final selfId = int.tryParse(
      ref.read(selectedUserIdsProvider).firstOrNull ?? '',
    );
    if (selfId == null || state.loading) return false;
    state = const CreateTeamSubmission(loading: true);
    try {
      await ref
          .read(teamsRepositoryProvider)
          .create(
            buildCreateTeamBody(ref.read(createTeamFlowProvider), selfId),
          );
      ref.invalidate(myTeamsProvider);
      state = const CreateTeamSubmission();
      return true;
    } on AppFailure catch (failure) {
      state = CreateTeamSubmission(failure: failure);
      return false;
    }
  }

  void clear() => state = const CreateTeamSubmission();
}

final createTeamSubmitterProvider =
    NotifierProvider<CreateTeamSubmitter, CreateTeamSubmission>(
      CreateTeamSubmitter.new,
    );
