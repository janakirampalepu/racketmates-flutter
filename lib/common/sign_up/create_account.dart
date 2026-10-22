import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_form.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_repository.dart';

class CreatedAccount {
  const CreatedAccount({required this.user, this.token});

  final AppUser? user;

  /// New session to persist (null on resume: the session already exists).
  final SessionToken? token;
}

/// Native `createUserAccount`: new numbers `POST users?signing_up=true` then an
/// OAuth password grant (username from the response, the verification code
/// from `verify_sms_code`); unfinished sign-ups `PUT users/{id}` with the
/// existing session.
class CreateAccountUseCase {
  const CreateAccountUseCase({
    required this.preLoginUsers,
    required this.users,
    required this.phone,
  });

  final UserRepository preLoginUsers;
  final UserRepository users;
  final PhoneVerificationRepository phone;

  Future<CreatedAccount> call(SignUpDraft draft) async {
    final form = buildSignUpForm(draft);
    if (draft.resume && draft.userId != null) {
      final details = await users.updateUser(draft.userId!, form);
      return CreatedAccount(user: details.user);
    }
    final details = await preLoginUsers.createAccount(form);
    final username = details.user?.mobileNumber;
    final token = await phone.signIn(
      PhoneNumberParts(
        nationalNumber: (username != null && username.isNotEmpty)
            ? username
            : draft.phone.nationalNumber,
        countryCode: draft.phone.countryCode,
        regionCode: draft.phone.regionCode,
      ),
      draft.verificationCode,
    );
    return CreatedAccount(user: details.user, token: token);
  }
}
