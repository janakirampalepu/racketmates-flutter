import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_drafts_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

const _ann = AppUser(id: 11, firstName: 'Ann', lastName: 'Lee');

const _summary = DraftSummary(
  eventId: 77,
  eventType: 'et_practice_drill',
  sportType: 'st_tennis',
  courtsLabel: '2 courts',
  lastUpdatedAt: '2026-10-20T10:00:00Z',
);

Map<String, dynamic> _savedRequest({String screen = 'sport'}) {
  final body = buildCreateEventBody(
    EventDraft(
      eventType: 'et_practice_drill',
      sport: SportKey.tennis,
      invitees: const [_ann],
    ),
    asDraft: true,
    screen: screen == 'sport'
        ? CreateEventStep.sport
        : CreateEventStep.settings,
  );
  return {
    'event': {...body['event'] as Map<String, dynamic>},
  };
}

Future<void> _openDrafts(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navSchedule));
  await tester.pumpAndSettle();
  await tester.tap(_id(EventDraftActionIds.scheduleButton));
  await tester.pumpAndSettle();
}

Future<void> _startWizard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navSchedule));
  await tester.pumpAndSettle();
  await tester.tap(_id(ScheduleTestIds.createEvent));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventTypeTestIds.type('et_practice_drill')));
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(_id(EventDraftActionIds.menu));
  await tester.pumpAndSettle();
  await tester.tap(_id(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the drafts button lists drafts, or says there are none', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp(drafts: FakeDraftsRepository()));
    await _openDrafts(tester);
    expect(_id(EventDraftsTestIds.empty), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a draft shows what it is and when it was saved', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(
      signedInApp(drafts: FakeDraftsRepository(drafts: [_summary])),
    );
    await _openDrafts(tester);
    expect(_id(EventDraftsTestIds.draft(77)), findsOneWidget);
    expect(find.textContaining('2 courts'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a failed list can be retried', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(drafts: [_summary])..listFails = true;
    await tester.pumpWidget(signedInApp(drafts: drafts));
    await _openDrafts(tester);
    expect(_id(EventDraftsTestIds.error), findsOneWidget);
    drafts.listFails = false;
    await tester.tap(_id(EventDraftsTestIds.retry));
    await tester.pumpAndSettle();
    expect(_id(EventDraftsTestIds.draft(77)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('deleting asks first and removes the draft', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(drafts: [_summary]);
    await tester.pumpWidget(signedInApp(drafts: drafts));
    await _openDrafts(tester);

    await tester.tap(_id(EventDraftsTestIds.delete(77)));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDraftsTestIds.confirmNo));
    await tester.pumpAndSettle();
    expect(drafts.deleted, isEmpty);

    await tester.tap(_id(EventDraftsTestIds.delete(77)));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDraftsTestIds.confirmYes));
    await tester.pumpAndSettle();
    expect(drafts.deleted, [77]);
    expect(_id(EventDraftsTestIds.empty), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a delete that fails keeps the draft and says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(drafts: [_summary])
      ..deleteFailure = const OfflineFailure();
    await tester.pumpWidget(signedInApp(drafts: drafts));
    await _openDrafts(tester);
    await tester.tap(_id(EventDraftsTestIds.delete(77)));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDraftsTestIds.confirmYes));
    await tester.pumpAndSettle();
    expect(
      find.text('The draft could not be deleted. Please try again.'),
      findsOneWidget,
    );
    expect(_id(EventDraftsTestIds.draft(77)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('opening a draft goes to the step it was saved on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(
      drafts: [_summary],
      requests: {77: _savedRequest(screen: 'settings')},
    );
    final create = FakeCreateEventRepository()..usersById = {11: _ann};
    await tester.pumpWidget(signedInApp(drafts: drafts, createEvent: create));
    await _openDrafts(tester);
    await tester.tap(_id(EventDraftsTestIds.draft(77)));
    await tester.pumpAndSettle();
    expect(drafts.opened, [77]);
    expect(_id(CreateEventSettingsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a draft that cannot be read says so and stays', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(
      drafts: [_summary],
      requests: {
        77: {'event': <String, dynamic>{}},
      },
    );
    await tester.pumpWidget(signedInApp(drafts: drafts));
    await _openDrafts(tester);
    await tester.tap(_id(EventDraftsTestIds.draft(77)));
    await tester.pumpAndSettle();
    expect(find.text('This draft could not be opened.'), findsOneWidget);
    expect(_id(EventDraftsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('saving from a step posts a draft and shows the list', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final create = FakeCreateEventRepository();
    final drafts = FakeDraftsRepository();
    await tester.pumpWidget(signedInApp(createEvent: create, drafts: drafts));
    await _startWizard(tester);
    await _menu(tester, EventDraftActionIds.save);

    final e = create.bodies.single['event'] as Map<String, dynamic>;
    expect(e['request_save_as_draft'], isTrue);
    expect(e['event_type'], 'et_practice_drill');
    expect(e['event_screen'], isNotNull);
    expect(e.containsKey('request_draft_event_id'), isFalse);
    expect(_id(EventDraftsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a draft that cannot be saved keeps the wizard open', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final create = FakeCreateEventRepository()
      ..createFailure = const OfflineFailure();
    await tester.pumpWidget(
      signedInApp(createEvent: create, drafts: FakeDraftsRepository()),
    );
    await _startWizard(tester);
    await _menu(tester, EventDraftActionIds.save);
    expect(
      find.text('The draft could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(_id(CreateEventSportTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('discarding asks first, and keeps editing on cancel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final create = FakeCreateEventRepository();
    final drafts = FakeDraftsRepository();
    await tester.pumpWidget(signedInApp(createEvent: create, drafts: drafts));
    await _startWizard(tester);
    await _menu(tester, EventDraftActionIds.discard);
    await tester.tap(_id(EventDraftActionIds.discardKeep));
    await tester.pumpAndSettle();
    expect(_id(CreateEventSportTestIds.root), findsOneWidget);

    await _menu(tester, EventDraftActionIds.discard);
    await tester.tap(_id(EventDraftActionIds.discardConfirm));
    await tester.pumpAndSettle();
    expect(_id(CreateEventSportTestIds.root), findsNothing);
    expect(create.bodies, isEmpty);
    expect(drafts.deleted, isEmpty);
    handle.dispose();
  });

  testWidgets('discarding a resumed draft deletes it', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final drafts = FakeDraftsRepository(
      drafts: [_summary],
      requests: {77: _savedRequest()},
    );
    await tester.pumpWidget(
      signedInApp(
        drafts: drafts,
        createEvent: FakeCreateEventRepository()..usersById = {11: _ann},
      ),
    );
    await _openDrafts(tester);
    await tester.tap(_id(EventDraftsTestIds.draft(77)));
    await tester.pumpAndSettle();
    await _menu(tester, EventDraftActionIds.discard);
    await tester.tap(_id(EventDraftActionIds.discardConfirm));
    await tester.pumpAndSettle();
    expect(drafts.deleted, [77]);
    handle.dispose();
  });

  testWidgets('saving a resumed draft again names the draft it replaces', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final create = FakeCreateEventRepository()..usersById = {11: _ann};
    final drafts = FakeDraftsRepository(
      drafts: [_summary],
      requests: {77: _savedRequest()},
    );
    await tester.pumpWidget(signedInApp(createEvent: create, drafts: drafts));
    await _openDrafts(tester);
    await tester.tap(_id(EventDraftsTestIds.draft(77)));
    await tester.pumpAndSettle();
    await _menu(tester, EventDraftActionIds.save);
    final e = create.bodies.single['event'] as Map<String, dynamic>;
    expect(e['request_draft_event_id'], 77);
    expect(e['request_save_as_draft'], isTrue);
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'drafts list meets accessibility guidelines (${dark ? 'dark' : 'light'})',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          signedInApp(drafts: FakeDraftsRepository(drafts: [_summary])),
        );
        await _openDrafts(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
