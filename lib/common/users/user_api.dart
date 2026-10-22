import 'package:dio/dio.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api.g.dart';

/// Existing `users` endpoints. `createUser` and `checkDuplicate` run before a
/// session exists (use the Dio without the auth interceptor); the others use
/// the authenticated Dio.
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('users/{id}')
  Future<UserDetails> getUser(@Path('id') int id);

  @GET('validations/duplicate_dname_email_check')
  Future<DuplicateCheck> duplicateCheck(
    @Query('email') String email,
    @Query('display_name') String displayName,
    @Query('user_id') int? userId,
  );

  /// Multipart sign-up (`signing_up=true`), field names as built by
  /// `buildSignUpForm`.
  @POST('users')
  @MultiPart()
  Future<UserDetails> createUser(
    @Body() FormData form,
    @Query('signing_up') bool signingUp,
  );

  /// Multipart update: resume of an unfinished sign-up, avatar upload.
  @PUT('users/{id}')
  @MultiPart()
  Future<UserDetails> updateUser(@Path('id') int id, @Body() FormData form);
}
