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

/// Verified but sign-up must be completed. [resume] = the account already
/// exists with sign-up unfinished: then [token] is the OAuth token to use for
/// updating it. [verificationCode] is sent again with the sign-up request.
class OtpSignUpRequired extends OtpOutcome {
  const OtpSignUpRequired({
    required this.resume,
    required this.verificationCode,
    this.token,
  });

  final bool resume;
  final String verificationCode;
  final SessionToken? token;
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
    final verificationCode = response.verificationCode ?? '';
    if (response.playerExist != true) {
      return OtpSignUpRequired(
        resume: false,
        verificationCode: verificationCode,
      );
    }
    final token = await _repository.signIn(phone, verificationCode);
    if (response.isSignedUp != true) {
      return OtpSignUpRequired(
        resume: true,
        verificationCode: verificationCode,
        token: token,
      );
    }
    return OtpSignedIn(token);
  }
}
