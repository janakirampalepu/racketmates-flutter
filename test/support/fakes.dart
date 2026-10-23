import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
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
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/billing_platform.dart';
import 'package:racketmates/common/billing/subscription_prompt.dart';
import 'package:racketmates/common/billing/subscription_repository.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/share/share_service.dart';
import 'package:racketmates/common/support/support_repository.dart';
import 'package:racketmates/common/location/location_platform.dart';
import 'package:racketmates/common/location/user_location.dart';
import 'package:racketmates/common/chat/chat_client.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
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
  sendbirdAppId: 'sendbird-test-app',
);

/// [testConfig] with another Sendbird application id.
EnvironmentConfig testConfigWith({
  String? sendbirdAppId,
  AppEnvironment? environment,
}) => EnvironmentConfig(
  environment: environment ?? testConfig.environment,
  apiBaseUrl: testConfig.apiBaseUrl,
  apiVersion: testConfig.apiVersion,
  oauthClientId: testConfig.oauthClientId,
  oauthClientSecret: testConfig.oauthClientSecret,
  sendbirdAppId: sendbirdAppId ?? testConfig.sendbirdAppId,
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

  final List<(int, Map<String, dynamic>)> profileUpdates = [];
  final List<int> removedAvatars = [];

  AppUser _with(AppUser u, {String? first, String? last, String? email}) =>
      AppUser(
        id: u.id,
        uid: u.uid,
        uuid: u.uuid,
        firstName: first ?? u.firstName,
        lastName: last ?? u.lastName,
        mobileNumber: u.mobileNumber,
        email: email ?? u.email,
        roles: u.roles,
        userRoles: u.userRoles,
        country: u.country,
        // No photo once removed: tests set avatarFileAttachmentUrl up front.
        avatarFileAttachmentUrl: u.avatarFileAttachmentUrl,
        thumbnailAttachmentUrl: u.thumbnailAttachmentUrl,
      );

  @override
  Future<UserDetails> updateProfile(int id, Map<String, dynamic> body) async {
    profileUpdates.add((id, body));
    if (failure != null) throw failure!;
    final user = body['user'] as Map<String, dynamic>;
    profile = UserDetails(
      user: _with(
        profile.user!,
        first: user['first_name'] as String?,
        last: user['last_name'] as String?,
        email: user['email'] as String?,
      ),
    );
    return profile;
  }

  /// Calls: `role:<id>:<roleId>`, `addRole:<id>`, `kid:create`, `delete:<id>`,
  /// `phone:<id>`; bodies are kept in [roleBodies], [kidForms], [phoneBodies].
  final List<String> userCalls = [];
  final List<Map<String, dynamic>> roleBodies = [];
  final List<FormData> kidForms = [];
  final List<Map<String, dynamic>> phoneBodies = [];

  /// Replaces the profile's user (tests set kids and roles through this).
  void setUser(AppUser user) => profile = UserDetails(user: user);

  @override
  Future<UserDetails> updateRole(
    int id,
    int roleId,
    Map<String, dynamic> body,
  ) async {
    userCalls.add('role:$id:$roleId');
    roleBodies.add(body);
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<UserDetails> addRole(int id, Map<String, dynamic> body) async {
    userCalls.add('addRole:$id');
    roleBodies.add(body);
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<UserDetails> createKid(FormData form) async {
    userCalls.add('kid:create');
    kidForms.add(form);
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<void> deleteUser(int id) async {
    userCalls.add('delete:$id');
    if (failure != null) throw failure!;
    final u = profile.user!;
    profile = UserDetails(
      user: AppUser(
        id: u.id,
        uid: u.uid,
        firstName: u.firstName,
        lastName: u.lastName,
        mobileNumber: u.mobileNumber,
        email: u.email,
        roles: u.roles,
        userRoles: u.userRoles,
        country: u.country,
        children: [
          for (final c in u.children ?? const <AppUser>[])
            if (c.id != id) c,
        ],
      ),
    );
  }

  @override
  Future<UserDetails> changeMobileNumber(
    int id,
    Map<String, dynamic> body,
  ) async {
    userCalls.add('phone:$id');
    phoneBodies.add(body);
    if (failure != null) throw failure!;
    final u = profile.user!;
    profile = UserDetails(
      user: AppUser(
        id: u.id,
        uid: u.uid,
        firstName: u.firstName,
        lastName: u.lastName,
        mobileNumber: body['mobile_number'] as String?,
        email: u.email,
        country: u.country,
      ),
    );
    return profile;
  }

  @override
  Future<void> removeAvatar(int id) async {
    removedAvatars.add(id);
    if (failure != null) throw failure!;
    final u = profile.user!;
    profile = UserDetails(
      user: AppUser(
        id: u.id,
        uid: u.uid,
        firstName: u.firstName,
        lastName: u.lastName,
        mobileNumber: u.mobileNumber,
        email: u.email,
      ),
    );
  }
}

class FakeSupportRepository implements SupportRepository {
  AppFailure? failure;
  final List<
    ({String email, String subject, String feedback, String? mobileNumber})
  >
  sent = [];

  @override
  Future<void> sendFeedback({
    required String email,
    required String subject,
    required String feedback,
    String? mobileNumber,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
    sent.add((
      email: email,
      subject: subject,
      feedback: feedback,
      mobileNumber: mobileNumber,
    ));
  }
}

class FakeShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async => shared.add(text);
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
  final List<int?> requestedTeams = [];

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
    int? teamId,
  }) {
    requestedPages.add(page);
    requestedTeams.add(teamId);
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
  FakePhoneVerificationRepository? phone,
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
  chatClientProvider.overrideWithValue(chat ?? FakeChatClient()),
  chatRepositoryProvider.overrideWithValue(
    chatRepository ?? FakeChatRepository(),
  ),
  chatUiProvider.overrideWithValue(chatUi ?? FakeChatUi()),
  billingPlatformProvider.overrideWithValue(billing ?? FakeBillingPlatform()),
  subscriptionRepositoryProvider.overrideWithValue(
    subscriptions ?? FakeSubscriptionRepository(),
  ),
  externalLinksProvider.overrideWithValue(links ?? FakeExternalLinks()),
  subscriptionPromptStoreProvider.overrideWithValue(
    promptStore ?? InMemoryPromptStore(),
  ),
  locationPlatformProvider.overrideWithValue(
    location ?? FakeLocationPlatform(),
  ),
  distanceFilterStoreProvider.overrideWithValue(
    distanceStore ?? InMemoryDistanceStore(),
  ),
  supportRepositoryProvider.overrideWithValue(
    support ?? FakeSupportRepository(),
  ),
  shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
  if (photoPicker != null) photoPickerProvider.overrideWithValue(photoPicker),
  if (phone != null)
    phoneVerificationRepositoryProvider.overrideWithValue(phone),
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
  final List<({double? latitude, double? longitude, int? distance})> locations =
      [];
  final List<(int, bool)> favouriteCalls = [];
  final List<int> detailsCalls = [];

  @override
  Future<List<PlaceItem>> search({
    String query = '',
    String? sportType,
    double? latitude,
    double? longitude,
    int? distance,
  }) async {
    searches.add((query: query, sport: sportType));
    locations.add((
      latitude: latitude,
      longitude: longitude,
      distance: distance,
    ));
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
    bool includeInactive = false,
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
        if ((includeInactive || !m.isInactive) &&
            (query.isEmpty ||
                (m.user?.displayName ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                )) &&
            (role == null ||
                (role == 'ur_player' && (m.isPlayer ?? false)) ||
                (role == 'ur_coach' && (m.isCoach ?? false))))
          m,
    ];
  }

  /// What the ranking answers, by (sport, period, match type) in the calls.
  List<TeamPlayer> ranking = const [];
  bool rankingFails = false;
  final List<({int team, String sport, String? period, String? matchType})>
  rankingRequests = [];

  /// Calls that change members: `roles:<team>:<player>:<c><o><p>`,
  /// `inactivate:`, `reactivate:`, `remove:`, `add:<team>:<ids>`.
  final List<String> memberCalls = [];
  AppFailure? changeFailure;

  /// People the add-members search finds.
  List<AppUser> candidates = const [];
  final List<({int team, String query, List<String> sports})>
  candidateSearches = [];

  @override
  Future<List<TeamPlayer>> rankings(
    int teamId, {
    required String sportKey,
    String? period,
    String? matchType,
  }) async {
    rankingRequests.add((
      team: teamId,
      sport: sportKey,
      period: period,
      matchType: matchType,
    ));
    await Future<void>.delayed(Duration.zero);
    if (rankingFails) throw const OfflineFailure();
    return ranking;
  }

  Future<void> _change(String call, void Function() apply) async {
    memberCalls.add(call);
    await Future<void>.delayed(Duration.zero);
    if (changeFailure != null) throw changeFailure!;
    apply();
  }

  void _replace(int teamId, int playerId, TeamPlayer Function(TeamPlayer) f) {
    membersByTeam = {
      ...membersByTeam,
      teamId: [
        for (final m in membersByTeam[teamId] ?? const <TeamPlayer>[])
          if (m.id == playerId) f(m) else m,
      ],
    };
  }

  TeamPlayer _copy(
    TeamPlayer m, {
    bool? captain,
    bool? coach,
    bool? player,
    String? inactivatedAt,
    bool clearInactive = false,
  }) => TeamPlayer(
    id: m.id,
    userId: m.userId,
    status: m.status,
    isCaptain: captain ?? m.isCaptain,
    isCoach: coach ?? m.isCoach,
    isPlayer: player ?? m.isPlayer,
    user: m.user,
    inactivatedAt: clearInactive ? null : (inactivatedAt ?? m.inactivatedAt),
  );

  @override
  Future<void> setMemberActive(
    int teamId,
    int teamPlayerId, {
    required bool active,
  }) => _change(
    '${active ? 'reactivate' : 'inactivate'}:$teamId:$teamPlayerId',
    () => _replace(
      teamId,
      teamPlayerId,
      (m) => active
          ? _copy(m, clearInactive: true)
          : _copy(m, inactivatedAt: '2026-01-01'),
    ),
  );

  @override
  Future<void> updateMemberRoles(
    int teamId,
    int teamPlayerId, {
    required bool captain,
    required bool coach,
    required bool player,
  }) => _change(
    'roles:$teamId:$teamPlayerId:${captain ? 'c' : '-'}${coach ? 'o' : '-'}${player ? 'p' : '-'}',
    () => _replace(
      teamId,
      teamPlayerId,
      (m) => _copy(m, captain: captain, coach: coach, player: player),
    ),
  );

  @override
  Future<void> removeMember(int teamId, int teamPlayerId) => _change(
    'remove:$teamId:$teamPlayerId',
    () => membersByTeam = {
      ...membersByTeam,
      teamId: [
        for (final m in membersByTeam[teamId] ?? const <TeamPlayer>[])
          if (m.id != teamPlayerId) m,
      ],
    },
  );

  @override
  Future<void> addMembers(
    int teamId,
    List<Map<String, dynamic>> members,
  ) => _change(
    'add:$teamId:${members.map((m) => '${m['user_id']}${m['is_captain'] == true ? 'c' : ''}${m['is_player'] == true ? 'p' : ''}${m['is_coach'] == true ? 'o' : ''}').join(',')}',
    () {},
  );

  @override
  Future<List<AppUser>> searchNonMembers(
    int teamId, {
    String query = '',
    List<String> sportKeys = const [],
  }) async {
    candidateSearches.add((team: teamId, query: query, sports: sportKeys));
    await Future<void>.delayed(Duration.zero);
    if (membersFail) throw const OfflineFailure();
    return [
      for (final u in candidates)
        if (query.isEmpty ||
            u.displayName.toLowerCase().contains(query.toLowerCase()))
          u,
    ];
  }

  /// Team calls: `update:<id>`, `archive:<id>`, `unarchive:<id>`,
  /// `delete:<id>`, with the body of the last update in [updatedBody].
  final List<String> teamCalls = [];
  Map<String, dynamic>? updatedBody;
  AppFailure? teamChangeFailure;

  Future<void> _teamChange(String call, void Function() apply) async {
    teamCalls.add(call);
    await Future<void>.delayed(Duration.zero);
    if (teamChangeFailure != null) throw teamChangeFailure!;
    apply();
  }

  void _setTeam(int id, Team Function(Team) f) {
    teams = [
      for (final t in teams)
        if (t.id == id) f(t) else t,
    ];
  }

  Team _archived(Team t, {required bool archived}) => Team(
    id: t.id,
    name: t.name,
    teamType: t.teamType,
    archived: archived,
    enablePlayerRanking: t.enablePlayerRanking,
    teamSports: t.teamSports,
    userPermissions: t.userPermissions,
  );

  @override
  Future<void> updateTeam(int teamId, Map<String, dynamic> body) =>
      _teamChange('update:$teamId', () {
        updatedBody = body;
        final team = (body['team'] as Map)['name'] as String;
        _setTeam(
          teamId,
          (t) => Team(
            id: t.id,
            name: team,
            teamType: (body['team'] as Map)['team_type'] as String?,
            archived: t.archived,
            enablePlayerRanking:
                (body['team'] as Map)['enable_player_ranking'] as bool?,
            teamSports: t.teamSports,
            userPermissions: t.userPermissions,
          ),
        );
      });

  @override
  Future<void> archive(int teamId) => _teamChange(
    'archive:$teamId',
    () => _setTeam(teamId, (t) => _archived(t, archived: true)),
  );

  @override
  Future<void> unarchive(int teamId) => _teamChange(
    'unarchive:$teamId',
    () => _setTeam(teamId, (t) => _archived(t, archived: false)),
  );

  @override
  Future<void> deleteTeam(int teamId) => _teamChange(
    'delete:$teamId',
    () => teams = [
      for (final t in teams)
        if (t.id != teamId) t,
    ],
  );

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

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.tokens = const ['sb-token-1']});

  /// Tokens handed out in turn (the last one repeats).
  List<String> tokens;
  AppFailure? tokenFailure;
  AppFailure? setupFailure;
  int tokenRequests = 0;
  int setups = 0;

  /// What the room creation calls answer.
  String roomUrl = 'sendbird_room_1';
  AppFailure? roomFailure;
  final List<String> roomCalls = [];

  /// What the player search answers.
  List<AppUser> players = const [
    AppUser(id: 11, uid: 'uid-11', firstName: 'Ann', lastName: 'Lee'),
    AppUser(id: 12, uid: 'uid-12', firstName: 'Bo', lastName: 'Chan'),
  ];
  AppFailure? searchFailure;
  final List<String> searches = [];

  @override
  Future<String> sendbirdToken() async {
    final i = tokenRequests++;
    await Future<void>.delayed(Duration.zero);
    if (tokenFailure != null) throw tokenFailure!;
    return tokens[i < tokens.length ? i : tokens.length - 1];
  }

  @override
  Future<void> setupDefaultRooms() async {
    setups++;
    if (setupFailure != null) throw setupFailure!;
  }

  Future<String> _room(String call) async {
    roomCalls.add(call);
    await Future<void>.delayed(Duration.zero);
    if (roomFailure != null) throw roomFailure!;
    return roomUrl;
  }

  @override
  Future<String> playersChatRoom(int eventId, {int? teamId}) =>
      _room('players:$eventId:$teamId');

  @override
  Future<String> captainsChatRoom(int eventId) => _room('captains:$eventId');

  @override
  Future<String> directChatRoom({
    required String ownUid,
    required String otherUid,
  }) => _room('direct:$ownUid:$otherUid');

  @override
  Future<List<AppUser>> searchPlayers(
    String query, {
    required int excludeUserId,
  }) async {
    searches.add(query);
    await Future<void>.delayed(Duration.zero);
    if (searchFailure != null) throw searchFailure!;
    return [
      for (final p in players)
        if (query.isEmpty ||
            (p.firstName ?? '').toLowerCase().contains(query.toLowerCase()))
          p,
    ];
  }
}

