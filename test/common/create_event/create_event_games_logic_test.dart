import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _place = PlaceItem(id: 5, name: 'Central Courts');
const _alex = AppUser(id: 8, firstName: 'Alex');
const _pat = AppUser(id: 9, firstName: 'Pat');
const _sam = AppUser(id: 10, firstName: 'Sam');
const _lee = AppUser(id: 11, firstName: 'Lee');
const _topLeft = MatchSlot(MatchKeys.sideTop, MatchKeys.positionLeft);
const _topCentre = MatchSlot(MatchKeys.sideTop, MatchKeys.positionCenter);
const _bottomCentre = MatchSlot(MatchKeys.sideBottom, MatchKeys.positionCenter);

const _minimums = {'sf_best_of_3_sets': 2, 'sf_single_set': 6};

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

EventDraft _read(ProviderContainer c) => c.read(createEventFlowProvider)!;

/// A game draft built through the flow, like the screens do.
CreateEventFlow _startGame(
  ProviderContainer c, {
  String type = 'et_competitive',
}) {
  final flow = c.read(createEventFlowProvider.notifier)
    ..start()
    ..setEventType(type)
    ..setSport(SportKey.tennis)
    ..setScoringFormat('sf_best_of_3_sets', _minimums)
    ..setPlace(_place);
  return flow;
}

EventDraft _withStart(EventDraft d) => d.copyWith(
  start: () => DateTime(2026, 11, 3, 18),
  timezoneInfoId: () => 77,
);

Map<String, dynamic> _event(EventDraft d) =>
    buildCreateEventBody(d)['event'] as Map<String, dynamic>;

