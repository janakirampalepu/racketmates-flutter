import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

import 'fakes.dart';

/// The whole app with a restored signed-in session (user id 7) and fake
/// repositories; starts at the splash and lands on home.
Widget signedInApp({
  FakeScheduleRepository? schedule,
  FakeUserRepository? users,
  FakeEventActionsRepository? actions,
  FakeContentRepository? content,
  InMemoryContentCache? contentCache,
  FakePlacesRepository? places,
  FakeCreateEventRepository? createEvent,
  FakeTeamsRepository? teams,
  FakeDeviceIntegrity? integrity,
  FakeNativeSessionSource? nativeSession,
  FakeDowntimeRepository? downtime,
  FakeSessionInfoRepository? sessionInfo,
  String? deviceTimezone = 'America/New_York',
  InMemoryTokenStore? tokenStore,
  FakePushPlatform? push,
  FakeSettingsRepository? settings,
  InMemoryPushTokenStore? pushTokens,
  FakeChatClient? chat,
  FakeChatRepository? chatRepository,
  FakeChatUi? chatUi,
  FakeBillingPlatform? billing,
  FakeSubscriptionRepository? subscriptions,
  FakeExternalLinks? links,
  InMemoryPromptStore? promptStore,
  FakeLocationPlatform? location,
  InMemoryDistanceStore? distanceStore,
  FakeSupportRepository? support,
  FakeShareService? share,
  FakePhotoPicker? photoPicker,
  String? sendbirdAppId,
  AppEnvironment? environment,
}) => ProviderScope(
  overrides: [
    environmentConfigProvider.overrideWithValue(
      testConfigWith(sendbirdAppId: sendbirdAppId, environment: environment),
    ),
    appVersionProvider.overrideWithValue('1.0.0'),
    tokenStoreProvider.overrideWithValue(
      tokenStore ??
          InMemoryTokenStore(
            const SessionToken(
              accessToken: 'a',
              refreshToken: 'r',
              user: SessionTokenUser(id: 7, uid: 'uid-7', uuid: 'uuid-7'),
            ),
          ),
    ),
    authApiProvider.overrideWithValue(FakeAuthApi()),
    startupRepositoryProvider.overrideWithValue(FakeStartupRepository()),
    userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
    scheduleRepositoryProvider.overrideWithValue(
      schedule ?? FakeScheduleRepository(),
    ),
    eventActionsRepositoryProvider.overrideWithValue(
      actions ?? FakeEventActionsRepository(),
    ),
    hourFormatProvider.overrideWithValue(12),
    placesRepositoryProvider.overrideWithValue(
      places ?? FakePlacesRepository(),
    ),
    createEventRepositoryProvider.overrideWithValue(
      createEvent ?? FakeCreateEventRepository(),
    ),
    teamsRepositoryProvider.overrideWithValue(teams ?? FakeTeamsRepository()),
    ...contentOverrides(
      repository: content,
      cache: contentCache,
      integrity: integrity,
      nativeSession: nativeSession,
      downtime: downtime,
      push: push,
      settings: settings,
      pushTokens: pushTokens,
      chat: chat,
      chatRepository: chatRepository,
      chatUi: chatUi,
      billing: billing,
      subscriptions: subscriptions,
      links: links,
      promptStore: promptStore,
      location: location,
      distanceStore: distanceStore,
      support: support,
      share: share,
      photoPicker: photoPicker,
      sessionInfo: sessionInfo,
      deviceTimezone: deviceTimezone,
    ),
  ],
  child: const RacketmatesApp(),
);

/// Makes the test viewport tall so long lists build all their children.
void useTallScreen(WidgetTester tester, {double height = 4000}) {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The app with no persisted session: lands on the welcome screen.
Widget signedOutApp({
  FakeContentRepository? content,
  InMemoryContentCache? contentCache,
  FakeDeviceIntegrity? integrity,
  FakeNativeSessionSource? nativeSession,
  FakeDowntimeRepository? downtime,
  FakeSessionInfoRepository? sessionInfo,
  InMemoryTokenStore? tokenStore,
  FakePushPlatform? push,
  FakeSettingsRepository? settings,
  InMemoryPushTokenStore? pushTokens,
  FakeChatClient? chat,
  FakeChatRepository? chatRepository,
  FakeChatUi? chatUi,
  FakeBillingPlatform? billing,
  FakeSubscriptionRepository? subscriptions,
  FakeExternalLinks? links,
  InMemoryPromptStore? promptStore,
  FakeLocationPlatform? location,
  InMemoryDistanceStore? distanceStore,
  FakeSupportRepository? support,
  FakeShareService? share,
  FakePhotoPicker? photoPicker,
}) => ProviderScope(
  overrides: [
    environmentConfigProvider.overrideWithValue(testConfig),
    appVersionProvider.overrideWithValue('1.0.0'),
    tokenStoreProvider.overrideWithValue(tokenStore ?? InMemoryTokenStore()),
    authApiProvider.overrideWithValue(FakeAuthApi()),
    startupRepositoryProvider.overrideWithValue(FakeStartupRepository()),
    scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
    ...contentOverrides(
      repository: content,
      cache: contentCache,
      integrity: integrity,
      nativeSession: nativeSession,
      downtime: downtime,
      push: push,
      settings: settings,
      pushTokens: pushTokens,
      chat: chat,
      chatRepository: chatRepository,
      chatUi: chatUi,
      billing: billing,
      subscriptions: subscriptions,
      links: links,
      promptStore: promptStore,
      location: location,
      distanceStore: distanceStore,
      support: support,
      share: share,
      photoPicker: photoPicker,
      sessionInfo: sessionInfo,
    ),
  ],
  child: const RacketmatesApp(),
);
