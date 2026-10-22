import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/create_event/create_event_api.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/users/models/app_user.dart';

abstract class CreateEventRepository {
  /// `POST events`; returns the created event (and server message).
  Future<EventDetailsResponse> create(Map<String, dynamic> body);

  /// Users matching [query] with role [role] (`ur_player`, `ur_coach`; null =
  /// any), limited to those who play [sportKey] (`st_tennis`) when given.
  Future<List<AppUser>> searchUsers({
    required String query,
    String? role,
    String? sportKey,
  });

  /// Scoring formats a sport offers for an event type.
  Future<ScoringFormatsResponse> scoringFormats({
    required String sportKey,
    required String eventType,
  });

  /// `timezone_info_id` for a venue at [latitude]/[longitude] and local [time]
  /// (`yyyy-MM-dd'T'HH:mm'Z'`), or null when it cannot be resolved.
  Future<int?> timezoneInfoId({
    required double latitude,
    required double longitude,
    required String time,
  });
}

class CreateEventRepositoryImpl implements CreateEventRepository {
  const CreateEventRepositoryImpl(this.api);

  final CreateEventApi api;

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
  Future<EventDetailsResponse> create(Map<String, dynamic> body) =>
      _guard(() => api.createEvent(body));

  @override
  Future<List<AppUser>> searchUsers({
    required String query,
    String? role,
    String? sportKey,
  }) async =>
      (await _guard(
        () => api.searchUsers(
          search: query.trim(),
          roles: role == null ? null : [role],
          sportTypes: sportKey == null ? null : [sportKey],
        ),
      )).users ??
      const [];

  @override
  Future<ScoringFormatsResponse> scoringFormats({
    required String sportKey,
    required String eventType,
  }) => _guard(
    () => api.scoringFormats(sportType: sportKey, eventType: eventType),
  );

  @override
  Future<int?> timezoneInfoId({
    required double latitude,
    required double longitude,
    required String time,
  }) async {
    final response = await _guard(
      () => api.timezoneLookup(
        latitude: '$latitude',
        longitude: '$longitude',
        time: time,
      ),
    );
    return response.timezoneInfo?.id;
  }
}

final createEventRepositoryProvider = Provider<CreateEventRepository>(
  (ref) => CreateEventRepositoryImpl(CreateEventApi(ref.watch(apiDioProvider))),
);
