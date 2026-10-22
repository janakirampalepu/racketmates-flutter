import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_state.dart';
import 'package:racketmates/screens/sign_up_details/usecases/validate_sign_up_details.dart';

class SignUpDetailsViewModel extends Notifier<SignUpDetailsState> {
  @override
  SignUpDetailsState build() => const SignUpDetailsState();

  UserRepository get _users {
    final draft = ref.read(signUpFlowProvider);
    // A resumed account already has a session; a new one does not.
    return (draft?.resume ?? false)
        ? ref.read(userRepositoryProvider)
        : ref.read(preLoginUserRepositoryProvider);
  }

  /// Resume: pre-fill the form from the existing profile.
  Future<void> loadResumeProfile() async {
    final draft = ref.read(signUpFlowProvider);
    if (draft == null || !draft.resume || draft.userId == null) return;
    if (draft.firstName.isNotEmpty) return;
    state = const SignUpDetailsState(loading: true);
    try {
      final details = await ref
          .read(userRepositoryProvider)
          .fetchUser(draft.userId!);
      final user = details.user;
      if (user != null) ref.read(signUpFlowProvider.notifier).prefillFrom(user);
      state = const SignUpDetailsState();
    } on AppFailure catch (failure) {
      state = SignUpDetailsState(failure: failure);
    }
  }

  /// Validates, checks the email is free, stores the details in the flow.
  /// Returns true when the user may continue to role selection.
  Future<bool> submit({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final validation = validateSignUpDetails(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    if (!validation.isValid) {
      state = SignUpDetailsState(
        firstNameMissing: validation.firstNameMissing,
        lastNameMissing: validation.lastNameMissing,
        emailError: validation.emailError,
      );
      return false;
    }
    final flow = ref.read(signUpFlowProvider.notifier);
    final trimmedEmail = email.trim().toLowerCase();
    flow.setDetails(
      firstName: firstName,
      lastName: lastName,
      email: trimmedEmail,
    );
    if (trimmedEmail.isEmpty) {
      state = const SignUpDetailsState();
      return true;
    }
    state = const SignUpDetailsState(loading: true);
    try {
      final draft = ref.read(signUpFlowProvider)!;
      final taken = await _users.isEmailTaken(
        email: trimmedEmail,
        displayName: draft.displayName,
        userId: draft.resume ? draft.userId : null,
      );
      state = SignUpDetailsState(emailError: taken ? EmailError.taken : null);
      return !taken;
    } on AppFailure catch (failure) {
      state = SignUpDetailsState(failure: failure);
      return false;
    }
  }
}

final signUpDetailsViewModelProvider =
    NotifierProvider.autoDispose<SignUpDetailsViewModel, SignUpDetailsState>(
      SignUpDetailsViewModel.new,
    );
