import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_api.dart';

/// Schedule tab / list kind. Values are the backend's `events_for` and
/// `time_period` strings (native `AppConstants`).
enum ScheduleTab {
  upcoming(eventsFor: 'upcoming', timePeriod: 'future'),
  past(eventsFor: 'past', timePeriod: 'past');

  const ScheduleTab({required this.eventsFor, required this.timePeriod});

  final String eventsFor;
  final String timePeriod;
}

/// Event roles requested by home and schedule (native `getSelectedOwnerType`).
const defaultEventRoles = ['managing', 'participant'];

/// Home shows this many upcoming/past events (native `HOME_PAGE_UPCOMMING_COUNT`).
const homeEventsCount = 3;

/// Schedule page size (native `VALUE_TEN`); page numbers start at 1.
const schedulePageSize = 10;

abstract class ScheduleRepository {
  Future<List<ScheduleItem>> homeUpcoming({
    required List<String> userIds,
    required int hourFormat,
  });

  Future<List<ScheduleItem>> homePast({
    required List<String> userIds,
    required int hourFormat,
  });

  /// One page of a schedule tab; an empty list means the end was reached.
  Future<ScheduleListResponse> schedulePage({
    required ScheduleTab tab,
    required int page,
    required List<String> userIds,
    required int hourFormat,
  });

  Future<List<PendingAction>> pendingActions({required List<String> userIds});

  Future<List<HomePageStats>> activitySummary({required List<String> userIds});

  Future<List<PlayerCard>> latestUpdates({required List<String> userIds});

  Future<EventDetails> eventDetails(int id, {required int hourFormat});
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this.api);

  final ScheduleApi api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<List<ScheduleItem>> homeUpcoming({
    required List<String> userIds,
    required int hourFormat,
  }) async {
    final response = await _guard(
      () => api.scheduledEvents(
        perPage: homeEventsCount,
        page: 1,
        eventsFor: 'home_page_upcoming',
        userIds: userIds,
        eventRoles: defaultEventRoles,
        hourFormat: hourFormat,
      ),
    );
    return response.scheduleItems ?? const [];
  }

  @override
  Future<List<ScheduleItem>> homePast({
    required List<String> userIds,
    required int hourFormat,
  }) async {
    final response = await _guard(
      () => api.scheduledEvents(
        perPage: homeEventsCount,
        page: 1,
        eventsFor: ScheduleTab.past.eventsFor,
        timePeriod: ScheduleTab.past.timePeriod,
        userIds: userIds,
        eventRoles: defaultEventRoles,
        hourFormat: hourFormat,
      ),
    );
    return response.scheduleItems ?? const [];
  }

  @override
  Future<ScheduleListResponse> schedulePage({
    required ScheduleTab tab,
    required int page,
    required List<String> userIds,
    required int hourFormat,
  }) => _guard(
    () => api.scheduledEvents(
      perPage: schedulePageSize,
      page: page,
      eventsFor: tab.eventsFor,
      timePeriod: tab.timePeriod,
      userIds: userIds,
      eventRoles: defaultEventRoles,
      hourFormat: hourFormat,
    ),
  );

  @override
  Future<List<PendingAction>> pendingActions({
    required List<String> userIds,
  }) async =>
      (await _guard(() => api.pendingActions(userIds: userIds)))
          .pendingActions ??
      const [];

  @override
  Future<List<HomePageStats>> activitySummary({
    required List<String> userIds,
  }) async =>
      (await _guard(() => api.statsSummary(userIds: userIds))).homePageStats ??
      const [];

  @override
  Future<List<PlayerCard>> latestUpdates({
    required List<String> userIds,
  }) async =>
      (await _guard(
        () => api.playerCards(
          userIds: userIds,
          cardTypes: const [playerCardEventResultUpdate],
        ),
      )).playerCards ??
      const [];

  @override
  Future<EventDetails> eventDetails(int id, {required int hourFormat}) async {
    final response = await _guard(
      () =>
          api.eventDetails(id, hourFormat: hourFormat, viewType: 'participant'),
    );
    final event = response.event;
    if (event == null) throw const ParseFailure('event missing');
    return event;
  }
}

final scheduleApiProvider = Provider<ScheduleApi>(
  (ref) => ScheduleApi(ref.watch(apiDioProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(ref.watch(scheduleApiProvider)),
);

/// Users whose events are shown (`user_ids[]`). Native default: the signed-in
/// user; the family picker (parents with kids) is a later addition.
final selectedUserIdsProvider = Provider<List<String>>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final id = session is SignedIn ? session.token.user?.id : null;
  return id == null ? const [] : ['$id'];
});

/// `hour_format` query value: 24 when the device uses a 24-hour clock.
final hourFormatProvider = Provider<int>(
  (ref) => WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat
      ? 24
      : 12,
);
