import 'package:racketmates/common/errors/app_failure.dart';

enum EmailError { invalid, taken }

class SignUpDetailsState {
  const SignUpDetailsState({
    this.loading = false,
    this.firstNameMissing = false,
    this.lastNameMissing = false,
    this.emailError,
    this.failure,
  });

  final bool loading;
  final bool firstNameMissing;
  final bool lastNameMissing;
  final EmailError? emailError;
  final AppFailure? failure;
}
