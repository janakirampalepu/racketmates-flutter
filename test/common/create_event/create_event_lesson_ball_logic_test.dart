import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _place = PlaceItem(id: 5, name: 'Central Courts');
const _coachA = AppUser(id: 3, firstName: 'Coach', lastName: 'A');
const _coachB = AppUser(id: 4, firstName: 'Coach', lastName: 'B');
const _coachC = AppUser(id: 5, firstName: 'Coach', lastName: 'C');
const _alex = AppUser(id: 8, firstName: 'Alex');
const _pat = AppUser(id: 9, firstName: 'Pat');

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

EventDraft _read(ProviderContainer c) => c.read(createEventFlowProvider)!;

CreateEventFlow _start(ProviderContainer c, String type) =>
    c.read(createEventFlowProvider.notifier)
      ..start()
      ..setEventType(type)
      ..setSport(SportKey.tennis)
      ..setPlace(_place);

Map<String, dynamic> _event(ProviderContainer c) =>
    buildCreateEventBody(
          _read(c).copyWith(
            start: () => DateTime(2026, 11, 3, 18),
            timezoneInfoId: () => 77,
          ),
        )['event']
        as Map<String, dynamic>;

void main() {
  group('steps', () {
    test('an individual lesson never asks team or non-team', () {
      expect(createEventStepsFor('et_individual_lesson'), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.settings,
        CreateEventStep.coaches,
        CreateEventStep.whenWhere,
        CreateEventStep.assignType,
        CreateEventStep.inviteSettings,
        CreateEventStep.players,
        CreateEventStep.review,
      ]);
      expect(createEventStepsFor('et_individual_lesson', forTeam: true), [
        for (final s in createEventStepsFor('et_individual_lesson')) s,
      ]);
    });

    test('one player now skips the invite settings', () {
      expect(createEventStepsFor('et_individual_lesson', assignNow: true), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.settings,
        CreateEventStep.coaches,
        CreateEventStep.whenWhere,
        CreateEventStep.assignType,
        CreateEventStep.players,
        CreateEventStep.review,
      ]);
    });

    test('a ball machine is a venue and one player', () {
      expect(createEventStepsFor('et_practice_ball'), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.whenWhere,
        CreateEventStep.players,
        CreateEventStep.review,
      ]);
      final c = _container();
      final flow = _start(c, 'et_practice_ball');
      expect(flow.next(CreateEventStep.sport), CreateEventStep.whenWhere);
      expect(flow.next(CreateEventStep.whenWhere), CreateEventStep.players);
      expect(flow.next(CreateEventStep.players), CreateEventStep.review);
    });

    test('they take one court chosen on the venue step', () {
      for (final key in ['et_individual_lesson', 'et_practice_ball']) {
        final spec = eventTypeSpecs[key]!;
        expect(spec.usesCourts, isTrue);
        expect(spec.courtCountOnWhenWhere, isFalse);
        expect(spec.noTeam, isTrue);
      }
      final c = _container();
      _start(c, 'et_individual_lesson')
        ..toggleCourt(11)
        ..toggleCourt(12);
      expect(_read(c).courtIds, [11]);
    });
  });

  group('flow', () {
    test('a lesson has at most two coaches', () {
      final c = _container();
      final flow = _start(c, 'et_individual_lesson')
        ..toggleCoach(_coachA)
        ..toggleCoach(_coachB)
        ..toggleCoach(_coachC);
      expect(_read(c).coaches.map((u) => u.id), [3, 4]);
      flow
        ..toggleCoach(_coachA)
        ..toggleCoach(_coachC);
      expect(_read(c).coaches.map((u) => u.id), [4, 5]);
    });

    test('a group lesson keeps any number of coaches', () {
      final c = _container();
      _start(c, 'et_group_lesson')
        ..toggleCoach(_coachA)
        ..toggleCoach(_coachB)
        ..toggleCoach(_coachC);
      expect(_read(c).coaches, hasLength(3));
    });

    test('later invites several, now takes one that can be replaced', () {
      final c = _container();
      final flow = _start(c, 'et_individual_lesson')
        ..toggleInvitee(_alex)
        ..toggleInvitee(_pat);
      expect(_read(c).invitees, hasLength(2));
      expect(_read(c).maxInvitees, isNull);

      flow.setAssignNow(value: true); // the choice clears the invitees
      expect(_read(c).invitees, isEmpty);
      expect(_read(c).maxInvitees, 1);
      flow
        ..toggleInvitee(_alex)
        ..toggleInvitee(_pat);
      expect(_read(c).invitees.map((u) => u.id), [9]);
      flow.toggleInvitee(_pat);
      expect(_read(c).invitees, isEmpty);

      flow
        ..toggleInvitee(_alex)
        ..setAssignNow(value: true); // same choice keeps them
      expect(_read(c).invitees, hasLength(1));
      flow.setAssignNow(value: false);
      expect(_read(c).invitees, isEmpty);
    });

    test('a ball machine takes one player', () {
      final c = _container();
      _start(c, 'et_practice_ball')
        ..toggleInvitee(_alex)
        ..toggleInvitee(_pat);
      expect(_read(c).invitees.map((u) => u.id), [9]);
      expect(_read(c).playersSetDirectly, isTrue);
    });

    test('other types are unaffected', () {
      final c = _container();
      _start(c, 'et_practice_drill')
        ..toggleInvitee(_alex)
        ..toggleInvitee(_pat)
        ..setAssignNow(value: true);
      expect(_read(c).invitees, hasLength(2));
      expect(_read(c).playersSetDirectly, isFalse);
    });
  });

  group('individual lesson request', () {
    test('invite several and assign later', () {
      final c = _container();
      _start(c, 'et_individual_lesson')
        ..toggleCoach(_coachA)
        ..toggleInvitee(_alex)
        ..toggleInvitee(_pat)
        ..toggleCourt(11);
      final event = _event(c);
      expect(event['event_type'], 'et_individual_lesson');
      expect(event.containsKey('originator_type'), isFalse);
      expect(event['with_coach'], isTrue);
      expect(event['assign_type'], 'at_assign_later');
      expect(event['players_limit'], 1);
      expect(event['rsvp_limit'], 1);
      expect(event['no_of_courts'], 1);
      expect(event['event_venue_courts_attributes'], [
        {'place_court_id': 11, 'order': 1},
      ]);
      expect(event.containsKey('event_matches_attributes'), isFalse);
      expect(event['player_acceptance_type'], acceptOrderOfResponse);
      expect(event['allow_participants_manage_players'], isFalse);
      expect(event['event_participants_attributes'], [
        {
          'user_id': 3,
          'is_player': false,
          'is_coach': true,
          'is_audience': false,
        },
        {
          'user_id': 8,
          'is_player': true,
          'is_coach': false,
          'is_audience': false,
        },
        {
          'user_id': 9,
          'is_player': true,
          'is_coach': false,
          'is_audience': false,
        },
      ]);
      expect(
        event['screen_flow_path'],
        'es_event_type_selection##es_sports_type##es_general_settings##'
        'es_coaches_assign##es_court_options##es_court_player_assign_type##'
        'es_invite_player_settings##es_invite_players_mgmt##es_review',
      );
    });

    test('one player now', () {
      final c = _container();
      _start(c, 'et_individual_lesson')
        ..toggleCoach(_coachA)
        ..toggleCoach(_coachB)
        ..setAssignNow(value: true)
        ..toggleInvitee(_alex);
      final event = _event(c);
      expect(event['assign_type'], 'at_court_addition');
      expect(event['player_acceptance_type'], acceptPickManually);
      expect((event['event_participants_attributes'] as List), hasLength(3));
      expect(
        event['screen_flow_path'],
        isNot(contains('es_invite_player_settings')),
      );
    });
  });

  group('ball machine request', () {
    test('one singles match with the player and the court', () {
      final c = _container();
      _start(c, 'et_practice_ball')
        ..toggleCourt(11)
        ..toggleInvitee(_alex);
      final event = _event(c);
      expect(event['event_type'], 'et_practice_ball');
      expect(event['sport_type'], 'st_tennis');
      expect(event['assign_type'], 'at_court_addition');
      expect(event['players_limit'], 1);
      expect(event['rsvp_limit'], 1);
      expect(event['player_acceptance_type'], acceptPickManually);
      expect(event['with_coach'], isFalse);
      expect(event['event_venue_courts_attributes'], isEmpty);
      expect(event['event_matches_attributes'], [
        {
          'match_type': 'mt_singles',
          'order': 1,
          'place_court_id': 11,
          'event_match_sides_attributes': [
            {
              'side': 'ecs_top',
              'event_participants': [
                {'user_id': 8, 'position': 'epp_center'},
              ],
            },
            {'side': 'ecs_bottom', 'event_participants': <Object>[]},
          ],
        },
      ]);
      expect(
        event['screen_flow_path'],
        'es_event_type_selection##es_sports_type##es_court_options##'
        'es_invite_players_mgmt##es_review',
      );
    });

    test('settings that were never asked are not sent', () {
      final c = _container();
      _start(c, 'et_practice_ball').toggleInvitee(_alex);
      final event = _event(c);
      for (final key in [
        'originator_type',
        'allow_participants_manage_players',
        'attendance_deadline_unit',
        'attendance_deadline_unit_type',
        'player_pool',
        'event_participants_attributes',
        'no_of_courts',
      ]) {
        expect(event.containsKey(key), isFalse, reason: key);
      }
    });

    test('the court is optional but the player is not', () {
      final c = _container();
      final flow = _start(c, 'et_practice_ball');
      expect(() => _event(c), throwsStateError);
      flow.toggleInvitee(_alex);
      final match =
          (_event(c)['event_matches_attributes'] as List).single as Map;
      expect(match.containsKey('place_court_id'), isFalse);
    });
  });
}
