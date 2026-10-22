import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/notifications/push_registrar.dart';
import 'package:racketmates/common/security/device_integrity.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:racketmates/common/settings/settings_repository.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/session/session_info_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/content_repository.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/create_event/create_event_api.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

const testConfig = EnvironmentConfig(
  environment: AppEnvironment.qa,
  apiBaseUrl: 'https://api-qa.example.test',
  apiVersion: 'application/vnd.test',
  oauthClientId: 'client-id',
  oauthClientSecret: 'client-secret',
);

SessionToken token({
  String access = 'access-1',
  String refresh = 'refresh-1',
  int createdAt = 1000,
  int expiresIn = 7200,
}) => SessionToken(
  accessToken: access,
  tokenType: 'Bearer',
  expiresIn: expiresIn,
  refreshToken: refresh,
  createdAt: createdAt,
);

DioException httpError(int status) => DioException(
  requestOptions: RequestOptions(),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(),
    statusCode: status,
  ),
);

DioException connectionError() => DioException(
  requestOptions: RequestOptions(),
  type: DioExceptionType.connectionError,
);

/// Scripted [AuthApi]: each `token` call pops the next result (a
/// [SessionToken] or a thrown [DioException]).
class FakeAuthApi implements AuthApi {
  FakeAuthApi({List<Object> tokenResults = const [], this.metadataResult})
    : tokenResults = List.of(tokenResults);

  final List<Object> tokenResults;
  final AppMetadata? metadataResult;
  final List<Map<String, dynamic>> tokenBodies = [];
  final List<Map<String, dynamic>> revokeBodies = [];
  int get tokenCalls => tokenBodies.length;

  @override
  Future<SessionToken> token(Map<String, dynamic> body) async {
    tokenBodies.add(body);
    await Future<void>.delayed(Duration.zero);
    final next = tokenResults.removeAt(0);
    if (next is DioException) throw next;
    return next as SessionToken;
  }

  @override
  Future<void> revokeToken(Map<String, dynamic> body) async =>
      revokeBodies.add(body);

  @override
  Future<AppMetadata> metadata(
    String clientId,
    String clientSecret,
    String appType,
    String appVersion,
  ) async {
    final result = metadataResult;
    if (result == null) throw connectionError();
    return result;
  }
}

class FakeStartupRepository implements StartupRepository {
  FakeStartupRepository({this.metadata, this.prompted});

  final AppMetadata? metadata;
  String? prompted;

  @override
  Future<AppMetadata?> fetchMetadata() async => metadata;

  @override
  Future<String?> lastPromptedVersion() async => prompted;

  @override
  Future<void> setLastPromptedVersion(String version) async =>
      prompted = version;
}

class FakePhoneVerificationRepository implements PhoneVerificationRepository {
  FakePhoneVerificationRepository({
    this.status = const MobileNumberStatus(userExist: true, isSignedUp: true),
    this.verifyResult = const SmsCodePayload(
      valid: true,
      playerExist: true,
      isSignedUp: true,
      verificationCode: 'vcode',
    ),
    this.failure,
  });

  MobileNumberStatus status;
  SmsCodePayload verifyResult;
  AppFailure? failure;
  final List<PhoneNumberParts> validated = [];
  final List<PhoneNumberParts> sent = [];
  final List<String> verifiedCodes = [];
  final List<String> signInCodes = [];

  @override
  Future<MobileNumberStatus> validateMobileNumber(
    PhoneNumberParts phone,
  ) async {
    validated.add(phone);
    if (failure != null) throw failure!;
    return status;
  }

  @override
  Future<void> sendSmsCode(PhoneNumberParts phone) async {
    sent.add(phone);
    if (failure != null) throw failure!;
  }

  @override
  Future<SmsCodePayload> verifySmsCode(
    PhoneNumberParts phone,
    String code,
  ) async {
    verifiedCodes.add(code);
    if (failure != null) throw failure!;
    return verifyResult;
  }

  @override
  Future<SessionToken> signIn(
    PhoneNumberParts phone,
    String verificationCode,
  ) async {
    signInCodes.add(verificationCode);
    return SessionToken(
      accessToken: 'signed-in',
      refreshToken: 'refresh-signed-in',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      expiresIn: 7200,
      user: const SessionTokenUser(id: 7),
    );
  }
}

