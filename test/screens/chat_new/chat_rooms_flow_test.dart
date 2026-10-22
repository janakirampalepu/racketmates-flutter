import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';
import 'package:racketmates/screens/chat_new/new_chat_test_ids.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _openNewChat(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navChat));
  await tester.pumpAndSettle();
  await tester.tap(find.text('new chat'));
  await tester.pumpAndSettle();
}

AccessInfo _perm(String access, [String? message]) =>
    AccessInfo(access: access, message: message);

EventDetails _event({
  Map<String, AccessInfo>? permissions,
  ChatRoomRef? players,
  ChatRoomRef? captains,
}) => EventDetails(
  id: 101,
  eventType: 'et_practice',
  userPermissions: permissions,
  playerChatRoom: players,
  captainsChatRoom: captains,
);

/// Opens event 101 the way a tapped notification does.
Future<void> _openEvent(
  WidgetTester tester, {
  required EventDetails event,
  FakeChatRepository? chat,
  FakeSessionInfoRepository? sessionInfo,
}) async {
  final push = FakePushPlatform();
  await tester.pumpWidget(
    signedInApp(
      push: push,
      schedule: FakeScheduleRepository(event: event),
      chatRepository: chat,
      sessionInfo: sessionInfo,
    ),
  );
  await tester.pumpAndSettle();
  push.openedController.add(
    const PushMessage(
      id: 'e1',
      data: {'navigation_page': 'nnp_event_details_page', 'event_id': '101'},
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('one-to-one chat', () {
    testWidgets('the channel list offers a new chat; a player opens a room', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await tester.pumpWidget(signedInApp(chatRepository: chat));
      await _openNewChat(tester);
      expect(_id(NewChatTestIds.root), findsOneWidget);
      expect(find.text('Ann Lee'), findsOneWidget);
      expect(find.text('Bo Chan'), findsOneWidget);
      await tester.tap(_id(NewChatTestIds.player(11)));
      await tester.pumpAndSettle();
      expect(chat.roomCalls, ['direct:uid-7:uid-11']);
      expect(find.text('fake channel sendbird_room_1'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('searching narrows the players', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await tester.pumpWidget(signedInApp(chatRepository: chat));
      await _openNewChat(tester);
      await tester.enterText(find.byType(TextField), 'bo');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(chat.searches.last, 'bo');
      expect(find.text('Bo Chan'), findsOneWidget);
      expect(find.text('Ann Lee'), findsNothing);
      handle.dispose();
    });

    testWidgets('no matches and a failing search are reported', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository()..players = const [];
      await tester.pumpWidget(signedInApp(chatRepository: chat));
      await _openNewChat(tester);
      expect(_id(NewChatTestIds.empty), findsOneWidget);
      chat.searchFailure = const OfflineFailure();
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_id(NewChatTestIds.error), findsOneWidget);
      chat.searchFailure = null;
      await tester.tap(_id(NewChatTestIds.retry));
      await tester.pumpAndSettle();
      expect(_id(NewChatTestIds.empty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a room that cannot be created keeps the list and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository()..roomFailure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(chatRepository: chat));
      await _openNewChat(tester);
      await tester.tap(_id(NewChatTestIds.player(11)));
      await tester.pumpAndSettle();
      expect(_id(NewChatTestIds.failed), findsOneWidget);
      expect(find.text('Ann Lee'), findsOneWidget);
      chat.roomFailure = null;
      await tester.tap(_id(NewChatTestIds.player(11)));
      await tester.pumpAndSettle();
      expect(find.text('fake channel sendbird_room_1'), findsOneWidget);
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('meets guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(signedInApp());
        await _openNewChat(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('event chat rooms', () {
    testWidgets('no chat button without a chat permission', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openEvent(tester, event: _event());
      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      expect(_id(EventChatTestIds.button), findsNothing);
      handle.dispose();
    });

    testWidgets('an existing players room opens directly', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {'event.show_players_chat_room': _perm('up_enabled')},
          players: const ChatRoomRef(id: 1, channelUrl: 'players-url'),
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(find.text('fake channel players-url'), findsOneWidget);
      expect(chat.roomCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('a room that does not exist yet is created', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository()..roomUrl = 'created-room';
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {'event.show_players_chat_room': _perm('up_enabled')},
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(chat.roomCalls, ['players:101:null']);
      expect(find.text('fake channel created-room'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('only the captains room: it is the one that opens', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {'event.show_captains_chat_room': _perm('up_enabled')},
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(chat.roomCalls, ['captains:101']);
      handle.dispose();
    });

    testWidgets('with both rooms the user chooses', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {
            'event.show_players_chat_room': _perm('up_enabled'),
            'event.show_captains_chat_room': _perm('up_enabled'),
          },
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(_id(EventChatTestIds.sheet), findsOneWidget);
      await tester.tap(_id(EventChatTestIds.captains));
      await tester.pumpAndSettle();
      expect(chat.roomCalls, ['captains:101']);
      handle.dispose();
    });

    testWidgets('a failing creation says so and stays on the event', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository()..roomFailure = const OfflineFailure();
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {'event.show_players_chat_room': _perm('up_enabled')},
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(
        find.text('The chat room could not be opened. Please try again.'),
        findsOneWidget,
      );
      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a disabled room explains itself', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await _openEvent(
        tester,
        chat: chat,
        event: _event(
          permissions: {
            'event.show_players_chat_room': _perm(
              'up_disabled',
              'Chat opens after the first RSVP.',
            ),
          },
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(find.text('Chat opens after the first RSVP.'), findsOneWidget);
      expect(chat.roomCalls, isEmpty);
      await tester.tap(_id(EventChatTestIds.blockedClose));
      await tester.pumpAndSettle();
      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a room that needs a subscription offers the plans', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatRepository();
      await _openEvent(
        tester,
        chat: chat,
        sessionInfo: FakeSessionInfoRepository(
          response: const SessionInfoResponse(
            user: SessionInfoUser(
              id: 7,
              hasFullFeatureAccess: false,
              trialRemainingDays: 30,
              timezoneIdentifier: 'America/New_York',
            ),
          ),
        ),
        event: _event(
          permissions: {
            'event.show_players_chat_room': _perm('up_requires_subscription'),
          },
        ),
      );
      await tester.tap(_id(EventChatTestIds.button));
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      expect(chat.roomCalls, isEmpty);
      handle.dispose();
    });
  });

  testWidgets('the chat tab still shows the list', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp());
    await tester.pumpAndSettle();
    await tester.tap(_id(MainShellTestIds.navChat));
    await tester.pumpAndSettle();
    expect(_id(ChatTestIds.list), findsOneWidget);
    handle.dispose();
  });
}
