import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/chat/chat_client.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';
import 'package:racketmates/screens/chat_channel_details/chat_channel_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _openChatTab(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navChat));
  await tester.pumpAndSettle();
}

void main() {
  group('chat tab', () {
    testWidgets('shows the channel list once connected', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatClient();
      await tester.pumpWidget(signedInApp(chat: chat));
      await _openChatTab(tester);
      expect(_id(ChatTestIds.list), findsOneWidget);
      expect(find.text('fake channel list'), findsOneWidget);
      expect(chat.connects.single.userId, 'uid-7');
      handle.dispose();
    });

    testWidgets('opening a channel shows the conversation and goes back', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await _openChatTab(tester);
      await tester.tap(find.text('open channel-1'));
      await tester.pumpAndSettle();
      expect(find.text('fake channel channel-1'), findsOneWidget);
      expect(_id(ChatTestIds.channelRoot), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('fake channel list'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the back button in the header also goes back', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await _openChatTab(tester);
      await tester.tap(find.text('open channel-1'));
      await tester.pumpAndSettle();
      await tester.tap(_id(ChatTestIds.channelBackButton));
      await tester.pumpAndSettle();
      expect(find.text('fake channel list'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'the header shows the resolved title and opens the details screen',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        final chatUi = FakeChatUi()
          ..info = const ChatChannelInfo(
            title: 'Alex Morgan',
            members: [
              ChatChannelMember(
                userId: 'u1',
                nickname: 'Alex Morgan',
                isMe: false,
              ),
              ChatChannelMember(userId: 'u2', nickname: 'Me', isMe: true),
            ],
            isMuted: false,
          );
        await tester.pumpWidget(signedInApp(chatUi: chatUi));
        await _openChatTab(tester);
        await tester.tap(find.text('open channel-1'));
        await tester.pumpAndSettle();
        expect(find.text('Alex Morgan'), findsOneWidget);
        await tester.tap(_id(ChatTestIds.channelHeader));
        await tester.pumpAndSettle();
        expect(_id(ChatChannelDetailsTestIds.root), findsOneWidget);
        expect(_id(ChatChannelDetailsTestIds.title), findsOneWidget);
        expect(find.text('Me (You)'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('muting from the details screen flips the switch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chatUi = FakeChatUi();
      await tester.pumpWidget(signedInApp(chatUi: chatUi));
      await _openChatTab(tester);
      await tester.tap(find.text('open channel-1'));
      await tester.pumpAndSettle();
      await tester.tap(_id(ChatTestIds.channelHeader));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.tap(_id(ChatChannelDetailsTestIds.muteSwitch));
      await tester.pumpAndSettle();
      expect(chatUi.muteCalls, [('channel-1', true)]);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a failed connection offers a retry', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatClient()
        ..results = [ChatConnectResult.failed, ChatConnectResult.connected];
      await tester.pumpWidget(signedInApp(chat: chat));
      await _openChatTab(tester);
      expect(_id(ChatTestIds.failed), findsOneWidget);
      await tester.tap(_id(ChatTestIds.retry));
      await tester.pumpAndSettle();
      expect(_id(ChatTestIds.list), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a build without chat says so', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatClient();
      await tester.pumpWidget(signedInApp(chat: chat, sendbirdAppId: ''));
      await _openChatTab(tester);
      expect(_id(ChatTestIds.unavailable), findsOneWidget);
      expect(chat.inits, 0);
      handle.dispose();
    });

    testWidgets('unread messages show on the tab', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatClient()..unreadNow = 4;
      await tester.pumpWidget(signedInApp(chat: chat));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      chat.unread.add(120);
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);
      chat.unread.add(0);
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      handle.dispose();
    });

    testWidgets('no archive tabs when nothing is archived', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chatUi = FakeChatUi();
      await tester.pumpWidget(signedInApp(chatUi: chatUi));
      await _openChatTab(tester);
      expect(_id(ChatTestIds.tabActive), findsNothing);
      expect(_id(ChatTestIds.tabArchived), findsNothing);
      handle.dispose();
    });

    testWidgets('switching to the archived tab queries archived channels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chatUi = FakeChatUi()..hasArchived = true;
      await tester.pumpWidget(signedInApp(chatUi: chatUi));
      await _openChatTab(tester);
      expect(_id(ChatTestIds.tabActive), findsOneWidget);
      expect(_id(ChatTestIds.tabArchived), findsOneWidget);
      expect(find.text('fake channel list'), findsOneWidget);
      expect(chatUi.lastArchived, isFalse);
      await tester.tap(_id(ChatTestIds.tabArchived));
      await tester.pumpAndSettle();
      expect(find.text('fake archived channel list'), findsOneWidget);
      expect(chatUi.lastArchived, isTrue);
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('connecting and failed states meet guidelines '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final chat = FakeChatClient()..results = [ChatConnectResult.failed];
        await tester.pumpWidget(signedInApp(chat: chat));
        await _openChatTab(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('push and support', () {
    testWidgets('a chat push opens the conversation', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform();
      await tester.pumpWidget(signedInApp(push: push));
      await tester.pumpAndSettle();
      push.openedController.add(
        const PushMessage(
          id: 'c1',
          data: {
            'sendbird': '{"channel":{"channel_url":"sendbird_group_channel_5"},"message":"hi"}',
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('fake channel sendbird_group_channel_5'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a chat push without a channel opens the chat tab', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform();
      await tester.pumpWidget(signedInApp(push: push));
      await tester.pumpAndSettle();
      push.openedController.add(
        const PushMessage(id: 'c2', data: {'sendbird': '{}'}),
      );
      await tester.pumpAndSettle();
      expect(_id(ChatTestIds.list), findsOneWidget);
      handle.dispose();
    });

    testWidgets('settings offers support chat when the user has a room', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: FakeSessionInfoRepository(
            response: const SessionInfoResponse(
              user: SessionInfoUser(
                id: 7,
                timezoneIdentifier: 'America/New_York',
                supportChatRoomUrl: 'support-room',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_id(HomeTestIds.settingsButton));
      await tester.pumpAndSettle();
      await tester.tap(_id(SettingsTestIds.support));
      await tester.pumpAndSettle();
      expect(find.text('fake channel support-room'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no support entry without a room', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      await tester.tap(_id(HomeTestIds.settingsButton));
      await tester.pumpAndSettle();
      expect(_id(SettingsTestIds.support), findsNothing);
      handle.dispose();
    });

    testWidgets('logging out signs out of chat', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final chat = FakeChatClient();
      await tester.pumpWidget(
        signedInApp(chat: chat, push: FakePushPlatform(available: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(_id(HomeTestIds.settingsButton));
      await tester.pumpAndSettle();
      await tester.tap(_id(SettingsTestIds.logout));
      await tester.pumpAndSettle();
      await tester.tap(_id(SettingsTestIds.logoutConfirm));
      await tester.pumpAndSettle();
      expect(_id(WelcomeTestIds.root), findsOneWidget);
      expect(chat.disconnects, greaterThanOrEqualTo(1));
      expect(chat.unregistered, ['device-token-1']);
      handle.dispose();
    });
  });
}