class FakeUserRepository implements UserRepository {
  FakeUserRepository({
    this.emailTaken = false,
    this.profile = const UserDetails(
      user: AppUser(id: 7, firstName: 'Sam', lastName: 'Lee'),
    ),
    this.failure,
  });

  bool emailTaken;
  UserDetails profile;
  AppFailure? failure;
  final List<({String email, String displayName, int? userId})>
  duplicateChecks = [];
  final List<FormData> created = [];
  final List<(int, FormData)> updated = [];
  final List<(int, String)> avatars = [];

  @override
  Future<UserDetails> fetchUser(int id) async {
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<bool> isEmailTaken({
    required String email,
    required String displayName,
    int? userId,
  }) async {
    duplicateChecks.add((
      email: email,
      displayName: displayName,
      userId: userId,
    ));
    if (failure != null) throw failure!;
    return emailTaken;
  }

  @override
  Future<UserDetails> createAccount(FormData form) async {
    created.add(form);
    if (failure != null) throw failure!;
    return const UserDetails(
      user: AppUser(id: 7, firstName: 'Sam', mobileNumber: '5551234567'),
    );
  }

  @override
  Future<UserDetails> updateUser(int id, FormData form) async {
    updated.add((id, form));
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<UserDetails> uploadAvatar(int id, String filePath) async {
    avatars.add((id, filePath));
    if (failure != null) throw failure!;
    return profile;
  }
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.path]);

  String? path;
  final List<PhotoSource> requests = [];

  @override
  Future<String?> pick(PhotoSource source) async {
    requests.add(source);
    return path;
  }
}

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository({
    this.upcoming = const [],
    this.past = const [],
    this.pending = const [],
    this.activity = const [],
    this.updates = const [],
    this.event,
    Map<ScheduleTab, List<List<ScheduleItem>>>? pages,
  }) : pages = pages ?? {};

  List<ScheduleItem> upcoming;
  List<ScheduleItem> past;
  List<PendingAction> pending;
  List<HomePageStats> activity;
  List<PlayerCard> updates;
  EventDetails? event;

  /// Pages served by `schedulePage` per tab (index = page - 1); missing = empty.
  final Map<ScheduleTab, List<List<ScheduleItem>>> pages;

  /// Sections / calls that fail with this failure.
  final Set<String> failing = {};
  AppFailure failure = const OfflineFailure();
  final List<String> calls = [];
  final List<int> requestedPages = [];

  Future<T> _run<T>(String name, T Function() value) async {
    calls.add(name);
    await Future<void>.delayed(Duration.zero);
    if (failing.contains(name)) throw failure;
    return value();
  }

  @override
  Future<List<ScheduleItem>> homeUpcoming({
    required List<String> userIds,
    required int hourFormat,
  }) => _run('upcoming', () => upcoming);

  @override
  Future<List<ScheduleItem>> homePast({
    required List<String> userIds,
    required int hourFormat,
  }) => _run('past', () => past);

  @override
  Future<ScheduleListResponse> schedulePage({
    required ScheduleTab tab,
    required int page,
    required List<String> userIds,
    required int hourFormat,
  }) {
    requestedPages.add(page);
    return _run('page-${tab.name}', () {
      final list = pages[tab] ?? const [];
      return ScheduleListResponse(
        scheduleItems: page - 1 < list.length ? list[page - 1] : const [],
      );
    });
  }

  @override
  Future<List<PendingAction>> pendingActions({required List<String> userIds}) =>
      _run('pending', () => pending);

  @override
  Future<List<HomePageStats>> activitySummary({
    required List<String> userIds,
  }) => _run('activity', () => activity);

  @override
  Future<List<PlayerCard>> latestUpdates({required List<String> userIds}) =>
      _run('updates', () => updates);

  @override
  Future<EventDetails> eventDetails(int id, {required int hourFormat}) =>
      _run('event-$id', () => event ?? (throw const ParseFailure()));
}

ScheduleItem scheduleItem(
  int id, {
  String date = '2026-11-03',
  String type = 'et_game',
}) => ScheduleItem(
  eventId: id,
  eventDate: date,
  eventType: type,
  eventStatusLabel: 'Scheduled',
  timeSlot: '6:00 PM - 7:30 PM',
  placeName: 'Central Courts',
);

