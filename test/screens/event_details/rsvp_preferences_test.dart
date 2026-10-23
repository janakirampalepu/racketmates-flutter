import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

EventParticipant _p(int id, int user, String first, String last) =>
    EventParticipant(
      id: id,
      userId: user,
      user: AppUser(id: user, firstName: first, lastName: last),
    );

/// `events_show_invited` as a round robin, changed by [edit].
EventDetailsResponse _roundRobin({
  String game = 'egt_both',
  String partnership = 'ept_fixed',
  void Function(Map<String, dynamic> mine)? edit,
}) {
  final json = apiFixture('events_show_invited');
  final event = json['event'] as Map<String, dynamic>;
  event['event_type'] = 'et_round_robin';
  event['game_type'] = game;
  event['partnership_type'] = partnership;
  final mine =
      (event['current_user_event_details'] as List).first
          as Map<String, dynamic>;
  mine['user'] = {'id': 8, 'first_name': 'Me', 'last_name': 'Self'};
  edit?.call(mine);
  return EventDetailsResponse.fromJson(json);
}

Future<FakeEventActionsRepository> _open(
  WidgetTester tester,
  EventDetailsResponse initial, {
  List<EventParticipant> candidates = const [],
  AppFailure? failure,
}) async {
  useTallScreen(tester);
  final actions =
      FakeEventActionsRepository(
          response: EventDetailsResponse.fromJson(
            apiFixture('events_show_accepted'),
          ),
          failure: failure,
        )
        ..participantGroups = {
          'status': [
            EventParticipantGroup(
              key: 'eus_confirmed',
              label: 'Confirmed',
              eventParticipants: candidates,
            ),
          ],
        };
  await tester.pumpWidget(
    signedInApp(
      schedule: FakeScheduleRepository(event: initial.event),
      actions: actions,
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(AppRoutes.eventFor(101)));
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

/// Taps and lets the action finish without settling (a snack bar must stay).
Future<void> _tapAndWait(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

FilledButton _submit(WidgetTester tester) => tester.widget<FilledButton>(
  find.descendant(
    of: _id(EventDetailsTestIds.prefsSubmit),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  final zoe = _p(77, 5, 'Zoe', 'Vega');
  final max = _p(78, 6, 'Max', 'Ray');

  group('answering a round robin', () {
    testWidgets('a partner is needed before confirming, then sent along', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        _roundRobin(),
        candidates: [zoe, max],
      );
      await _tap(tester, EventDetailsTestIds.action('accept'));
      expect(_id(EventDetailsTestIds.prefsSheet), findsOneWidget);
      expect(_submit(tester).onPressed, isNull); // has a partner, none chosen

      await _tap(tester, EventDetailsTestIds.prefsSelectPartner);
      final q = actions.participantQueries.single;
      expect(q['groupBy'], 'status');
      expect(q['exclude'], [8]); // not myself
      expect(q['excludeWithPartner'], isTrue);
      expect(q['statuses'], ['eus_confirmed']);
      expect(find.text('Confirmed (2)'), findsOneWidget);

      await _tap(tester, EventDetailsTestIds.partnerOption(77));
      await _tap(tester, EventDetailsTestIds.partnerSelect);
      expect(find.text('Zoe Vega'), findsOneWidget);
      expect(_submit(tester).onPressed, isNotNull);

      await tester.enterText(_field(EventDetailsTestIds.prefsNotes), 'Late');
      await tester.pump();
      await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
      expect(actions.calls, ['accept:101:1']);
      expect(actions.preferences.single, {
        'preferred_match_type': 'mt_doubles',
        'notes': 'Late',
        'event_partner_id': 77,
      });
      handle.dispose();
    });

    testWidgets('needing a partner sends none, and singles or doubles', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, _roundRobin());
      await _tap(tester, EventDetailsTestIds.action('accept'));
      await _tap(
        tester,
        EventDetailsTestIds.prefsPartnerType('eppp_needs_partner'),
      );
      expect(_id(EventDetailsTestIds.prefsSelectPartner), findsNothing);
      await _tap(tester, EventDetailsTestIds.prefsMatch('mt_undecided'));
      expect(_submit(tester).onPressed, isNotNull);
      await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
      expect(actions.preferences.single, {
        'preferred_match_type': 'mt_undecided',
        'notes': '',
      });
      handle.dispose();
    });

    testWidgets('singles only events do not ask', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, _roundRobin(game: 'egt_singles'));
      await _tapAndWait(tester, EventDetailsTestIds.action('accept'));
      expect(_id(EventDetailsTestIds.prefsSheet), findsNothing);
      expect(actions.calls, ['accept:101:1']);
      expect(actions.preferences.single, isEmpty);
      handle.dispose();
    });

    testWidgets('rotating partners with one game type do not ask', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        _roundRobin(game: 'egt_doubles', partnership: 'ept_rotating'),
      );
      await _tapAndWait(tester, EventDetailsTestIds.action('accept'));
      expect(_id(EventDetailsTestIds.prefsSheet), findsNothing);
      expect(actions.preferences.single, isEmpty);
      handle.dispose();
    });

    testWidgets(
      'rotating partners with both game types ask the match type only',
      (tester) async {
        final handle = tester.ensureSemantics();
        final actions = await _open(
          tester,
          _roundRobin(partnership: 'ept_rotating'),
        );
        await _tap(tester, EventDetailsTestIds.action('accept'));
        expect(
          _id(EventDetailsTestIds.prefsMatch('mt_doubles')),
          findsOneWidget,
        );
        expect(_id(EventDetailsTestIds.prefsSelectPartner), findsNothing);
        expect(_submit(tester).onPressed, isNotNull);
        await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
        expect(actions.preferences.single, {
          'preferred_match_type': 'mt_doubles',
          'notes': '',
        });
        handle.dispose();
      },
    );

    testWidgets('closing the sheet answers nothing', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, _roundRobin());
      await _tap(tester, EventDetailsTestIds.action('accept'));
      await tester.tapAt(const Offset(10, 10)); // the scrim
      await tester.pumpAndSettle();
      expect(_id(EventDetailsTestIds.prefsSheet), findsNothing);
      expect(actions.calls, isEmpty);
      handle.dispose();
    });
  });

  group('choosing a partner', () {
    testWidgets('no partners and searching', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, _roundRobin());
      await _tap(tester, EventDetailsTestIds.action('accept'));
      await _tap(tester, EventDetailsTestIds.prefsSelectPartner);
      expect(_id(EventDetailsTestIds.partnerNone), findsOneWidget);
      await tester.enterText(_field(EventDetailsTestIds.partnerSearch), 'zo');
      await tester.pumpAndSettle();
      expect(actions.participantQueries.last['search'], 'zo');
      handle.dispose();
    });

    testWidgets('a list that cannot be loaded says so', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, _roundRobin());
      await _tap(tester, EventDetailsTestIds.action('accept'));
      actions.failure = const OfflineFailure();
      await _tap(tester, EventDetailsTestIds.prefsSelectPartner);
      expect(_id(EventDetailsTestIds.partnerError), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a chosen partner can be changed', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        _roundRobin(),
        candidates: [zoe, max],
      );
      await _tap(tester, EventDetailsTestIds.action('accept'));
      await _tap(tester, EventDetailsTestIds.prefsSelectPartner);
      await _tap(tester, EventDetailsTestIds.partnerOption(77));
      await _tap(tester, EventDetailsTestIds.partnerSelect);
      await _tap(tester, EventDetailsTestIds.prefsChangePartner);
      await _tap(tester, EventDetailsTestIds.partnerOption(78));
      await _tap(tester, EventDetailsTestIds.partnerSelect);
      expect(find.text('Max Ray'), findsOneWidget);
      await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
      expect(actions.preferences.single['event_partner_id'], 78);
      handle.dispose();
    });
  });

  group('the partner on the event page', () {
    Map<String, dynamic> zoeJson() => {
      'id': 77,
      'user_id': 5,
      'user': {'id': 5, 'first_name': 'Zoe', 'last_name': 'Vega'},
    };

    EventDetailsResponse accepted(void Function(Map<String, dynamic>) edit) {
      final json = apiFixture('events_show_accepted');
      final event = json['event'] as Map<String, dynamic>;
      event['event_type'] = 'et_round_robin';
      event['game_type'] = 'egt_both';
      event['partnership_type'] = 'ept_fixed';
      final mine =
          (event['current_user_event_details'] as List).first
              as Map<String, dynamic>;
      mine['user'] = {'id': 8, 'first_name': 'Me', 'last_name': 'Self'};
      mine['is_player'] = true;
      edit(mine);
      return EventDetailsResponse.fromJson(json);
    }

    testWidgets('shows who the partner is and lets it change', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        accepted((m) {
          m['partnership_preference'] = 'eppp_has_partner';
          m['event_partner'] = zoeJson();
          m['preferred_match_type'] = 'mt_undecided';
        }),
        candidates: [max],
      );
      expect(find.text('Your partner'), findsOneWidget);
      expect(find.text('Zoe Vega'), findsOneWidget);

      await _tap(tester, EventDetailsTestIds.partnerEdit);
      // No note when only changing; starts from what is stored.
      expect(_id(EventDetailsTestIds.prefsNotes), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Zoe Vega'), findsWidgets);
      await _tap(tester, EventDetailsTestIds.prefsChangePartner);
      await _tap(tester, EventDetailsTestIds.partnerOption(78));
      await _tap(tester, EventDetailsTestIds.partnerSelect);
      await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
      expect(actions.calls, ['preference:101:1']);
      expect(actions.preferences.single, {
        'preferred_match_type': 'mt_undecided',
        'event_partner_id': 78,
      });
      expect(find.text('Your game preferences were saved.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rejected change shows a message', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        accepted((m) {
          m['partnership_preference'] = 'eppp_has_partner';
          m['event_partner'] = zoeJson();
        }),
      );
      actions.failure = const ServerFailure(422, 'Partner taken');
      await _tap(tester, EventDetailsTestIds.partnerEdit);
      await _tapAndWait(tester, EventDetailsTestIds.prefsSubmit);
      expect(find.text('Partner taken'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('someone who asked is shown, without an edit button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, accepted((m) => m['event_partner'] = zoeJson()));
      expect(find.text('Someone wants to play with you'), findsOneWidget);
      expect(_id(EventDetailsTestIds.partnerEdit), findsNothing);
      handle.dispose();
    });

    testWidgets('wanting a partner without one offers to choose', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        accepted((m) => m['partnership_preference'] = 'eppp_has_partner'),
      );
      expect(find.text('You have not chosen a partner yet.'), findsOneWidget);
      await _tap(tester, EventDetailsTestIds.partnerChoose);
      expect(_id(EventDetailsTestIds.prefsSheet), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nothing about partners on other events', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _roundRobin(partnership: 'ept_rotating'));
      expect(_id(EventDetailsTestIds.partnerSection), findsNothing);
      handle.dispose();
    });
  });

  for (final dark in [false, true]) {
    testWidgets('the sheet meets guidelines (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _open(tester, _roundRobin(), candidates: [zoe]);
      await _tap(tester, EventDetailsTestIds.action('accept'));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