class FakeChatClient implements ChatClient {
  FakeChatClient({this.initOk = true});

  bool initOk;

  /// Results of successive `connect` calls (the last one repeats).
  List<ChatConnectResult> results = [ChatConnectResult.connected];
  final List<({String userId, String token})> connects = [];
  final List<String> registered = [];
  final List<String> unregistered = [];
  int inits = 0;
  int disconnects = 0;
  final unread = StreamController<int>.broadcast();
  int unreadNow = 0;

  @override
  Future<bool> init(String appId) async {
    inits++;
    return initOk;
  }

  @override
  Future<ChatConnectResult> connect({
    required String userId,
    required String token,
  }) async {
    final i = connects.length;
    connects.add((userId: userId, token: token));
    await Future<void>.delayed(Duration.zero);
    return results[i < results.length ? i : results.length - 1];
  }

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<void> registerPushToken(String token, {required bool apns}) async =>
      registered.add(token);

  @override
  Future<void> unregisterPushToken(String token, {required bool apns}) async =>
      unregistered.add(token);

  @override
  Stream<int> unreadCount() async* {
    yield unreadNow;
    yield* unread.stream;
  }
}

/// Stands in for the Sendbird screens; shows the url and lets a test "tap" a
/// channel.
class FakeChatUi implements ChatUi {
  @override
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
    required VoidCallback onCreate,
  }) => Scaffold(
    body: Column(
      children: [
        const Text('fake channel list'),
        TextButton(onPressed: onCreate, child: const Text('new chat')),
        TextButton(
          onPressed: () => onOpen('channel-1'),
          child: const Text('open channel-1'),
        ),
      ],
    ),
  );

  @override
  Widget channel(BuildContext context, {required String channelUrl}) =>
      Scaffold(body: Text('fake channel $channelUrl'));
}

