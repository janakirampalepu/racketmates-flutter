import 'package:dio/dio.dart';

/// App-wide failure types. User-facing text is resolved by the UI layer
/// (server-driven strings with local fallbacks), never here.
sealed class AppFailure implements Exception {
  const AppFailure([this.message]);

  final String? message;
}

class OfflineFailure extends AppFailure {
  const OfflineFailure();
}

class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message]);
}

class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode, [super.message]);

  final int? statusCode;
}

class ParseFailure extends AppFailure {
  const ParseFailure([super.message]);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message]);
}

/// Tolerant reader for the error body shapes seen in the native apps
/// (`error`, `message`, `error_message`).
String? extractServerMessage(Object? data) {
  if (data is Map) {
    for (final key in const ['error_message', 'message', 'error']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
  }
  return null;
}

AppFailure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const OfflineFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final message = extractServerMessage(e.response?.data);
      if (status == 401) return UnauthorizedFailure(message);
      return ServerFailure(status, message);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}
