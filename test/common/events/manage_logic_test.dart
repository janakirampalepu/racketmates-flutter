import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';

import '../../support/fixtures.dart';

EventDetails _event(String fixture) =>
    EventDetailsResponse.fromJson(apiFixture(fixture)).event!;

void main() {
  group('event model', () {
    test('settings, courts and the venue time zone are read', () {
      final e = _event('events_show_manage_practice');
      expect(e.attendanceDeadlineUnit, 2);
      expect(e.attendanceDeadlineUnitType, 'adut_hour');
      expect(e.rsvpLimit, 6);
      expect(e.noOfCourts, 1);
      expect(e.settingsLocked, isFalse);
      expect(e.eventVenueCourts?.single.placeCourtId, 11);
      expect(e.hasSingleSchedule, isTrue);
      final option = e.eventScheduleOptions!.single;
      expect(option.timezoneInfoId, 14);
      expect(option.timezoneInfo?.utcOffsetTime, -18000);
      // 23:00 UTC at UTC-5 is 18:00 on the wall at the venue.
      expect(option.venueStart, DateTime(2030, 11, 3, 18));
    });

    test('matches with sides, players and scores', () {
      final e = _event('events_show_manage_game');
      expect(e.isGame, isTrue);
      expect(e.hasSingleSchedule, isFalse); // games are rescheduled per match
      final m = e.eventMatches!.first;
      expect(m.top?.label, 'Alex Kim');
      expect(m.bottom?.label, 'Pat Lee');
      expect(m.placeCourt?.name, 'Court 1');
      expect(m.top?.scoreOfSet('1'), '6');
      // The set tie-break is not the regular set score.
      expect(m.top?.scoreOfSet('2'), '7');
      expect(m.top?.eventScores?.last.setTieBreaker, isTrue);
      final open = e.eventMatches!.last;
      expect(open.top?.label, 'Team A'); // no players yet: the team name
      expect(open.unfinished, isTrue);
    });

    test('ball machines and single schedules', () {
      expect(
        const EventDetails(
          eventType: 'et_practice_ball',
          eventScheduleOptions: [EventScheduleOption()],
        ).hasSingleSchedule,
        isFalse,
      );
      expect(
        const EventDetails(
          eventType: 'et_practice_drill',
          eventScheduleOptions: [EventScheduleOption(), EventScheduleOption()],
        ).hasSingleSchedule,
        isFalse,
      );
    });
  });

  group('settings', () {
    test('start from the event and clamp like the wizard', () {
      final edit = settingsEditFor(_event('events_show_manage_practice'));
      expect(edit.attendanceUnit, 2);
      expect(edit.attendanceUnitType, attendanceUnitHours);
      expect(edit.playersLimit, 4);
      expect(edit.rsvpLimit, 6);
      expect(edit.acceptanceType, acceptOrderOfResponse);
      expect(edit.scoring, isNull);

      final days = edit.withAttendanceType(attendanceUnitDays);
      expect(days.attendanceUnit, 1);
      expect(days.withAttendanceUnit(99).attendanceUnit, maxAttendanceDays);
      expect(edit.withAttendanceUnit(99).attendanceUnit, maxAttendanceHours);

      // The RSVP limit follows the players limit up, never below it.
      expect(edit.withPlayersLimit(8).rsvpLimit, 8);
      expect(edit.withPlayersLimit(0).playersLimit, 1);
      expect(edit.withRsvpLimit(2).rsvpLimit, 4);
    });

    test('a practice sends deadline, switch and limits only', () {
      final e = _event('events_show_manage_practice');
      final body = buildUpdateSettingsBody(
        e,
        settingsEditFor(e).copyWith(allowManagePlayers: true),
      );
      expect(body, {
        'event': {
          'attendance_deadline_unit': 2,
          'attendance_deadline_unit_type': 'adut_hour',
          'allow_participants_manage_players': true,
          'players_limit': 4,
          'rsvp_limit': 6,
          'player_acceptance_type': 'pat_order_of_response',
        },
      });
    });

    test('a game also sends results and scoring', () {
      final e = _event('events_show_manage_game');
      final edit = settingsEditFor(e);
      expect(edit.scoring?.format, 'sf_best_of_3_sets');
      expect(edit.scoring?.minimumScore, 2);
      final event =
          buildUpdateSettingsBody(
                e,
                edit.copyWith(
                  allowLogResults: true,
                  scoring: const ScoringChoice(
                    format: 'sf_single_set',
                    minimumScore: 6,
                    decidingSetType: 'dst_regular_set',
                  ),
                ),
              )['event']
              as Map<String, dynamic>;
      expect(event['allow_participants_to_log_results'], isTrue);
      expect(event['scoring_format'], 'sf_single_set');
      expect(event['minimum_score_to_win'], 6);
      expect(event['deciding_set_type'], 'dst_regular_set');
      expect(event.containsKey('consider_for_team_ranking'), isFalse);
    });

    test('the ranking switch is for team round robins only', () {
      const rr = EventDetails(
        eventType: 'et_round_robin',
        originatorType: 'Team',
        scoringFormat: 'sf_single_set',
      );
      final event =
          buildUpdateSettingsBody(
                rr,
                settingsEditFor(rr).copyWith(considerForTeamRanking: false),
              )['event']
              as Map<String, dynamic>;
      expect(event['consider_for_team_ranking'], isFalse);
      const plain = EventDetails(eventType: 'et_round_robin');
      expect(
        (buildUpdateSettingsBody(plain, settingsEditFor(plain))['event'] as Map)
            .containsKey('consider_for_team_ranking'),
        isFalse,
      );
    });
  });

  group('reschedule', () {
    test('the draft holds the event as it is now', () {
      final d = rescheduleDraftFor(_event('events_show_manage_practice'));
      expect(d.eventType, 'et_practice_drill');
      expect(d.sport, SportKey.tennis);
      expect(d.place?.id, 5);
      expect(d.place?.name, 'Central Courts');
      expect(d.start, DateTime(2030, 11, 3, 18));
      expect(d.durationMinutes, 90);
      expect(d.timezoneInfoId, 14);
      expect(d.courtIds, [11]);
      expect(d.courtCount, 1);
      expect(d.notes, 'Bring balls');
    });

    test('the body replaces the option, courts and notes', () {
      final d = rescheduleDraftFor(_event('events_show_manage_practice'))
          .copyWith(
            start: () => DateTime(2030, 12, 1, 9, 5),
            durationMinutes: 60,
            notes: '  New notes ',
            courtCount: 2,
            courtIds: [12, 11],
          );
      expect(buildRescheduleBody(d), {
        'event': {
          'event_schedule_options_attributes': [
            {
              'place_id': 5,
              'start_time': '2030-12-01T09:05Z',
              'duration': 60,
              'timezone_info_id': 14,
            },
          ],
          'event_venue_courts_attributes': [
            {'place_court_id': 12, 'order': 1},
            {'place_court_id': 11, 'order': 2},
          ],
          'notes_for_event': 'New notes',
        },
      });
    });

    test('a changed venue or time drops the zone until it is looked up', () {
      final d = rescheduleDraftFor(_event('events_show_manage_practice'))
          .copyWith(timezoneInfoId: () => null);
      final option =
          ((buildRescheduleBody(d)['event']
                          as Map)['event_schedule_options_attributes']
                      as List)
                  .single
              as Map;
      expect(option.containsKey('timezone_info_id'), isFalse);
    });

    test('an incomplete draft cannot be sent', () {
      expect(
        () => buildRescheduleBody(const EventDraft(place: PlaceItem(id: 5))),
        throwsStateError,
      );
    });
  });

  group('scores', () {
    test('sets per scoring format', () {
      expect(scoreSetCount('sf_best_of_3_sets'), 3);
      expect(scoreSetCount('sf_best_of_3_games'), 3);
      expect(scoreSetCount('sf_fast4_tennis'), 3);
      expect(scoreSetCount('sf_best_of_5_sets'), 5);
      expect(scoreSetCount('sf_single_set'), 1);
      expect(scoreSetCount('sf_reach_points'), 1);
      expect(scoreSetCount(null), 1);
    });

    test('validation', () {
      const empty = (top: '', bottom: '');
      expect(validateSetScores([empty, empty]), [ScoreError.noScores]);
      expect(validateSetScores([(top: '6', bottom: ''), empty]), [
        ScoreError.incompleteSet,
      ]);
      expect(validateSetScores([(top: '6', bottom: 'x')]), [
        ScoreError.notANumber,
      ]);
      expect(validateSetScores([(top: '6', bottom: '-1')]), [
        ScoreError.notANumber,
      ]);
      expect(validateSetScores([(top: ' 6 ', bottom: '4'), empty]), isEmpty);
    });

    test('sets won', () {
      expect(
        setsWon([
          (top: '6', bottom: '4'),
          (top: '3', bottom: '6'),
          (top: '7', bottom: '5'),
          (top: '6', bottom: '6'),
          (top: '', bottom: ''),
        ]),
        (top: 2, bottom: 1),
      );
    });

    test('existing scores are prefilled and summarized', () {
      final m = _event('events_show_manage_game').eventMatches!.first;
      expect(prefillSets(m), [
        (top: '6', bottom: '4'),
        (top: '7', bottom: '6'),
        (top: '', bottom: ''),
      ]);
      expect(scoreSummary(m), '6-4, 7-6(5)');
      final open = _event('events_show_manage_game').eventMatches!.last;
      expect(prefillSets(open), [(top: '', bottom: '')]); // single set
      expect(scoreSummary(open), isEmpty);
    });

    test('the body has both sides of each filled set', () {
      final m = _event('events_show_manage_game').eventMatches!.last;
      expect(
        buildUpdateScoresBody(m, [
          (top: ' 6', bottom: '3 '),
        ], unfinished: false),
        {
          'event_match': {
            'deciding_set_type': null,
            'event_scores_attributes': [
              {
                'event_match_side_id': 403,
                'set': '1',
                'score': '6',
                'set_tie_breaker': false,
                'match_tie_breaker': false,
              },
              {
                'event_match_side_id': 404,
                'set': '1',
                'score': '3',
                'set_tie_breaker': false,
                'match_tie_breaker': false,
              },
            ],
            'request_unfinished_match': false,
          },
        },
      );
    });

    test('empty sets are skipped and tie-breaks are sent back unchanged', () {
      final m = _event('events_show_manage_game').eventMatches!.first;
      final body = buildUpdateScoresBody(
        m,
        [
          (top: '6', bottom: '4'),
          (top: '7', bottom: '6'),
          (top: '', bottom: ''),
        ],
        unfinished: true,
        tieBreaks: prefillTieBreaks(m),
        decidingSetType: 'dst_decide_later',
      );
      final match = body['event_match'] as Map<String, dynamic>;
      expect(match['deciding_set_type'], 'dst_decide_later');
      expect(match['request_unfinished_match'], isTrue);
      final scores = (match['event_scores_attributes'] as List)
          .cast<Map<String, dynamic>>();
      // 2 sets x 2 sides + the 2 stored set tie-break scores.
      expect(scores, hasLength(6));
      expect(
        scores
            .where((s) => s['set_tie_breaker'] == true)
            .map((s) => (s['event_match_side_id'], s['score'])),
        [(401, '7'), (402, '5')],
      );
      expect(scores.every((s) => !s.containsKey('id')), isTrue);
    });

    test('a tie-break that is no longer entered is cleared by its id', () {
      final m = _event('events_show_manage_game').eventMatches!.first;
      // The second set is now 3-6: no tie-break any more.
      final body = buildUpdateScoresBody(m, [
        (top: '6', bottom: '4'),
        (top: '3', bottom: '6'),
      ], unfinished: false);
      final scores =
          ((body['event_match'] as Map)['event_scores_attributes'] as List)
              .cast<Map<String, dynamic>>();
      final cleared = scores.where((s) => s.containsKey('id')).toList();
      expect(cleared, hasLength(2));
      expect(cleared.every((s) => s['score'] == '' && s['set'] == '2'), isTrue);
      expect(cleared.every((s) => s['set_tie_breaker'] == true), isTrue);
    });

    test('a match without sides cannot be scored', () {
      expect(
        () => buildUpdateScoresBody(const EventMatch(id: 1), [
          (top: '1', bottom: '0'),
        ], unfinished: false),
        throwsStateError,
      );
    });
  });

  group('tie-breaks', () {
    test('only tennis and padel have them', () {
      expect(allowsTieBreak('st_tennis'), isTrue);
      expect(allowsTieBreak('st_padel'), isTrue);
      expect(allowsTieBreak('st_pickleball'), isFalse);
      expect(allowsTieBreak(null), isFalse);
    });

    test('a set is tied at the minimum score', () {
      bool tied(String a, String b, {int min = 6, bool allow = true}) =>
          needsSetTieBreak((top: a, bottom: b), allow: allow, minimum: min);
      expect(tied('6', '6'), isTrue);
      expect(tied('7', '7'), isTrue);
      expect(tied('5', '5'), isFalse);
      expect(tied('6', '4'), isFalse);
      expect(tied('', ''), isFalse);
      expect(tied('6', '6', allow: false), isFalse);
      expect(tied('0', '0', min: 0), isFalse);
    });

    test('a tied set goes to its tie-break', () {
      expect(setWinner((top: '6', bottom: '4')), 1);
      expect(setWinner((top: '4', bottom: '6')), -1);
      expect(setWinner((top: '6', bottom: '6')), 0);
      expect(setWinner((top: '6', bottom: '6'), (top: '5', bottom: '7')), -1);
      expect(setWinner((top: '6', bottom: '6'), (top: '7', bottom: '7')), 0);
      expect(setWinner((top: '', bottom: '')), 0);
    });

    test('sets won count tie-breaks and a match tie-break', () {
      expect(
        setsWon(
          [(top: '6', bottom: '6'), (top: '3', bottom: '6')],
          tieBreaks: {1: (top: '7', bottom: '4')},
        ),
        (top: 1, bottom: 1),
      );
      expect(
        setsWon(
          [(top: '6', bottom: '4'), (top: '3', bottom: '6')],
          matchTieBreak: (top: '8', bottom: '10'),
        ),
        (top: 1, bottom: 2),
      );
    });

    group('layout', () {
      const level = [(top: '6', bottom: '4'), (top: '3', bottom: '6')];
      ScoreLayout layout({
        String format = 'sf_best_of_3_sets',
        String sport = 'st_tennis',
        String? deciding,
        List<SetScore> sets = level,
      }) => scoreLayout(
        format: format,
        sportType: sport,
        decidingSetType: deciding,
        sets: sets,
      );

      test('level sets ask how the last set is played', () {
        expect(layout().askDecidingSet, isTrue);
        expect(layout(deciding: 'dst_decide_later').askDecidingSet, isTrue);
        expect(layout().setRows, 3);
        expect(layout().matchTieBreakRow, isFalse);
      });

      test('not asked once decided, in other sports or when not level', () {
        expect(layout(deciding: 'dst_regular_set').askDecidingSet, isFalse);
        expect(layout(sport: 'st_pickleball').askDecidingSet, isFalse);
        expect(
          layout(sets: const [(top: '6', bottom: '4'), (top: '6', bottom: '3')])
              .askDecidingSet,
          isFalse,
        );
      });

      test('a tie-break replaces the last set', () {
        final l = layout(deciding: 'dst_tie_break');
        expect(l.setRows, 2);
        expect(l.matchTieBreakRow, isTrue);
        expect(l.askDecidingSet, isFalse);
        final five = layout(
          format: 'sf_best_of_5_sets',
          deciding: 'dst_tie_break',
        );
        expect(five.setRows, 4);
        expect(five.matchTieBreakRow, isTrue);
      });

      test('best of five asks at two sets each', () {
        const twoTwo = [
          (top: '6', bottom: '4'),
          (top: '4', bottom: '6'),
          (top: '6', bottom: '3'),
          (top: '2', bottom: '6'),
        ];
        expect(
          layout(format: 'sf_best_of_5_sets', sets: twoTwo).askDecidingSet,
          isTrue,
        );
        expect(
          layout(
            format: 'sf_best_of_5_sets',
            sets: twoTwo.take(2).toList(),
          ).askDecidingSet,
          isFalse,
        );
      });

      test('single sets and other formats have no tie-break row', () {
        final l = layout(format: 'sf_single_set', deciding: 'dst_tie_break');
        expect(l.setRows, 1);
        expect(l.matchTieBreakRow, isFalse);
      });
    });

    test('validation needs both tie-break scores, apart', () {
      List<ScoreError> check({
        TieBreaks tb = const {},
        SetScore? mtb,
        bool mtbNeeded = false,
      }) => validateTieBreaks(
        [(top: '6', bottom: '6')],
        tieBreaks: tb,
        matchTieBreak: mtb,
        allow: true,
        minimum: 6,
        matchTieBreakNeeded: mtbNeeded,
      );
      expect(check(), [ScoreError.incompleteSet]);
      expect(check(tb: {1: (top: '7', bottom: '')}), [
        ScoreError.incompleteSet,
      ]);
      expect(check(tb: {1: (top: '7', bottom: 'x')}), [ScoreError.notANumber]);
      expect(check(tb: {1: (top: '7', bottom: '7')}), [
        ScoreError.tieBreakDrawn,
      ]);
      expect(check(tb: {1: (top: '7', bottom: '5')}), isEmpty);
      expect(
        check(
          tb: {1: (top: '7', bottom: '5')},
          mtb: (top: '', bottom: ''),
          mtbNeeded: true,
        ),
        [ScoreError.incompleteSet],
      );
      expect(
        check(tb: {1: (top: '7', bottom: '5')}, mtb: (top: '', bottom: '')),
        isEmpty,
      );
    });

    test(
      'the body carries tie-breaks, the match tie-break and deciding type',
      () {
        final m = _event('events_show_manage_game').eventMatches!.last;
        final body = buildUpdateScoresBody(
          m,
          [(top: '6', bottom: '6')],
          unfinished: false,
          tieBreaks: {1: (top: '7', bottom: '5')},
          matchTieBreak: (top: '10', bottom: '8'),
          decidingSetType: 'dst_tie_break',
        );
        final match = body['event_match'] as Map<String, dynamic>;
        expect(match['deciding_set_type'], 'dst_tie_break');
        final scores = (match['event_scores_attributes'] as List)
            .cast<Map<String, dynamic>>();
        (int, String, String, bool, bool) key(Map<String, dynamic> s) => (
          s['event_match_side_id'] as int,
          s['set'] as String,
          s['score'] as String,
          s['set_tie_breaker'] as bool,
          s['match_tie_breaker'] as bool,
        );
        expect(scores.map(key), [
          (403, '1', '6', false, false),
          (404, '1', '6', false, false),
          (403, '1', '7', true, false),
          (404, '1', '5', true, false),
          (403, '6', '10', false, true),
          (404, '6', '8', false, true),
        ]);
      },
    );

    test('stored tie-breaks are read back', () {
      final m = _event('events_show_manage_game').eventMatches!.first;
      expect(prefillTieBreaks(m), {2: (top: '7', bottom: '5')});
      expect(prefillMatchTieBreak(m), isNull);
      const withMtb = EventMatch(
        eventMatchSides: [
          EventMatchSide(
            id: 1,
            side: 'ecs_top',
            eventScores: [
              EventScore(set: '6', score: '10', matchTieBreaker: true),
            ],
          ),
          EventMatchSide(
            id: 2,
            side: 'ecs_bottom',
            eventScores: [
              EventScore(set: '6', score: '8', matchTieBreaker: true),
            ],
          ),
        ],
      );
      expect(prefillMatchTieBreak(withMtb), (top: '10', bottom: '8'));
      expect(scoreSummary(withMtb), '[10-8]');
    });
  });

  group('people', () {
    test('status groups', () {
      expect(groupOfStatus('eus_confirmed'), ParticipantGroup.confirmed);
      expect(groupOfStatus('eus_accepted'), ParticipantGroup.confirmed);
      expect(
        groupOfStatus('eus_to_be_confirmed'),
        ParticipantGroup.toBeConfirmed,
      );
      expect(groupOfStatus('eus_waitlisted'), ParticipantGroup.waitlisted);
      expect(groupOfStatus('eus_invited'), ParticipantGroup.invited);
      expect(
        groupOfStatus('eus_declined_with_other_courts'),
        ParticipantGroup.declined,
      );
      expect(groupOfStatus('something'), ParticipantGroup.other);
      expect(groupOfStatus(null), ParticipantGroup.other);
    });

    test('the role people are added with', () {
      const practice = EventDetails(eventType: 'et_practice_drill');
      const meetup = EventDetails(eventType: 'et_casual_meeting');
      expect(addRoleFor(practice, coach: false), 'ur_player');
      expect(addRoleFor(practice, coach: true), 'ur_coach');
      expect(addRoleFor(meetup, coach: false), 'ur_audience');
    });
  });
}