const monthlyPlan = StorePlan(
  id: 'qa.monthly',
  period: PlanPeriod.monthly,
  title: 'Monthly',
  price: r'$4.99',
  priceMicros: 4990000,
  currencyCode: 'USD',
);

const yearlyPlan = StorePlan(
  id: 'qa.yearly',
  period: PlanPeriod.yearly,
  title: 'Yearly',
  price: r'$39.99',
  priceMicros: 39990000,
  currencyCode: 'USD',
);

PurchaseRecord androidPurchase({
  String token = 'tok-1',
  bool acknowledged = false,
  String productId = 'qa.yearly',
}) => PurchaseRecord.fromMap({
  'platform': 'android',
  'orderId': 'GPA.1',
  'packageName': 'io.appsmaker.racketmates.qa',
  'productId': productId,
  'purchaseTime': 1700000000000,
  'purchaseState': 1,
  'purchaseToken': token,
  'autoRenewing': true,
  'acknowledged': acknowledged,
});

PurchaseRecord applePurchase({String original = 'orig-1'}) =>
    PurchaseRecord.fromMap({
      'platform': 'ios',
      'productId': 'qayearly',
      'originalTransactionId': original,
      'transactionId': 'tx-1',
      'json': '{"originalTransactionId":"$original","productId":"qayearly"}',
    });