class FakeEventActionsRepository implements EventActionsRepository {
  FakeEventActionsRepository({this.response, this.failure});

  /// Returned by every RSVP call.
  EventDetailsResponse? response;
  AppFailure? failure;
  final List<String> calls = [];
  final List<List<int>> optionIds = [];
  String? cancelReason;
  bool? cancelRemove;

  /// Organizer calls, in order: `name` with the body or ids sent.
  final List<({String name, Object? data})> manageCalls = [];

  Future<void> _manage(String name, Object? data) async {
    manageCalls.add((name: name, data: data));
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
  }

  @override
  Future<void> updateSettings(int eventId, Map<String, dynamic> body) =>
      _manage('updateSettings:$eventId', body);

  @override
  Future<void> reschedule(int eventId, Map<String, dynamic> body) =>
      _manage('reschedule:$eventId', body);

  @override
  Future<void> updateScores(
    int eventId,
    int matchId,
    Map<String, dynamic> body,
  ) => _manage('updateScores:$eventId:$matchId', body);

  @override
  Future<void> clearUnfinished(int eventId, int matchId) =>
      _manage('clearUnfinished:$eventId:$matchId', null);

  @override
  Future<void> pickPlayers(int eventId, List<int> userIds) =>
      _manage('pickPlayers:$eventId', userIds);

  @override
  Future<void> removeParticipants(int eventId, List<int> userIds) =>
      _manage('removeParticipants:$eventId', userIds);

  @override
  Future<void> addParticipants(int eventId, List<int> userIds, String role) =>
      _manage('addParticipants:$eventId:$role', userIds);

  Future<EventDetailsResponse> _rsvp(String name) async {
    calls.add(name);
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
    return response ?? const EventDetailsResponse();
  }

  @override
  Future<EventDetailsResponse> accept(
    int eventId,
    int participantId, {
    List<int> scheduleOptionIds = const [],
  }) {
    optionIds.add(scheduleOptionIds);
    return _rsvp('accept:$eventId:$participantId');
  }

  @override
  Future<EventDetailsResponse> decline(int eventId, int participantId) =>
      _rsvp('decline:$eventId:$participantId');

  @override
  Future<EventDetailsResponse> rejoin(
    int eventId,
    int participantId, {
    required List<int> scheduleOptionIds,
  }) {
    optionIds.add(scheduleOptionIds);
    return _rsvp('rejoin:$eventId:$participantId');
  }

  @override
  Future<EventDetailsResponse> leave(int eventId, int participantId) =>
      _rsvp('leave:$eventId:$participantId');

  @override
  Future<EventDetailsResponse> joinWaitlist(int eventId, int participantId) =>
      _rsvp('waitlist:$eventId:$participantId');

  @override
  Future<void> cancelEvent(
    int eventId, {
    String? reason,
    bool removeEvent = false,
  }) async {
    calls.add('cancel:$eventId');
    cancelReason = reason;
    cancelRemove = removeEvent;
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
  }
}

class FakeContentRepository implements ContentRepository {
  FakeContentRepository({
    this.messagesTree = const {},
    this.preLoginTree = const {},
    this.reference = const [],
    this.failing = false,
  });

  Map<String, dynamic> messagesTree;
  Map<String, dynamic> preLoginTree;
  List<Map<String, dynamic>> reference;
  bool failing;
  int messagesCalls = 0;
  int preLoginCalls = 0;
  int referenceCalls = 0;

  @override
  Future<Map<String, dynamic>> messages() async {
    messagesCalls++;
    if (failing) throw const OfflineFailure();
    return messagesTree;
  }

  @override
  Future<Map<String, dynamic>> preLoginMessages() async {
    preLoginCalls++;
    if (failing) throw const OfflineFailure();
    return preLoginTree;
  }

  @override
  Future<ReferenceDataResponse> referenceData() async {
    referenceCalls++;
    if (failing) throw const OfflineFailure();
    return ReferenceDataResponse.fromJson({'reference_data': reference});
  }
}

class FakeDeviceIntegrity implements DeviceIntegrity {
  FakeDeviceIntegrity({this.compromised = false});

  bool compromised;
  final List<bool> checks = [];

  @override
  Future<bool> isCompromised({required bool allowSimulator}) async {
    checks.add(allowSimulator);
    return compromised;
  }
}

