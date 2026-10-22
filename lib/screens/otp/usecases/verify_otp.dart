import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';

sealed class OtpOutcome {
  const OtpOutcome();
}

/// Verified, registered, sign-up complete: the session token to persist.
class OtpSignedIn extends OtpOutcome {
  const OtpSignedIn(this.token);

  final SessionToken token;
}

/// Verified but sign-up must be completed ([resume] = account already exists
/// and sign-up was left unfinished). Handled by the sign-up milestone.
class OtpSignUpRequired extends OtpOutcome {
  const OtpSignUpRequired({required this.resume});

  final bool resume;
}

class OtpInvalidCode extends OtpOutcome {
  const OtpInvalidCode();
}

/// Native flow (`OtpFragment.showNextScreen`): `verify_sms_code`; when the code
/// is valid and the player exists, OAuth password grant with the returned
/// `verification_code`; `is_signed_up` decides between the app and sign-up.
class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final PhoneVerificationRepository _repository;

  Future<OtpOutcome> call(PhoneNumberParts phone, String code) async {
    final response = await _repository.verifySmsCode(phone, code);
    if (response.valid != true) return const OtpInvalidCode();
    if (response.playerExist != true) {
      return const OtpSignUpRequired(resume: false);
    }
    if (response.isSignedUp != true) {
      return const OtpSignUpRequired(resume: true);
    }
    final token = await _repository.signIn(
      phone,
      response.verificationCode ?? '',
    );
    return OtpSignedIn(token);
  }
}
