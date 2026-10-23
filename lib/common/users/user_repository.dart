import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_api.dart';

abstract class UserRepository {
  Future<UserDetails> fetchUser(int id);

  /// True when the email is already taken (`email_result`).
  Future<bool> isEmailTaken({
    required String email,
    required String displayName,
    int? userId,
  });

  Future<UserDetails> createAccount(FormData form);
  Future<UserDetails> updateUser(int id, FormData form);

  /// `PUT users/{id}` with the multipart field `user[avatar_file]`.
  Future<UserDetails> uploadAvatar(int id, String filePath);

  /// `PUT users/{id}` with the profile body of `buildProfileUpdateBody`.
  Future<UserDetails> updateProfile(int id, Map<String, dynamic> body);

  /// `DELETE users/{id}/destroy_profile_image`.
  Future<void> removeAvatar(int id);

  /// Sports of a role the user has: `PUT users/{id}/user_roles/{roleId}`.
  Future<UserDetails> updateRole(int id, int roleId, Map<String, dynamic> body);

  /// A role the user does not have yet: `POST users/{id}/user_roles`.
  Future<UserDetails> addRole(int id, Map<String, dynamic> body);

  /// `POST users` for a kid of the signed-in parent.
  Future<UserDetails> createKid(FormData form);

  /// `DELETE users/{id}` (a kid account).
  Future<void> deleteUser(int id);

  /// `PUT users/{id}/change_mobile_number` after the new number was verified.
  Future<UserDetails> changeMobileNumber(int id, Map<String, dynamic> body);
}

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this.api);

  final UserApi api;

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
  Future<UserDetails> fetchUser(int id) => _guard(() => api.getUser(id));

  @override
  Future<bool> isEmailTaken({
    required String email,
    required String displayName,
    int? userId,
  }) async {
    final result = await _guard(
      () => api.duplicateCheck(email, displayName, userId),
    );
    return result.emailResult ?? false;
  }

  @override
  Future<UserDetails> createAccount(FormData form) =>
      _guard(() => api.createUser(form, true));

  @override
  Future<UserDetails> updateUser(int id, FormData form) =>
      _guard(() => api.updateUser(id, form));

  @override
  Future<UserDetails> updateProfile(int id, Map<String, dynamic> body) =>
      _guard(() => api.updateProfile(id, body));

  @override
  Future<UserDetails> updateRole(
    int id,
    int roleId,
    Map<String, dynamic> body,
  ) => _guard(() => api.updateRole(id, roleId, body));

  @override
  Future<UserDetails> addRole(int id, Map<String, dynamic> body) =>
      _guard(() => api.addRole(id, body));

  @override
  Future<UserDetails> createKid(FormData form) =>
      _guard(() => api.createKid(form));

  @override
  Future<void> deleteUser(int id) => _guard(() => api.deleteUser(id));

  @override
  Future<UserDetails> changeMobileNumber(int id, Map<String, dynamic> body) =>
      _guard(() => api.changeMobileNumber(id, body));

  @override
  Future<void> removeAvatar(int id) => _guard(() => api.removeAvatar(id));

  @override
  Future<UserDetails> uploadAvatar(int id, String filePath) async {
    final form = FormData.fromMap({
      avatarFileField: await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    return _guard(() => api.updateUser(id, form));
  }
}

/// Native `AppConstants.AVATAR_FILE`.
const avatarFileField = 'user[avatar_file]';

/// Before sign-in: no bearer token, no refresh.
final preLoginUserRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(UserApi(ref.watch(authDioProvider))),
);

/// After sign-in: authenticated, with token refresh.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(UserApi(ref.watch(apiDioProvider))),
);
