import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/screens/kid_form/kid_form_state.dart';

class KidFormViewModel extends Notifier<KidFormState> {
  @override
  KidFormState build() => const KidFormState();

  /// Validates a kid (names, optional mobile, at least one sport) and saves it
  /// to the sign-up draft. A kid's mobile must not belong to a registered user
  /// (native `ValidateMobileNumberResponse.userExist`).
  Future<bool> save({
    required String firstName,
    required String lastName,
    required String mobile,
    required Set<SportKey> sports,
    required Country? country,
    int? index,
  }) async {
    final digits = digitsOnly(mobile);
    final mobileInvalid =
        digits.isNotEmpty &&
        (country == null ||
            validateNationalNumber(digits, country) != PhoneValidation.ok);
    final missingFirst = firstName.trim().isEmpty;
    final missingLast = lastName.trim().isEmpty;
    final missingSport = sports.isEmpty;
    if (missingFirst || missingLast || mobileInvalid || missingSport) {
      state = KidFormState(
        firstNameMissing: missingFirst,
        lastNameMissing: missingLast,
        mobileError: mobileInvalid ? KidMobileError.invalid : null,
        sportMissing: missingSport,
      );
      return false;
    }
    final flow = ref.read(signUpFlowProvider.notifier);
    final draft = ref.read(signUpFlowProvider)!;
    if (digits.isNotEmpty) {
      state = const KidFormState(loading: true);
      try {
        final status = await ref
            .read(phoneVerificationRepositoryProvider)
            .validateMobileNumber(
              PhoneNumberParts(
                nationalNumber: digits,
                countryCode: draft.phone.countryCode,
                regionCode: draft.phone.regionCode,
              ),
            );
        if (status.userExist ?? false) {
          state = const KidFormState(mobileError: KidMobileError.taken);
          return false;
        }
      } on AppFailure catch (failure) {
        state = KidFormState(failure: failure);
        return false;
      }
    }
    final existing = (index != null && index < draft.kids.length)
        ? draft.kids[index]
        : null;
    final kid = (existing ?? const KidDraft()).copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      mobileNumber: digits,
      sports: sports,
    );
    flow.saveKid(kid, index: index);
    state = const KidFormState();
    return true;
  }
}

final kidFormViewModelProvider =
    NotifierProvider.autoDispose<KidFormViewModel, KidFormState>(
      KidFormViewModel.new,
    );
