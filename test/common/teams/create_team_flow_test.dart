import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _alex = AppUser(id: 8, firstName: 'Alex');
const _pat = AppUser(id: 9, firstName: 'Pat');

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

TeamDraft _read(ProviderContainer c) => c.read(createTeamFlowProvider);

void main() {
  test('validation needs a name, a type and a sport', () {
    expect(validateTeamDetails(const TeamDraft()), [
      TeamDetailsError.nameRequired,
      TeamDetailsError.typeRequired,
      TeamDetailsError.sportRequired,
    ]);
    expect(
      validateTeamDetails(
        const TeamDraft(
          name: '   ',
          teamType: TeamTypes.casual,
          sports: [SportKey.tennis],
        ),
      ),
      [TeamDetailsError.nameRequired],
    );
    expect(
      validateTeamDetails(
        const TeamDraft(
          name: 'A',
          teamType: TeamTypes.casual,
          sports: [SportKey.tennis],
        ),
      ),
      isEmpty,
    );
  });

  test('flow edits the draft', () {
    final c = _container();
    c.read(createTeamFlowProvider.notifier)
      ..setName('Smashers')
      ..setType(TeamTypes.competitive)
      ..toggleSport(SportKey.tennis)
      ..toggleSport(SportKey.padel)
      ..toggleSport(SportKey.tennis)
      ..setRanking(value: true)
      ..setSelfPlayer(value: true)
      ..setSelfCoach(value: true);
    final d = _read(c);
    expect(d.name, 'Smashers');
    expect(d.teamType, TeamTypes.competitive);
    expect(d.sports, [SportKey.padel]);
    expect(d.enablePlayerRanking, isTrue);
    expect(d.selfPlayer, isTrue);
    expect(d.selfCoach, isTrue);
    c.read(createTeamFlowProvider.notifier).reset();
    expect(_read(c).name, isEmpty);
  });

  test('member roles toggle and a member without roles disappears', () {
    final c = _container();
    final flow = c.read(createTeamFlowProvider.notifier)
      ..toggleMemberRole(_alex, TeamRole.player)
      ..toggleMemberRole(_pat, TeamRole.coach)
      ..toggleMemberRole(_alex, TeamRole.captain);
    expect(_read(c).members.map((m) => m.user.id), [8, 9]);
    expect(_read(c).members.first.player, isTrue);
    expect(_read(c).members.first.captain, isTrue);
    flow
      ..toggleMemberRole(_alex, TeamRole.player)
      ..toggleMemberRole(_alex, TeamRole.captain);
    expect(_read(c).members.map((m) => m.user.id), [9]);
    flow.toggleMemberRole(_pat, TeamRole.coach);
    expect(_read(c).members, isEmpty);
  });

  test('create body: creator is the captain, members carry their roles', () {
    final body = buildCreateTeamBody(
      TeamDraft(
        name: '  Smashers ',
        teamType: TeamTypes.competitive,
        sports: const [SportKey.tennis, SportKey.padel],
        enablePlayerRanking: true,
        selfPlayer: true,
        members: [
          const MemberRoles(_alex, player: true),
          const MemberRoles(_pat, coach: true, captain: true),
          const MemberRoles(AppUser(id: 7), player: true), // the creator
          const MemberRoles(AppUser(id: 10)), // no role: not sent
        ],
      ),
      7,
    );
    expect(body, {
      'team': {
        'name': 'Smashers',
        'team_type': 'tt_competitive',
        'enable_player_ranking': true,
        'team_sports_attributes': [
          {'sport_type': 'st_tennis'},
          {'sport_type': 'st_padel'},
        ],
        'team_players_attributes': [
          {
            'user_id': 7,
            'is_captain': true,
            'is_player': true,
            'is_coach': false,
          },
          {
            'user_id': 8,
            'is_captain': false,
            'is_player': true,
            'is_coach': false,
          },
          {
            'user_id': 9,
            'is_captain': true,
            'is_player': false,
            'is_coach': true,
          },
        ],
      },
    });
  });

  test('an incomplete draft cannot be built', () {
    expect(() => buildCreateTeamBody(const TeamDraft(), 7), throwsStateError);
  });
}
