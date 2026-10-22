import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/team_models.dart';

const _place = PlaceItem(id: 5, name: 'Central Courts');
const _team = Team(id: 31, name: 'Sunday Smashers');

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

Map<String, dynamic> _event(EventDraft d) =>
    buildCreateEventBody(d)['event'] as Map<String, dynamic>;

CreateEventFlow _start(ProviderContainer c, String type) =>
    c.read(createEventFlowProvider.notifier)
      ..start()
      ..setEventType(type)
      ..setSport(SportKey.tennis)
      ..setPlace(_place);

void main() {
  group('steps', () {
    test('every type asks team or not after the sport', () {
      expect(createEventStepsFor('et_practice_drill'), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.teamChoice,
        CreateEventStep.settings,
        CreateEventStep.players,
        CreateEventStep.whenWhere,
        CreateEventStep.inviteSettings,
        CreateEventStep.review,
      ]);
      // A meetup has no sport: the choice follows the type.
      expect(createEventStepsFor('et_casual_meeting').take(3), [
        CreateEventStep.type,
        CreateEventStep.teamChoice,
        CreateEventStep.settings,
      ]);
    });

    test('a team event adds the team selection', () {
      expect(createEventStepsFor('et_competitive', forTeam: true).take(5), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.teamChoice,
        CreateEventStep.teamSelect,
        CreateEventStep.settings,
      ]);
      expect(
        nextCreateEventStep(
          'et_round_robin',
          CreateEventStep.teamChoice,
          forTeam: true,
        ),
        CreateEventStep.teamSelect,
      );
    });

    test('the flow follows the team choice', () {
      final c = _container();
      final flow = _start(c, 'et_practice_drill');
      expect(flow.next(CreateEventStep.teamChoice), CreateEventStep.settings);
      flow.setForTeam(value: true);
      expect(flow.next(CreateEventStep.teamChoice), CreateEventStep.teamSelect);
      expect(flow.next(CreateEventStep.teamSelect), CreateEventStep.settings);
    });
  });

  group('flow', () {
    test('choosing non-team forgets a picked team', () {
      final c = _container();
      final flow = _start(c, 'et_practice_drill')
        ..setForTeam(value: true)
        ..setTeam(_team);
      expect(_read(c).team?.id, 31);
      flow.setForTeam(value: false);
      expect(_read(c).team, isNull);
      expect(_read(c).forTeam, isFalse);
    });

    test('changing the sport starts the team choice over', () {
      final c = _container();
      final flow = _start(c, 'et_practice_drill')
        ..setForTeam(value: true)
        ..setTeam(_team);
      flow.setSport(SportKey.padel);
      expect(_read(c).forTeam, isNull);
      expect(_read(c).team, isNull);
    });
  });

  group('request body', () {
    test('a non-team event keeps the empty originator', () {
      final c = _container();
      _start(c, 'et_practice_drill').setForTeam(value: false);
      final event = _event(_timed(_read(c)));
      expect(event['originator_type'], '');
      expect(event.containsKey('originator_id'), isFalse);
      expect(event.containsKey('event_teams_attributes'), isFalse);
      expect(event.containsKey('opponent_team_type'), isFalse);
      expect(
        event['screen_flow_path'],
        contains('es_sports_type##es_team_non_team##es_general_settings'),
      );
      expect(event['screen_flow_path'], isNot(contains('es_self_team')));
    });

    test('a team practice names the team and plays within it', () {
      final c = _container();
      _start(c, 'et_practice_drill')
        ..setForTeam(value: true)
        ..setTeam(_team);
      final event = _event(_timed(_read(c)));
      expect(event['originator_type'], 'Team');
      expect(event['originator_id'], 31);
      expect(event['event_teams_attributes'], [
        {
          'team_id': 31,
          'event_team_type': 'ett_home',
          'logged_in_user_belongs_to_team': true,
        },
      ]);
      expect(event['opponent_team_type'], 'ott_within_team');
      expect(event.containsKey('consider_for_team_ranking'), isFalse);
      expect(
        event['screen_flow_path'],
        contains('es_team_non_team##es_self_team##es_general_settings'),
      );
    });

    test('a team game puts the team on both sides of every match', () {
      final c = _container();
      _start(c, 'et_competitive')
        ..setForTeam(value: true)
        ..setTeam(_team)
        ..setScoringFormat('sf_single_set', const {'sf_single_set': 6})
        ..setMatchType(0, MatchKeys.singles);
      final event = _event(_timed(_read(c)));
      expect(event['originator_type'], 'Team');
      final sides =
          (event['event_matches_attributes'] as List)
                  .single['event_match_sides_attributes']
              as List;
      expect(sides.map((s) => (s as Map)['team_id']), [31, 31]);
      expect(
        event['screen_flow_path'],
        contains('es_sports_type##es_team_non_team##es_self_team##'),
      );
    });

    test('a team round robin can count towards the team ranking', () {
      final c = _container();
      final flow = _start(c, 'et_round_robin')
        ..setForTeam(value: true)
        ..setTeam(_team)
        ..setScoringFormat('sf_single_set', const {'sf_single_set': 6})
        ..setEventSubType(MatchKeys.formatClassic);
      expect(_event(_timed(_read(c)))['consider_for_team_ranking'], isTrue);
      flow.setConsiderForTeamRanking(value: false);
      expect(_event(_timed(_read(c)))['consider_for_team_ranking'], isFalse);
    });

    test('a team event without a team cannot be built', () {
      final c = _container();
      _start(c, 'et_practice_drill').setForTeam(value: true);
      expect(() => _event(_timed(_read(c))), throwsStateError);
    });
  });
}
