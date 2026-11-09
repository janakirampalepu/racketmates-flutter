import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _openSchedule(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navSchedule));
  await tester.pumpAndSettle();
  expect(_id(ScheduleTestIds.root), findsOneWidget);
}

SessionInfoResponse _free() => const SessionInfoResponse(
  user: SessionInfoUser(id: 7, hasFullFeatureAccess: false),
);

/// An action button's visibility/tap behavior follows the event's own
/// `access` state (native: Android only shows a swipe action when
/// `access == UP_ENABLED`; iOS shows it for anything but `not_available`
/// and branches what tapping does — this app follows iOS's richer model,
/// see `handleEventActionTap`).
void main() {
  testWidgets('an enabled action opens the event directly', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [
            ScheduleItem(
              eventId: 1,
              eventDate: '2026-11-03',
              eventType: 'et_game',
              swipeRight: const EventSwipeAction(
                action: 'user_action_manage_event',
                access: 'up_enabled',
              ),
            ),
          ],
        ],
      },
    );
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);
    expect(find.text('Manage event'), findsOneWidget);

    await tester.tap(find.text('Manage event'));
    await tester.pumpAndSettle();
    expect(_id(EventDetailsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'a disabled action explains itself instead of opening the event',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository(
        pages: {
          ScheduleTab.upcoming: [
            [
              ScheduleItem(
                eventId: 1,
                eventDate: '2026-11-03',
                eventType: 'et_game',
                swipeRight: const EventSwipeAction(
                  action: 'user_action_manage_event',
                  access: 'up_disabled',
                  message: 'Only the organizer can manage this event.',
                ),
              ),
            ],
          ],
        },
      );
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);

      await tester.tap(find.text('Manage event'));
      await tester.pumpAndSettle();
      expect(
        find.text('Only the organizer can manage this event.'),
        findsOneWidget,
      );
      expect(_id(EventDetailsTestIds.root), findsNothing);
      handle.dispose();
    },
  );

  testWidgets('a subscription-gated action offers the plans', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [
            ScheduleItem(
              eventId: 1,
              eventDate: '2026-11-03',
              eventType: 'et_game',
              swipeRight: const EventSwipeAction(
                action: 'user_action_manage_event',
                access: 'up_requires_subscription',
              ),
            ),
          ],
        ],
      },
    );
    await tester.pumpWidget(
      signedInApp(
        schedule: repo,
        sessionInfo: FakeSessionInfoRepository(response: _free()),
      ),
    );
    await _openSchedule(tester);

    await tester.tap(find.text('Manage event'));
    await tester.pumpAndSettle();
    expect(_id(SubscriptionTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an action marked not_available falls back to View event', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [
            ScheduleItem(
              eventId: 1,
              eventDate: '2026-11-03',
              eventType: 'et_game',
              swipeRight: const EventSwipeAction(
                action: 'user_action_manage_event',
                access: 'up_not_available',
              ),
            ),
          ],
        ],
      },
    );
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);
    expect(find.text('Manage event'), findsNothing);
    expect(find.text('View event'), findsOneWidget);
    handle.dispose();
  });

  // Confirmed from native source: submit/update/confirm scores go through
  // the exact same action mechanism as every other row action (one
  // adapter/layout on Android, the same `EventSwipeActions` on iOS) — a
  // past event offering one of these used to fall through to the generic
  // "View event" button since Flutter had no case for them at all.
  for (final (action, label) in const [
    ('user_action_submit_scores', 'Submit scores'),
    ('user_action_update_scores', 'Edit scores'),
    ('user_action_confirm_scores', 'Confirm scores'),
  ]) {
    testWidgets('$action renders its own "$label" button', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository(
        pages: {
          ScheduleTab.past: [
            [
              ScheduleItem(
                eventId: 1,
                eventDate: '2026-11-03',
                eventType: 'et_game',
                swipeRight: EventSwipeAction(
                  action: action,
                  access: 'up_enabled',
                ),
              ),
            ],
          ],
        },
      );
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);
      await tester.tap(_id(ScheduleTestIds.topRowPast));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      handle.dispose();
    });
  }
}
