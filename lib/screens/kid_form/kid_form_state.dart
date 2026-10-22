import 'package:racketmates/common/errors/app_failure.dart';

enum KidMobileError { invalid, taken }

class KidFormState {
  const KidFormState({
    this.loading = false,
    this.firstNameMissing = false,
    this.lastNameMissing = false,
    this.mobileError,
    this.sportMissing = false,
    this.failure,
  });

  final bool loading;
  final bool firstNameMissing;
  final bool lastNameMissing;
  final KidMobileError? mobileError;
  final bool sportMissing;
  final AppFailure? failure;
}