void main() {
  group('match slots', () {
    test('singles has a centre spot per side, doubles two, undecided none', () {
      expect(slotsFor(MatchKeys.singles), hasLength(2));
      expect(slotsFor(MatchKeys.doubles), hasLength(4));
      expect(slotsFor(MatchKeys.undecided), isEmpty);
    });

    test('players move, clear and reset with the match type', () {
      var match = const MatchDraft(matchType: MatchKeys.doubles);
      match = match.withPlayer(_topLeft, _alex);
      expect(match.players[_topLeft], _alex);
      // The same player in another spot moves.
      const topRight = MatchSlot(MatchKeys.sideTop, MatchKeys.positionRight);
      match = match.withPlayer(topRight, _alex);
      expect(match.players.keys, [topRight]);
      expect(match.allSlotsFilled, isFalse);
      expect(match.withoutPlayer(topRight).players, isEmpty);
      expect(match.withType(MatchKeys.singles).players, isEmpty);
      expect(match.withType(MatchKeys.doubles).players, isNotEmpty);
    });

    test('an undecided match counts as doubles for the player limit', () {
      expect(const MatchDraft().playerCount, 4);
      expect(const MatchDraft(matchType: MatchKeys.singles).playerCount, 2);
    });
  });

  group('step order', () {
    test('games: assign later invites, assign now fills the matches', () {
      expect(createEventStepsFor('et_competitive'), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.teamChoice,
        CreateEventStep.settings,
        CreateEventStep.matches,
        CreateEventStep.whenWhere,
        CreateEventStep.assignType,
        CreateEventStep.inviteSettings,
        CreateEventStep.players,
        CreateEventStep.review,
      ]);
      expect(createEventStepsFor('et_casual', assignNow: true), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.teamChoice,
        CreateEventStep.settings,
        CreateEventStep.matches,
        CreateEventStep.whenWhere,
        CreateEventStep.assignType,
        CreateEventStep.assignPlayers,
        CreateEventStep.review,
      ]);
    });

    test('round robin goes through the format and always invites', () {
      expect(createEventStepsFor('et_round_robin'), [
        CreateEventStep.type,
        CreateEventStep.sport,
        CreateEventStep.teamChoice,
        CreateEventStep.settings,
        CreateEventStep.matches,
        CreateEventStep.roundRobinFormat,
        CreateEventStep.whenWhere,
        CreateEventStep.inviteSettings,
        CreateEventStep.players,
        CreateEventStep.review,
      ]);
      expect(
        nextCreateEventStep('et_round_robin', CreateEventStep.matches),
        CreateEventStep.roundRobinFormat,
      );
    });

    test('the flow follows the assignment choice', () {
      final c = _container();
      final flow = _startGame(c);
      expect(
        flow.next(CreateEventStep.assignType),
        CreateEventStep.inviteSettings,
      );
      flow.setAssignNow(value: true);
      expect(
        flow.next(CreateEventStep.assignType),
        CreateEventStep.assignPlayers,
      );
      expect(flow.next(CreateEventStep.assignPlayers), CreateEventStep.review);
    });

    test(
      'only courts of the matches/courts types differ on the venue step',
      () {
        expect(
          eventTypeSpecs['et_practice_drill']!.courtCountOnWhenWhere,
          isTrue,
        );
        expect(
          eventTypeSpecs['et_competitive']!.courtCountOnWhenWhere,
          isFalse,
        );
        expect(
          eventTypeSpecs['et_round_robin']!.courtCountOnWhenWhere,
          isFalse,
        );
        expect(eventTypeSpecs['et_round_robin']!.usesScoring, isTrue);
        expect(eventTypeSpecs['et_group_lesson']!.usesScoring, isFalse);
      },
    );
  });

  group('games in the flow', () {
    test('a game starts with one undecided match and sizes the limits', () {
      final c = _container();
      _startGame(c);
      expect(_read(c).matches.single.matchType, MatchKeys.undecided);
      expect(_read(c).playersLimit, 4);
      expect(_read(c).rsvpLimit, 4);
    });

    test('adding, typing and removing matches updates limits and courts', () {
      final c = _container();
      final flow = _startGame(c)
        ..addMatch()
        ..setMatchType(0, MatchKeys.singles);
      expect(_read(c).playersLimit, 6); // 2 + 4
      expect(_read(c).courtCap, 2);
      flow
        ..toggleCourt(11)
        ..toggleCourt(12)
        ..toggleCourt(13); // third ignored: two matches
      expect(_read(c).courtIds, [11, 12]);
      flow.removeMatch(1);
      expect(_read(c).matches, hasLength(1));
      expect(_read(c).courtIds, [11]);
      expect(_read(c).playersLimit, 2);
      flow.removeMatch(0); // the last match stays
      expect(_read(c).matches, hasLength(1));
    });

    test('changing the sport starts the matches over', () {
      final c = _container();
      final flow = _startGame(c)..addMatch();
      flow.setSport(SportKey.padel);
      expect(_read(c).matches, hasLength(1));
      expect(_read(c).scoring, isNull);
    });
  });

  group('round robin in the flow', () {
    test('limits follow the courts and singles/doubles', () {
      final c = _container();
      final flow = _startGame(c, type: 'et_round_robin')..setCourtCount(3);
      expect(_read(c).playersLimit, 12);
      flow.setGameType(MatchKeys.gameSingles);
      expect(_read(c).playersLimit, 6);
      expect(_read(c).partnershipType, isNull);
      flow.setGameType(MatchKeys.gameBoth);
      expect(_read(c).playersLimit, 12);
      expect(_read(c).partnershipType, MatchKeys.partnersRotating);
    });

    test('changing the players or partners clears the format choice', () {
      final c = _container();
      final flow = _startGame(c, type: 'et_round_robin')
        ..setEventSubType(MatchKeys.formatClassic);
      expect(_read(c).eventSubType, MatchKeys.formatClassic);
      flow.setPartnership(MatchKeys.partnersFixed);
      expect(_read(c).eventSubType, isNull);
      flow
        ..setEventSubType(MatchKeys.formatManual)
        ..setGameType(MatchKeys.gameSingles);
      expect(_read(c).eventSubType, isNull);
    });
  });

  group('scoring', () {
    test('defaults per format', () {
      expect(defaultMinimumScore(ScoringKeys.singleSet, _minimums), 6);
      expect(defaultMinimumScore(ScoringKeys.bestOf3Sets, _minimums), 2);
      expect(defaultMinimumScore(ScoringKeys.bestOf5Sets, _minimums), 0);
      expect(defaultMinimumScore(ScoringKeys.reachPoints, const {}), 10);
      expect(defaultMinimumScore(ScoringKeys.totalPoints, const {}), 20);
      expect(defaultMinimumScore(ScoringKeys.timeBased, const {}), 15);
    });

    test('how each format edits its score', () {
      expect(scoreInputFor(ScoringKeys.singleSet), ScoreInput.number);
      expect(scoreInputFor(ScoringKeys.reachPoints), ScoreInput.number);
      expect(scoreInputFor(ScoringKeys.timeBased), ScoreInput.minutes);
      expect(scoreInputFor(ScoringKeys.bestOf3Sets), ScoreInput.none);
      expect(canChooseDecidingSet(SportKey.tennis), isTrue);
      expect(canChooseDecidingSet(SportKey.padel), isTrue);
      expect(canChooseDecidingSet(SportKey.pickleball), isFalse);
      expect(canChooseDecidingSet(null), isFalse);
    });

    test('choosing a format resets the score and deciding set', () {
      final c = _container();
      final flow = _startGame(c)
        ..setDecidingSetType(ScoringKeys.tieBreak)
        ..setScoringFormat(ScoringKeys.singleSet, _minimums);
      expect(_read(c).scoring!.format, ScoringKeys.singleSet);
      expect(_read(c).scoring!.minimumScore, 6);
      expect(_read(c).scoring!.decidingSetType, ScoringKeys.decideLater);
      flow.setMinimumScore(0);
      expect(_read(c).scoring!.minimumScore, 1);
      flow.setMinimumScore(9);
      expect(_read(c).scoring!.minimumScore, 9);
    });
  });

  group('request body', () {
    test('game with players assigned later', () {
      final c = _container();
      final flow = _startGame(c)
        ..setMatchType(0, MatchKeys.singles)
        ..addMatch()
        ..setMatchType(1, MatchKeys.doubles)
        ..toggleCourt(11)
        ..toggleCourt(12)
        ..toggleInvitee(_alex)
        ..setAllowLogResults(value: true)
        ..assignPlayer(0, _topCentre, _pat); // ignored: assigning later
      expect(flow.next(CreateEventStep.assignType), isNotNull);
      final event = _event(_withStart(_read(c)));

      expect(event['event_type'], 'et_competitive');
      expect(event['sport_type'], 'st_tennis');
      expect(event['scoring_format'], 'sf_best_of_3_sets');
      expect(event['deciding_set_type'], 'dst_decide_later');
      expect(event['minimum_score_to_win'], 2);
      expect(event['allow_participants_to_log_results'], isTrue);
      expect(event['assign_type'], 'at_assign_later');
      expect(event['players_limit'], 6);
      expect(event.containsKey('no_of_courts'), isFalse);
      expect(event['event_venue_courts_attributes'], isEmpty);
      expect(event['event_participants_attributes'], [
        {
          'user_id': 8,
          'is_player': true,
          'is_coach': false,
          'is_audience': false,
        },
      ]);
      expect(event['player_acceptance_type'], acceptOrderOfResponse);
      expect(event['event_matches_attributes'], [
        {
          'match_type': 'mt_singles',
          'order': 1,
          'place_court_id': 11,
          'event_match_sides_attributes': [
            {'side': 'ecs_top', 'event_participants': <Object>[]},
            {'side': 'ecs_bottom', 'event_participants': <Object>[]},
          ],
        },
        {
          'match_type': 'mt_doubles',
          'order': 2,
          'place_court_id': 12,
          'event_match_sides_attributes': [
            {'side': 'ecs_top', 'event_participants': <Object>[]},
            {'side': 'ecs_bottom', 'event_participants': <Object>[]},
          ],
        },
      ]);
      expect(
        event['screen_flow_path'],
        'es_event_type_selection##es_sports_type##es_team_non_team##es_general_settings##'
        'es_courts_addition##es_court_options##es_court_player_assign_type##'
        'es_invite_player_settings##es_invite_players_mgmt##es_review',
      );
    });

    test('game with players assigned now keeps them in the match sides', () {
      final c = _container();
      _startGame(c, type: 'et_casual')
        ..setMatchType(0, MatchKeys.singles)
        ..setAssignNow(value: true)
        ..toggleInvitee(_lee) // an invitee is not sent when assigning now
        ..assignPlayer(0, _topCentre, _alex)
        ..assignPlayer(0, _bottomCentre, _pat);
      final event = _event(_withStart(_read(c)));
      expect(event['assign_type'], 'at_court_addition');
      expect(event['player_acceptance_type'], acceptPickManually);
      expect(event['event_participants_attributes'], isEmpty);
      expect(
        (event['event_matches_attributes'] as List)
            .single['event_match_sides_attributes'],
        [
          {
            'side': 'ecs_top',
            'event_participants': [
              {'user_id': 8, 'position': 'epp_center'},
            ],
          },
          {
            'side': 'ecs_bottom',
            'event_participants': [
              {'user_id': 9, 'position': 'epp_center'},
            ],
          },
        ],
      );
      expect(_read(c).assignedPlayers.map((u) => u.id), [8, 9]);
      expect(event['screen_flow_path'], contains('es_court_player_assignment'));
      expect(
        event['screen_flow_path'],
        isNot(contains('es_invite_players_mgmt')),
      );
    });

    test('doubles match positions', () {
      final c = _container();
      _startGame(c)
        ..setMatchType(0, MatchKeys.doubles)
        ..setAssignNow(value: true)
        ..assignPlayer(0, _topLeft, _alex)
        ..assignPlayer(
          0,
          const MatchSlot(MatchKeys.sideTop, MatchKeys.positionRight),
          _pat,
        )
        ..assignPlayer(
          0,
          const MatchSlot(MatchKeys.sideBottom, MatchKeys.positionLeft),
          _sam,
        )
        ..assignPlayer(
          0,
          const MatchSlot(MatchKeys.sideBottom, MatchKeys.positionRight),
          _lee,
        );
      expect(_read(c).matches.single.allSlotsFilled, isTrue);
      final sides =
          (_event(_withStart(_read(c)))['event_matches_attributes'] as List)
                  .single['event_match_sides_attributes']
              as List;
      expect((sides[0] as Map)['event_participants'], [
        {'user_id': 8, 'position': 'epp_left'},
        {'user_id': 9, 'position': 'epp_right'},
      ]);
      expect((sides[1] as Map)['event_participants'], [
        {'user_id': 10, 'position': 'epp_left'},
        {'user_id': 11, 'position': 'epp_right'},
      ]);
    });

    test('round robin sends courts, game type, partners and format', () {
      final c = _container();
      _startGame(c, type: 'et_round_robin')
        ..setCourtCount(2)
        ..setGameType(MatchKeys.gameDoubles)
        ..setPartnership(MatchKeys.partnersFixed)
        ..setEventSubType(MatchKeys.formatKingOfTheCourt)
        ..toggleCourt(21)
        ..toggleCourt(22)
        ..toggleInvitee(_alex);
      final event = _event(_withStart(_read(c)));
      expect(event['event_type'], 'et_round_robin');
      expect(event['no_of_courts'], 2);
      expect(event['game_type'], 'egt_doubles');
      expect(event['partnership_type'], 'ept_fixed');
      expect(event['event_sub_type'], 'est_king_of_the_court');
      expect(event['assign_type'], 'at_assign_later');
      expect(event['players_limit'], 8);
      expect(event.containsKey('event_matches_attributes'), isFalse);
      expect(event['event_venue_courts_attributes'], [
        {'place_court_id': 21, 'order': 1},
        {'place_court_id': 22, 'order': 2},
      ]);
      expect(event['scoring_format'], 'sf_best_of_3_sets');
      expect(
        event['screen_flow_path'],
        contains('es_round_robin_format_selection'),
      );
    });

    test('round robin singles sends no partnership type', () {
      final c = _container();
      _startGame(c, type: 'et_round_robin')
        ..setGameType(MatchKeys.gameSingles)
        ..setEventSubType(MatchKeys.formatClassic)
        ..toggleInvitee(_alex);
      final event = _event(_withStart(_read(c)));
      expect(event['game_type'], 'egt_singles');
      expect(event.containsKey('partnership_type'), isFalse);
      expect(event['players_limit'], 2);
    });

    test('a scored event without a scoring format cannot be built', () {
      final c = _container();
      c.read(createEventFlowProvider.notifier)
        ..start()
        ..setEventType('et_competitive')
        ..setSport(SportKey.tennis)
        ..setPlace(_place);
      expect(() => _event(_withStart(_read(c))), throwsStateError);
    });
  });
}
