import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

InMemoryContentCache _cachedContent() => InMemoryContentCache()
  ..snapshot = ContentSnapshot(
    messages: {
      'home_page': {
        'upcoming_events_title': 'Coming up next',
        'pending_actions_no_actions_title': 'All caught up',
      },
      'schedule': {
        'nav_title': 'My calendar',
        'events_title': 'Soon',
        'past_events_title': 'History',
        'no_upcoming_events_title': 'Nothing planned',
      },
    },
    preLoginMessages: {
      'introduction': {
        'product_title': 'Play more tennis',
        'sign_up_button': 'Join now',
      },
    },
    referenceData: [
      {
        'id': 1,
        'data_type': 'event_type',
        'key': 'et_practice_drill',
        'localized_label': 'Practice drill',
      },
    ],
  );

void main() {
  testWidgets('home and event tiles use server strings and reference labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final repo = FakeScheduleRepository(
      upcoming: [scheduleItem(1, type: 'et_practice_drill')],
    );
    await tester.pumpWidget(
      signedInApp(schedule: repo, contentCache: _cachedContent()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming up next'), findsOneWidget);
    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('Upcoming'), findsNothing); // ARB fallback replaced
    // Tile title: reference label, not "Practice Drill" from the key.
    expect(find.text('Practice drill'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keys the server did not send keep the local fallback', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp(contentCache: _cachedContent()));
    await tester.pumpAndSettle();
    expect(find.text('Recent games'), findsOneWidget); // no server key set
    expect(find.text('No upcoming events.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('schedule uses the server titles', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(signedInApp(contentCache: _cachedContent()));
    await tester.pumpAndSettle();
    await tester.tap(_id(MainShellTestIds.navSchedule));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.root), findsOneWidget);
    expect(find.text('My calendar'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Nothing planned'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('signed-out welcome uses the pre-login strings', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(signedOutApp(contentCache: _cachedContent()));
    await tester.pumpAndSettle();
    expect(_id(WelcomeTestIds.root), findsOneWidget);
    expect(find.text('Play more tennis'), findsOneWidget);
    expect(find.text('Join now'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget); // not sent -> fallback
    handle.dispose();
  });

  testWidgets(
    'without cached or fetched content everything uses the ARB fallbacks',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      expect(find.text('Hi, Sam'), findsOneWidget);
      handle.dispose();
    },
  );
}
