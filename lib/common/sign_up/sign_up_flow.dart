import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/sign_up/create_account.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_repository.dart';

/// Device timezone id (IANA), or null when the platform cannot tell. Anything
/// that writes the zone to the server uses this one, so a failed lookup never
/// overwrites the user's real zone.
final deviceTimezoneOrNullProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone().timeout(
      const Duration(seconds: 2),
    );
    return info.identifier;
  } on Object {
    return null;
  }
});

/// Device timezone id (IANA) with a UTC fallback (sign-up needs a value).
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  final id = await ref.watch(deviceTimezoneOrNullProvider.future);
  return id ?? 'UTC';
});

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>(
  (ref) => CreateAccountUseCase(
    preLoginUsers: ref.watch(preLoginUserRepositoryProvider),
    users: ref.watch(userRepositoryProvider),
    phone: ref.watch(phoneVerificationRepositoryProvider),
  ),
);

/// State shared by the sign-up screens (details, roles, sports, kids). It
/// lives in `common/` because several screens read and write it; it is
/// cleared when the flow ends.
class SignUpFlow extends Notifier<SignUpDraft?> {
  @override
  SignUpDraft? build() => null;

  SignUpDraft get _draft => state!;

  void start({
    required PhoneNumberParts phone,
    required String verificationCode,
    required bool resume,
    int? userId,
    String? timezone,
  }) {
    state = SignUpDraft(
      phone: phone,
      verificationCode: verificationCode,
      resume: resume,
      userId: userId,
      timezone: timezone ?? 'UTC',
    );
  }

  void reset() => state = null;

  void setTimezone(String timezone) =>
      state = _draft.copyWith(timezone: timezone);

  void setDetails({
    required String firstName,
    required String lastName,
    required String email,
  }) => state = _draft.copyWith(
    firstName: firstName,
    lastName: lastName,
    email: email,
  );

  void toggleRole(String role) {
    final roles = {..._draft.roles};
    if (!roles.add(role)) roles.remove(role);
    state = _draft.copyWith(roles: roles);
  }

  void toggleSport(String role, SportKey sport) {
    final current = role == RoleKeys.coach
        ? _draft.coachSports
        : _draft.playerSports;
    final next = {...current};
    if (!next.add(sport)) next.remove(sport);
    state = role == RoleKeys.coach
        ? _draft.copyWith(coachSports: next)
        : _draft.copyWith(playerSports: next);
  }

  /// Adds a kid, or replaces the one at [index].
  void saveKid(KidDraft kid, {int? index}) {
    final kids = [..._draft.kids];
    if (index != null && index < kids.length) {
      kids[index] = kid;
    } else if (kids.length < SignUpDraft.maxKids) {
      kids.add(kid);
    }
    state = _draft.copyWith(kids: kids);
  }

  void removeKid(int index) {
    final kids = [..._draft.kids]..removeAt(index);
    state = _draft.copyWith(kids: kids);
    if (kids.isEmpty && _draft.hasParent) {
      state = _draft.copyWith(
        roles: {..._draft.roles}..remove(RoleKeys.parent),
      );
    }
  }

  /// Resume: pre-fill the form from the existing profile (names, email, roles,
  /// sports and kids, plus the ids needed to update/destroy them).
  void prefillFrom(AppUser user) {
    final roleIds = <String, int>{};
    final sportIds = <String, Map<SportKey, int>>{};
    final roles = <String>{};
    var player = <SportKey>{};
    var coach = <SportKey>{};
    for (final role in user.userRoles ?? const <UserRole>[]) {
      final key = role.role;
      if (key == null) continue;
      roles.add(key);
      if (role.id != null) roleIds[key] = role.id!;
      final ids = <SportKey, int>{};
      final sports = <SportKey>{};
      for (final s in role.userRoleSports ?? const <UserRoleSport>[]) {
        final sport = SportKey.fromKey(s.sportType);
        if (sport == null) continue;
        sports.add(sport);
        if (s.id != null) ids[sport] = s.id!;
      }
      sportIds[key] = ids;
      if (key == RoleKeys.player) player = sports;
      if (key == RoleKeys.coach) coach = sports;
    }
    final kids = <KidDraft>[
      for (final child in user.children ?? const <AppUser>[]) _kidFrom(child),
    ];
    state = _draft.copyWith(
      firstName: user.firstName ?? '',
      lastName: user.lastName ?? '',
      email: user.email ?? '',
      roles: roles,
      playerSports: player,
      coachSports: coach,
      kids: kids,
      roleIds: roleIds,
      sportIds: sportIds,
    );
  }

  KidDraft _kidFrom(AppUser child) {
    final role = child.roleOf(RoleKeys.player);
    final ids = <SportKey, int>{};
    final sports = <SportKey>{};
    for (final s in role?.userRoleSports ?? const <UserRoleSport>[]) {
      final sport = SportKey.fromKey(s.sportType);
      if (sport == null) continue;
      sports.add(sport);
      if (s.id != null) ids[sport] = s.id!;
    }
    return KidDraft(
      id: child.id,
      firstName: child.firstName ?? '',
      lastName: child.lastName ?? '',
      mobileNumber: child.mobileNumber ?? '',
      sports: sports,
      roleId: role?.id,
      sportIds: ids,
    );
  }
}

final signUpFlowProvider = NotifierProvider<SignUpFlow, SignUpDraft?>(
  SignUpFlow.new,
);