class FakeBillingPlatform implements BillingPlatform {
  FakeBillingPlatform({
    this.available = true,
    this.plansToOffer = const [monthlyPlan, yearlyPlan],
    this.active = const [],
  });

  bool available;
  List<StorePlan> plansToOffer;
  List<PurchaseRecord> active;
  List<PurchaseRecord> restorable = const [];
  bool completeOk = true;
  final List<String> purchased = [];
  final List<String> accountIds = [];
  final List<String> completed = [];
  List<String> requestedIds = [];
  int redeemed = 0;
  int restores = 0;

  /// What `purchase` reports (default: the sheet opens and nothing happens
  /// until a test pushes an update).
  void Function(String id)? onPurchase;
  final updatesController = StreamController<PurchaseUpdate>.broadcast();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StorePlan>> plans(List<String> ids) async {
    requestedIds = ids;
    return plansToOffer;
  }

  @override
  Future<void> purchase(String productId, {required String accountId}) async {
    purchased.add(productId);
    accountIds.add(accountId);
    onPurchase?.call(productId);
  }

  @override
  Future<List<PurchaseRecord>> activePurchases() async => active;

  @override
  Future<List<PurchaseRecord>> restore() async {
    restores++;
    return restorable;
  }

  @override
  Future<bool> complete(PurchaseRecord record) async {
    completed.add(record.key);
    return completeOk;
  }

