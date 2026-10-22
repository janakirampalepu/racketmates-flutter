// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_event_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSearchResponse _$UserSearchResponseFromJson(Map<String, dynamic> json) =>
    UserSearchResponse(
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserSearchResponseToJson(UserSearchResponse instance) =>
    <String, dynamic>{'users': instance.users};

ScoringFormatsResponse _$ScoringFormatsResponseFromJson(
  Map<String, dynamic> json,
) => ScoringFormatsResponse(
  scoringFormatKeys: (json['scoring_format_keys'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  minimumScores: (json['minimum_scores'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as num?),
  ),
);

Map<String, dynamic> _$ScoringFormatsResponseToJson(
  ScoringFormatsResponse instance,
) => <String, dynamic>{
  'scoring_format_keys': instance.scoringFormatKeys,
  'minimum_scores': instance.minimumScores,
};

TimezoneLookupResponse _$TimezoneLookupResponseFromJson(
  Map<String, dynamic> json,
) => TimezoneLookupResponse(
  timezoneInfo: json['timezone_info'] == null
      ? null
      : TimezoneInfo.fromJson(json['timezone_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TimezoneLookupResponseToJson(
  TimezoneLookupResponse instance,
) => <String, dynamic>{'timezone_info': instance.timezoneInfo};

TimezoneInfo _$TimezoneInfoFromJson(Map<String, dynamic> json) => TimezoneInfo(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  utcOffsetTime: (json['utc_offset_time'] as num?)?.toInt(),
  abbreviation: json['abbreviation'] as String?,
);

Map<String, dynamic> _$TimezoneInfoToJson(TimezoneInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'utc_offset_time': instance.utcOffsetTime,
      'abbreviation': instance.abbreviation,
    };

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _CreateEventApi implements CreateEventApi {
  _CreateEventApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<EventDetailsResponse> createEvent(Map<String, dynamic> body) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _options = _setStreamType<EventDetailsResponse>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'events',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EventDetailsResponse _value;
    try {
      _value = EventDetailsResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<UserSearchResponse> searchUsers({
    String? search,
    List<String>? roles,
    List<String>? sportTypes,
    List<int>? includeUserIds,
    List<int>? excludeUserIds,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'search': search,
      r'roles[]': roles,
      r'sport_types[]': sportTypes,
      r'include_user_ids[]': includeUserIds,
      r'exclude_user_ids[]': excludeUserIds,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<UserSearchResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'users',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late UserSearchResponse _value;
    try {
      _value = UserSearchResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<ScoringFormatsResponse> scoringFormats({
    String? sportType,
    String? eventType,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'sport_type': sportType,
      r'event_type': eventType,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<ScoringFormatsResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'reference_data/scoring_formats',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late ScoringFormatsResponse _value;
    try {
      _value = ScoringFormatsResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<TimezoneLookupResponse> timezoneLookup({
    String? latitude,
    String? longitude,
    String? time,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'latitude': latitude,
      r'longitude': longitude,
      r'time': time,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<TimezoneLookupResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'timezone_infos/lookup',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late TimezoneLookupResponse _value;
    try {
      _value = TimezoneLookupResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
