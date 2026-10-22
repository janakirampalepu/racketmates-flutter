import 'package:dio/dio.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
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
