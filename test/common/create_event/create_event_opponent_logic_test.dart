import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _place = PlaceItem(id: 5, name: 'Central Courts');
const _mine = Team(id: 31, name: 'Sunday Smashers');
const _eagles = Team(id: 44, name: 'Eagles');
const _alex = AppUser(id: 8, firstName: 'Alex');
const _pat = AppUser(id: 9, firstName: 'Pat');

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

EventDraft _read(ProviderContainer c) => c.read(createEventFlowProvider)!;

EventDraft _timed(EventDraft d) => d.copyWith(
  start: () => DateTime(2026, 11, 3, 18),
  timezoneInfoId: () => 77,
);

Map<String, dynamic> _event(ProviderContainer c) =>
    buildCreateEventBody(_timed(_read(c)))['event'] as Map<String, dynamic>;

/// A team game ready to build, against [opponent].
CreateEventFlow _game(ProviderContainer c, OpponentKind opponent) {
  final flow = c.read(createEventFlowProvider.notifier)
    ..start()
    ..setEventType('et_competitive')
    ..setSport(SportKey.tennis)
    ..setForTeam(value: true)
    ..setTeam(_mine)
    ..setOpponent(opponent)
    ..setScoringFormat('sf_single_set', const {'sf_single_set': 6})
    ..setPlace(_place);
  switch (opponent) {
    case OpponentKind.selectTeam:
      flow.setOpponentTeam(_eagles);
    case OpponentKind.namedTeam:
      flow.setOpponentName('  Eagles FC ');
    case OpponentKind.withinTeam:
  }
  return flow;
}

List<Map<String, dynamic>> _sides(Map<String, dynamic> event) =>
    ((event['event_matches_attributes'] as List).first
                as Map)['event_match_sides_attributes']
            .cast<Map<String, dynamic>>()
        as List<Map<String, dynamic>>;