class FakeNativeSessionSource implements NativeSessionSource {
  FakeNativeSessionSource([this.raw]);

  String? raw;
  int reads = 0;
  int clears = 0;

  @override
  Future<String?> read() async {
    reads++;
    return raw;
  }

  @override
  Future<void> clear() async {
    clears++;
    raw = null;
  }
}

class FakeDowntimeRepository implements DowntimeRepository {
  FakeDowntimeRepository([this.incident]);

  Incident? incident;
  int checks = 0;

  @override
  Future<Incident?> currentIncident() async {
    checks++;
    return incident;
  }
}

class FakePushPlatform implements PushPlatform {
  FakePushPlatform({
    this.available = false,
    this.permissionState = PushPermission.granted,
    this.currentToken = 'device-token-1',
    this.launch,
  });

  bool available;
  PushPermission permissionState;
  String? currentToken;
  PushMessage? launch;
  int initializations = 0;
  int permissionRequests = 0;
  int settingsOpened = 0;

  /// What the next `requestPermission` answers.
  PushPermission answerToRequest = PushPermission.granted;

  final tokenController = StreamController<String>.broadcast();
  final foregroundController = StreamController<PushMessage>.broadcast();
  final openedController = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> initialize() async {
    initializations++;
    return available;
  }

  @override
  Future<PushPermission> permission() async => permissionState;

