import 'package:dio/dio.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:retrofit/retrofit.dart';

part 'content_api.g.dart';

/// Server-driven content endpoints. They authenticate with the OAuth client in
/// the query (no bearer token), so they also work before sign-in.
/// `messages` / `preLoginMessages` return the raw JSON tree (`dynamic`): the
/// string trees are read by path, not mapped to classes.
@RestApi()
abstract class ContentApi {
  factory ContentApi(Dio dio, {String? baseUrl}) = _ContentApi;

  @GET('resources/messages')
  Future<dynamic> messages(
    @Query('client_id') String clientId,
    @Query('client_secret') String clientSecret,
  );

  @GET('resources/pre_login_messages')
  Future<dynamic> preLoginMessages(
    @Query('client_id') String clientId,
    @Query('client_secret') String clientSecret,
  );

  @GET('reference_data')
  Future<ReferenceDataResponse> referenceData(
    @Query('client_id') String clientId,
    @Query('client_secret') String clientSecret,
  );
}