  @override
  Future<void> redeemCode() async => redeemed++;

  @override
  Stream<PurchaseUpdate> get updates => updatesController.stream;
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  AppFailure? failure;
  final List<PurchaseRecord> linked = [];

  @override
  Future<void> link(PurchaseRecord purchase) async {
    await Future<void>.delayed(Duration.zero);
    if (failure != null) throw failure!;
    linked.add(purchase);
  }
}

class FakeExternalLinks implements ExternalLinks {
  final List<Uri> opened = [];

  @override
  Future<void> open(Uri uri) async => opened.add(uri);
}

class InMemoryPromptStore implements SubscriptionPromptStore {
  /// [allSeen] (the default for app tests) means no reminder is ever due, so a
  /// test about something else is not interrupted by the subscription screen.
  InMemoryPromptStore({this.allSeen = true});

  final bool allSeen;
  final Set<String> seenKeys = {};

  @override
  Future<bool> seen(SubscriptionPromptKind kind, int userId) async =>
      allSeen || seenKeys.contains('${kind.name}:$userId');

  @override
  Future<void> markSeen(SubscriptionPromptKind kind, int userId) async =>
      seenKeys.add('${kind.name}:$userId');
}

class FakeLocationPlatform implements LocationPlatform {
  /// Default: undecided and answering "granted", with a fix, so a screen that
  /// asks gets a position. Tests set what they need.
  FakeLocationPlatform({
    this.state = LocationPermission.notDetermined,
    this.answerToRequest = LocationPermission.granted,
    this.position = const LatLng(40.7128, -74.006),
  });

  LocationPermission state;
  LocationPermission answerToRequest;
  LatLng? position;
  int requests = 0;
  int fixes = 0;
  int settingsOpened = 0;

  @override
  Future<LocationPermission> permission() async => state;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    state = answerToRequest;
    return state;
  }

  @override
  Future<LatLng?> currentPosition() async {
    fixes++;
    return position;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class InMemoryDistanceStore implements DistanceFilterStore {
  int value = defaultSearchDistance;

  @override
  Future<int> read() async => value;

  @override
  Future<void> write(int distance) async => value = distance;
}