void main() {
  group('steps', () {
    test('only team games ask who they are played against', () {
      for (final type in [
        'et_practice_drill',
        'et_group_lesson',
        'et_casual_meeting',
        'et_round_robin',
      ]) {
        expect(
          createEventStepsFor(type, forTeam: true),
          isNot(contains(CreateEventStep.teamDynamics)),
        );
      }
      expect(
        createEventStepsFor('et_competitive'),
        isNot(contains(CreateEventStep.teamDynamics)),
      );
      expect(
        createEventStepsFor('et_casual', forTeam: true),
        contains(CreateEventStep.teamDynamics),
      );
    });

    test('opponent screens follow the choice', () {
      List<CreateEventStep> steps(OpponentKind? o) =>
          createEventStepsFor('et_competitive', forTeam: true, opponent: o)
              .skipWhile((s) => s != CreateEventStep.teamDynamics)
              .takeWhile((s) => s != CreateEventStep.settings)
              .toList();
      expect(steps(null), [CreateEventStep.teamDynamics]);
      expect(steps(OpponentKind.withinTeam), [CreateEventStep.teamDynamics]);
      expect(steps(OpponentKind.selectTeam), [
        CreateEventStep.teamDynamics,
        CreateEventStep.opponentSelect,
        CreateEventStep.homeAway,
      ]);
      expect(steps(OpponentKind.namedTeam), [
        CreateEventStep.teamDynamics,
        CreateEventStep.homeAway,
      ]);
    });

    test('the flow follows the opponent choice', () {
      final c = _container();
      final flow = _game(c, OpponentKind.namedTeam);
      expect(flow.next(CreateEventStep.teamDynamics), CreateEventStep.homeAway);
      expect(flow.next(CreateEventStep.homeAway), CreateEventStep.settings);
      flow.setOpponent(OpponentKind.selectTeam);
      expect(
        flow.next(CreateEventStep.teamDynamics),
        CreateEventStep.opponentSelect,
      );
      expect(
        flow.next(CreateEventStep.opponentSelect),
        CreateEventStep.homeAway,
      );
    });
  });

  group('flow', () {
    test('changing the opponent drops the details of the others', () {
      final c = _container();
      final flow = _game(c, OpponentKind.selectTeam);
      expect(_read(c).opponentTeam?.id, 44);
      flow.setOpponent(OpponentKind.namedTeam);
      expect(_read(c).opponentTeam, isNull);
      flow.setOpponentName('Eagles FC');
      flow.setOpponent(OpponentKind.namedTeam); // same choice keeps the name
      expect(_read(c).opponentName, 'Eagles FC');
      flow.setOpponent(OpponentKind.withinTeam);
      expect(_read(c).opponentName, isEmpty);
    });

    test('a new team or non-team forgets the opponent and home choice', () {
      final c = _container();
      final flow = _game(c, OpponentKind.selectTeam)
        ..swapHomeAway()
        ..setHomeTeamNotDecided(value: true);
      flow.setTeam(const Team(id: 32, name: 'Other'));
      final d = _read(c);
      expect(d.opponent, isNull);
      expect(d.opponentTeam, isNull);
      expect(d.opponentIsHome, isFalse);
      expect(d.homeTeamNotDecided, isFalse);
      flow
        ..setOpponent(OpponentKind.namedTeam)
        ..setForTeam(value: false);
      expect(_read(c).opponent, isNull);
    });

    test('against another team each match needs half the players of ours', () {
      final c = _container();
      final flow = _game(c, OpponentKind.withinTeam)
        ..setMatchType(0, MatchKeys.singles)
        ..addMatch()
        ..setMatchType(1, MatchKeys.doubles);
      expect(_read(c).isMultiTeam, isFalse);
      expect(_read(c).playersLimit, 6); // 2 + 4
      flow.setOpponent(OpponentKind.selectTeam);
      expect(_read(c).isMultiTeam, isTrue);
      expect(_read(c).playersLimit, 3); // 1 + 2
      flow.addMatch(); // undecided counts as doubles
      expect(_read(c).playersLimit, 5);
      flow.setOpponent(OpponentKind.withinTeam);
      expect(_read(c).playersLimit, 10);
    });

    test('only our own side has to be filled against another team', () {
      const topLeft = MatchSlot(MatchKeys.sideTop, MatchKeys.positionLeft);
      const topRight = MatchSlot(MatchKeys.sideTop, MatchKeys.positionRight);
      final match = const MatchDraft(matchType: MatchKeys.doubles)
          .withPlayer(topLeft, _alex)
          .withPlayer(topRight, _pat);
      expect(match.filled(multiTeam: true), isTrue);
      expect(match.filled(multiTeam: false), isFalse);
      expect(const MatchDraft().filled(multiTeam: true), isFalse);
    });
  });

  group('request body', () {
    test('within the team: one team, no opponent fields', () {
      final c = _container();
      _game(c, OpponentKind.withinTeam).setMatchType(0, MatchKeys.singles);
      final event = _event(c);
      expect(event['opponent_team_type'], 'ott_within_team');
      expect(event['event_teams_attributes'], hasLength(1));
      expect(event.containsKey('opponent_team_name'), isFalse);
      expect(event.containsKey('home_team_not_decided'), isFalse);
      expect(_sides(event).map((s) => s['team_id']), [31, 31]);
    });

    test('against an existing team: both teams, our team is home', () {
      final c = _container();
      _game(c, OpponentKind.selectTeam).setMatchType(0, MatchKeys.singles);
      final event = _event(c);
      expect(event['opponent_team_type'], 'ott_specific_team');
      expect(event['event_teams_attributes'], [
        {
          'team_id': 31,
          'event_team_type': 'ett_home',
          'logged_in_user_belongs_to_team': true,
        },
        {
          'team_id': 44,
          'event_team_type': 'ett_visiting',
          'logged_in_user_belongs_to_team': false,
        },
      ]);
      expect(event['home_team_not_decided'], isFalse);
      expect(event.containsKey('opponent_team_name'), isFalse);
      expect(_sides(event).map((s) => s['team_id']), [31, 44]);
      expect(event['players_limit'], 1);
      expect(
        event['screen_flow_path'],
        contains(
          'es_self_team##es_event_dynamics_selection##es_team_opponent_selection'
          '##es_event_team_home_away_selection##es_general_settings',
        ),
      );
    });

    test('swapping makes the opponent the home team', () {
      final c = _container();
      _game(c, OpponentKind.selectTeam).swapHomeAway();
      final teams = _event(c)['event_teams_attributes'] as List;
      expect((teams[0] as Map)['event_team_type'], 'ett_visiting');
      expect((teams[1] as Map)['event_team_type'], 'ett_home');
    });

    test('an undecided home team sends no home or visiting', () {
      final c = _container();
      _game(c, OpponentKind.selectTeam).setHomeTeamNotDecided(value: true);
      final event = _event(c);
      expect(event['home_team_not_decided'], isTrue);
      for (final t in event['event_teams_attributes'] as List) {
        expect((t as Map).containsKey('event_team_type'), isFalse);
      }
    });

    test('against a team known by name: the name, no team id', () {
      final c = _container();
      _game(c, OpponentKind.namedTeam).setMatchType(0, MatchKeys.doubles);
      final event = _event(c);
      expect(event['opponent_team_type'], 'ott_unknown_team_with_name');
      expect(event['opponent_team_name'], 'Eagles FC');
      expect(event['event_teams_attributes'], [
        {
          'team_id': 31,
          'event_team_type': 'ett_home',
          'logged_in_user_belongs_to_team': true,
        },
        {
          'event_team_type': 'ett_visiting',
          'logged_in_user_belongs_to_team': false,
        },
      ]);
      final sides = _sides(event);
      expect(sides[0]['team_id'], 31);
      expect(sides[1].containsKey('team_id'), isFalse);
      expect(event['players_limit'], 2);
      expect(
        event['screen_flow_path'],
        contains(
          'es_event_dynamics_selection##es_event_team_home_away_selection',
        ),
      );
      expect(
        event['screen_flow_path'],
        isNot(contains('es_team_opponent_selection')),
      );
    });

    test('assigning now sends only our own players', () {
      const topCentre = MatchSlot(MatchKeys.sideTop, MatchKeys.positionCenter);
      final c = _container();
      _game(c, OpponentKind.selectTeam)
        ..setMatchType(0, MatchKeys.singles)
        ..setAssignNow(value: true)
        ..assignPlayer(0, topCentre, _alex);
      final sides = _sides(_event(c));
      expect(sides[0]['event_participants'], [
        {'user_id': 8, 'position': 'epp_center'},
      ]);
      expect(sides[1]['event_participants'], isEmpty);
    });

    test('a team game must say who it is against', () {
      final c = _container();
      c.read(createEventFlowProvider.notifier)
        ..start()
        ..setEventType('et_competitive')
        ..setSport(SportKey.tennis)
        ..setForTeam(value: true)
        ..setTeam(_mine)
        ..setScoringFormat('sf_single_set', const {'sf_single_set': 6})
        ..setPlace(_place);
      expect(() => _event(c), throwsStateError);
    });

    test('an opponent team or name is required for those choices', () {
      final c = _container();
      final flow = _game(c, OpponentKind.selectTeam);
      flow
        ..setOpponent(OpponentKind.withinTeam)
        ..setOpponent(OpponentKind.selectTeam); // no team chosen yet
      expect(() => _event(c), throwsStateError);
      flow
        ..setOpponent(OpponentKind.namedTeam)
        ..setOpponentName('   ');
      expect(() => _event(c), throwsStateError);
    });

    test('other team events stay within the team', () {
      final c = _container();
      c.read(createEventFlowProvider.notifier)
        ..start()
        ..setEventType('et_practice_drill')
        ..setSport(SportKey.tennis)
        ..setForTeam(value: true)
        ..setTeam(_mine)
        ..setPlace(_place);
      final event = _event(c);
      expect(event['opponent_team_type'], 'ott_within_team');
      expect(event['event_teams_attributes'], hasLength(1));
    });
  });
}
