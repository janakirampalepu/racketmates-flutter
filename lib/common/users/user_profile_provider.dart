import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_repository.dart';

/// The signed-in user's profile (`GET users/{id}`), loaded after sign-in and on
/// session restore; null when signed out or the token carries no user id.
/// In-memory only (the native apps also cache the JSON; add persistence if a
/// screen needs offline profile data).
final userProfileProvider = FutureProvider<AppUser?>((ref) async {
  final session = ref.watch(sessionControllerProvider);
  if (session is! SignedIn) return null;
  final id = session.token.user?.id;
  if (id == null) return null;
  return (await ref.watch(userRepositoryProvider).fetchUser(id)).user;
});
