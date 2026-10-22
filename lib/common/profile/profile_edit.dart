import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/sign_up_details/usecases/validate_sign_up_details.dart'
    show isValidEmail;

enum ProfileError { firstNameMissing, lastNameMissing, emailInvalid }

/// What the profile editor changes.
class ProfileEdit {
  const ProfileEdit({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ProfileEdit.of(AppUser user) => ProfileEdit(
    firstName: user.firstName ?? '',
    lastName: user.lastName ?? '',
    email: user.email ?? '',
  );

  final String firstName;
  final String lastName;
  final String email;

  ProfileEdit copyWith({String? firstName, String? lastName, String? email}) =>
      ProfileEdit(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
      );

  /// The email as the backend stores it.
  String get normalizedEmail => email.trim().toLowerCase();
}

/// First and last name are required; the email is optional but valid when
/// given (native `ProfilePicUpdateFragment.isAllFieldsValid`).
List<ProfileError> validateProfile(ProfileEdit edit) => [
  if (edit.firstName.trim().isEmpty) ProfileError.firstNameMissing,
  if (edit.lastName.trim().isEmpty) ProfileError.lastNameMissing,
  if (edit.email.trim().isNotEmpty && !isValidEmail(edit.email.trim()))
    ProfileError.emailInvalid,
];

/// Whether [edit] differs from what [user] has.
bool profileChanged(AppUser user, ProfileEdit edit) {
  final before = ProfileEdit.of(user);
  return before.firstName.trim() != edit.firstName.trim() ||
      before.lastName.trim() != edit.lastName.trim() ||
      before.normalizedEmail != edit.normalizedEmail;
}

/// Body of `PUT users/{id}` (native `ProfileViewModel.updateProfileToAPI`): the
/// edited fields, the phone number, and the user's roles and sports sent back
/// unchanged so the update does not touch them.
Map<String, dynamic> buildProfileUpdateBody(AppUser user, ProfileEdit edit) {
  if (validateProfile(edit).isNotEmpty) throw StateError('invalid profile');
  return {
    'user': {
      'first_name': edit.firstName,
      'last_name': edit.lastName,
      'email': edit.normalizedEmail,
      'mobile_number': user.mobileNumber,
      'user_roles_attributes': [
        for (final role in user.userRoles ?? const <UserRole>[])
          {
            'id': role.id,
            'role': role.role,
            'user_role_sports_attributes': [
              for (final sport
                  in role.userRoleSports ?? const <UserRoleSport>[])
                {'id': sport.id, 'sport_type': sport.sportType},
            ],
          },
      ],
    },
    'roles': user.roles ?? const <String>[],
    'region_code': user.country?.regionCode ?? '',
    'country_code': user.country?.code ?? '',
  };
}
