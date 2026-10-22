import 'package:dio/dio.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/content/content_api.dart';
import 'package:racketmates/common/content/reference_data.dart';

abstract class ContentRepository {
  Future<Map<String, dynamic>> messages();
  Future<Map<String, dynamic>> preLoginMessages();
  Future<ReferenceDataResponse> referenceData();
}

class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl({
    required this.api,
    required this.clientId,
    required this.clientSecret,
  });

  final ContentApi api;
  final String clientId;
  final String clientSecret;

  Map<String, dynamic> _tree(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const ParseFailure('strings payload is not an object');
  }

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
  Future<Map<String, dynamic>> messages() async =>
      _tree(await _guard(() => api.messages(clientId, clientSecret)));

  @override
  Future<Map<String, dynamic>> preLoginMessages() async =>
      _tree(await _guard(() => api.preLoginMessages(clientId, clientSecret)));

  @override
  Future<ReferenceDataResponse> referenceData() =>
      _guard(() => api.referenceData(clientId, clientSecret));
}
