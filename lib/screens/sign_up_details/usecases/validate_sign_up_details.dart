import 'package:racketmates/screens/sign_up_details/sign_up_details_state.dart';

/// Android `Patterns.EMAIL_ADDRESS`.
final _email = RegExp(
  r'^[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9][a-zA-Z0-9\-]{0,64}'
  r'(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+$',
);

bool isValidEmail(String value) => _email.hasMatch(value);

class DetailsValidation {
  const DetailsValidation({
    required this.firstNameMissing,
    required this.lastNameMissing,
    required this.emailError,
  });

  final bool firstNameMissing;
  final bool lastNameMissing;
  final EmailError? emailError;

  bool get isValid =>
      !firstNameMissing && !lastNameMissing && emailError == null;
}

/// First and last name are required; email is optional but must be valid when
/// given (native `SignUpDetailsFragment.validationCheck`).
DetailsValidation validateSignUpDetails({
  required String firstName,
  required String lastName,
  required String email,
}) {
  final trimmed = email.trim();
  return DetailsValidation(
    firstNameMissing: firstName.trim().isEmpty,
    lastNameMissing: lastName.trim().isEmpty,
    emailError: trimmed.isNotEmpty && !isValidEmail(trimmed)
        ? EmailError.invalid
        : null,
  );
}
