import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';

sealed class SubmitPhoneResult {
  const SubmitPhoneResult();
}

/// Code sent; continue to OTP in [mode].
class CodeSent extends SubmitPhoneResult {
  const CodeSent(this.mode);

  final PhoneEntryMode mode;
}

/// The chosen mode does not match the number's registration (native
/// `MobileNumberVerificationPicker`): ask before switching to [suggestedMode].
class ModeMismatch extends SubmitPhoneResult {
  const ModeMismatch(this.suggestedMode);

  final PhoneEntryMode suggestedMode;
}

/// Validates the number against the backend and sends the SMS code.
///
/// Native rules (`SignUpFragment.showUserStatusPopup`): signing up with an
/// already registered number, or signing in with an unregistered one, asks the
/// user to switch; otherwise the code is sent.
class SubmitPhoneNumberUseCase {
  const SubmitPhoneNumberUseCase(this._repository);

  final PhoneVerificationRepository _repository;

  Future<SubmitPhoneResult> call(
    PhoneNumberParts phone,
    PhoneEntryMode mode,
  ) async {
    final status = await _repository.validateMobileNumber(phone);
    if (mode == PhoneEntryMode.signUp && status.isRegistered) {
      return const ModeMismatch(PhoneEntryMode.signIn);
    }
    if (mode == PhoneEntryMode.signIn && !status.isRegistered) {
      return const ModeMismatch(PhoneEntryMode.signUp);
    }
    await _repository.sendSmsCode(phone);
    return CodeSent(mode);
  }

  /// After the user accepts switching modes: send the code in the new mode.
  Future<SubmitPhoneResult> sendCode(
    PhoneNumberParts phone,
    PhoneEntryMode mode,
  ) async {
    await _repository.sendSmsCode(phone);
    return CodeSent(mode);
  }
}