  @override
  Future<PushPermission> requestPermission() async {
    permissionRequests++;
    permissionState = answerToRequest;
    return permissionState;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Future<PushMessage?> launchMessage() async {
    final message = launch;
    launch = null;
    return message;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Stream<String> get tokens => tokenController.stream;

  @override
  Stream<PushMessage> get foregroundMessages => foregroundController.stream;

  @override
  Stream<PushMessage> get openedMessages => openedController.stream;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({List<ReminderPreference>? reminders})
    : stored = List.of(reminders ?? const []);

  List<ReminderPreference> stored;
  AppFailure? failure;
  bool loadFails = false;
  int nextId = 100;
  final List<String> calls = [];
  final List<({String token, TargetPlatform platform, String language})>
  registrations = [];
  final List<String> revoked = [];
  final List<bool> textConsents = [];

  Future<void> _run(String call) async {
    calls.add(call);
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
  }

  @override
  Future<List<ReminderPreference>> reminders(int userId) async {
    calls.add('reminders:$userId');
    await Future<void>.delayed(Duration.zero);
    if (loadFails) throw const OfflineFailure();
    return List.of(stored);
  }

  @override
  Future<void> addReminder(
    int userId, {
    required int value,
    required String unit,
  }) async {
    await _run('add:$userId:$value:$unit');
    stored.add(
      ReminderPreference(
        id: nextId++,
        reminderUnit: value,
        reminderUnitType: unit,
      ),
    );
  }

  @override
  Future<void> removeReminder(int userId, int reminderId) async {
    await _run('remove:$userId:$reminderId');
    stored.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<void> setTextConsent({required bool consent}) async {
    await _run('consent:$consent');
    textConsents.add(consent);
  }

  @override
  Future<void> registerDeviceToken(
    String token, {
    required TargetPlatform platform,
    required String language,
  }) async {
    await _run('register:$token');
    registrations.add((token: token, platform: platform, language: language));
  }

  @override
  Future<void> revokeDeviceToken(String token) async {
    await _run('revoke:$token');
    revoked.add(token);
  }
}

class InMemoryPushTokenStore implements PushTokenStore {
  ({String token, int userId})? value;

  @override
  Future<({String token, int userId})?> read() async => value;

  @override
  Future<void> write(String token, int userId) async =>
      value = (token: token, userId: userId);

  @override
  Future<void> clear() async => value = null;
}

class FakeSessionInfoRepository implements SessionInfoRepository {
  FakeSessionInfoRepository({
    this.response = const SessionInfoResponse(
      user: SessionInfoUser(
        id: 7,
        hasFullFeatureAccess: true,
        timezoneIdentifier: 'America/New_York',
      ),
    ),
  });

  SessionInfoResponse response;
  AppFailure? fetchFailure;
  AppFailure? updateFailure;
  int fetches = 0;
  final List<String> timezoneUpdates = [];

  @override
  Future<SessionInfoResponse> fetch() async {
    fetches++;
    await Future<void>.delayed(Duration.zero);
    if (fetchFailure != null) throw fetchFailure!;
    return response;
  }

  @override
  Future<void> updateTimeZone(String identifier) async {
    timezoneUpdates.add(identifier);
    await Future<void>.delayed(Duration.zero);
    if (updateFailure != null) throw updateFailure!;
  }
}

/// Provider overrides that keep content (strings / reference data) and the
/// startup checks (device integrity, native session, downtime) offline and
/// deterministic in widget tests: an unmocked platform channel never answers
/// in a widget test, so the real ones would hang startup.
List<Override> contentOverrides({
  FakeContentRepository? repository,
  InMemoryContentCache? cache,
  FakeDeviceIntegrity? integrity,
  FakeNativeSessionSource? nativeSession,
  FakeDowntimeRepository? downtime,
  FakeSessionInfoRepository? sessionInfo,
  String? deviceTimezone = 'America/New_York',
  FakePushPlatform? push,
  FakeSettingsRepository? settings,
  InMemoryPushTokenStore? pushTokens,
}) => [
  contentRepositoryProvider.overrideWithValue(
    repository ?? FakeContentRepository(),
  ),
  contentCacheProvider.overrideWithValue(cache ?? InMemoryContentCache()),
  deviceIntegrityProvider.overrideWithValue(integrity ?? FakeDeviceIntegrity()),
  nativeSessionSourceProvider.overrideWithValue(
    nativeSession ?? FakeNativeSessionSource(),
  ),
  downtimeRepositoryProvider.overrideWithValue(
    downtime ?? FakeDowntimeRepository(),
  ),
  sessionInfoRepositoryProvider.overrideWithValue(
    sessionInfo ?? FakeSessionInfoRepository(),
  ),
  deviceTimezoneOrNullProvider.overrideWith((ref) async => deviceTimezone),
  pushPlatformProvider.overrideWithValue(push ?? FakePushPlatform()),
  settingsRepositoryProvider.overrideWithValue(
    settings ?? FakeSettingsRepository(),
  ),
  pushTokenStoreProvider.overrideWithValue(
    pushTokens ?? InMemoryPushTokenStore(),
  ),
];

class FakePlacesRepository implements PlacesRepository {
  FakePlacesRepository({
    this.places = const [],
    this.favouritePlaces = const [],
    this.detailsById = const {},
  });

  List<PlaceItem> places;
  List<PlaceItem> favouritePlaces;
  Map<int, PlaceItem> detailsById;
  bool failing = false;
  final List<({String query, String? sport})> searches = [];
  final List<(int, bool)> favouriteCalls = [];
  final List<int> detailsCalls = [];

  @override
  Future<List<PlaceItem>> search({String query = '', String? sportType}) async {
    searches.add((query: query, sport: sportType));
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return [
      for (final p in places)
        if (query.isEmpty ||
            (p.name ?? '').toLowerCase().contains(query.toLowerCase()))
          p,
    ];
  }

  @override
  Future<List<PlaceItem>> favourites() async {
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return favouritePlaces;
  }

  @override
  Future<PlaceItem> details(int id) async {
    detailsCalls.add(id);
    await Future<void>.delayed(Duration.zero);
    final d = detailsById[id];
    if (failing || d == null) throw const OfflineFailure();
    return d;
  }

  @override
  Future<void> setFavourite(int id, {required bool favourite}) async {
    favouriteCalls.add((id, favourite));
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    favouritePlaces = favourite
        ? [
            ...favouritePlaces,
            places.firstWhere((p) => p.id == id).copyWith(favourite: true),
          ]
        : [
            for (final p in favouritePlaces)
              if (p.id != id) p,
          ];
  }
}

class FakeTeamsRepository implements TeamsRepository {
  FakeTeamsRepository({
    this.teams = const [],
    this.captain = const [],
    this.membersByTeam = const {},
  });

  List<Team> teams;
  List<Team> captain;
  Map<int, List<TeamPlayer>> membersByTeam;

  /// Teams a team can play against.
  List<Team> opponents = const [];
  bool failing = false;
  bool membersFail = false;
  AppFailure? createFailure;
  Map<String, dynamic>? created;
  int createdId = 900;
  final List<List<String>> myTeamsRequests = [];
  final List<({String? sport, List<String> userIds})> captainRequests = [];
  final List<({int exclude, String? sport, String query})> opponentRequests =
      [];
  final List<({int team, String query, String? role, String? sport})>
  memberSearches = [];

  @override
  Future<List<Team>> myTeams({required List<String> userIds}) async {
    myTeamsRequests.add(userIds);
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return teams;
  }

  @override
  Future<List<Team>> captainTeams({
    required List<String> userIds,
    String? sportKey,
    String query = '',
  }) async {
    captainRequests.add((sport: sportKey, userIds: userIds));
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return captain;
  }

  @override
  Future<List<Team>> opponentTeams({
    required int excludeTeamId,
    String? sportKey,
    String query = '',
  }) async {
    opponentRequests.add((
      exclude: excludeTeamId,
      sport: sportKey,
      query: query,
    ));
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return [
      for (final t in opponents)
        if (t.id != excludeTeamId &&
            (query.isEmpty ||
                (t.name ?? '').toLowerCase().contains(query.toLowerCase())))
          t,
    ];
  }

  @override
  Future<Team> details(int id) async {
    await Future<void>.delayed(Duration.zero);
    if (failing) throw const OfflineFailure();
    return [...teams, ...captain].firstWhere((t) => t.id == id);
  }

  @override
  Future<List<TeamPlayer>> members(
    int teamId, {
    String query = '',
    String? role,
    String? sportKey,
  }) async {
    memberSearches.add((
      team: teamId,
      query: query,
      role: role,
      sport: sportKey,
    ));
    await Future<void>.delayed(Duration.zero);
    if (membersFail) throw const OfflineFailure();
    return [
      for (final m in membersByTeam[teamId] ?? const <TeamPlayer>[])
        if ((query.isEmpty ||
                (m.user?.displayName ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                )) &&
            (role == null ||
                (role == 'ur_player' && (m.isPlayer ?? false)) ||
                (role == 'ur_coach' && (m.isCoach ?? false))))
          m,
    ];
  }

  @override
  Future<Team> create(Map<String, dynamic> body) async {
    await Future<void>.delayed(Duration.zero);
    if (createFailure != null) throw createFailure!;
    created = body;
    return Team(id: createdId);
  }
}

class FakeCreateEventRepository implements CreateEventRepository {
  FakeCreateEventRepository({
    this.players = const [],
    this.createdId = 321,
    this.scoring = const ScoringFormatsResponse(
      scoringFormatKeys: [
        'sf_best_of_3_sets',
        'sf_single_set',
        'sf_time_based',
      ],
      minimumScores: {'sf_best_of_3_sets': 2, 'sf_single_set': 6},
    ),
  });

  ScoringFormatsResponse scoring;
  bool scoringFails = false;
  final List<({String sport, String eventType})> scoringRequests = [];

  List<AppUser> players;
  int? createdId;
  AppFailure? createFailure;
  bool searchFails = false;
  int? timezone = 99;
  Map<String, dynamic>? body;
  final List<({String query, String? role, String? sport})> searches = [];

  @override
  Future<EventDetailsResponse> create(Map<String, dynamic> b) async {
    await Future<void>.delayed(Duration.zero);
    if (createFailure != null) throw createFailure!;
    body = b;
    return EventDetailsResponse(event: EventDetails(id: createdId));
  }

  @override
  Future<List<AppUser>> searchUsers({
    required String query,
    String? role,
    String? sportKey,
    List<String>? sportKeys,
  }) async {
    searches.add((query: query, role: role, sport: sportKey));
    await Future<void>.delayed(Duration.zero);
    if (searchFails) throw const OfflineFailure();
    return [
      for (final p in players)
        if (query.isEmpty ||
            p.displayName.toLowerCase().contains(query.toLowerCase()))
          p,
    ];
  }

  @override
  Future<ScoringFormatsResponse> scoringFormats({
    required String sportKey,
    required String eventType,
  }) async {
    scoringRequests.add((sport: sportKey, eventType: eventType));
    await Future<void>.delayed(Duration.zero);
    if (scoringFails) throw const OfflineFailure();
    return scoring;
  }

  @override
  Future<int?> timezoneInfoId({
    required double latitude,
    required double longitude,
    required String time,
  }) async => timezone;
}
