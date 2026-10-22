import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';

class CreateAccountState {
  const CreateAccountState({
    this.loading = false,
    this.failure,
    this.done = false,
  });

  final bool loading;
  final AppFailure? failure;

  /// Account created/updated and the session is in place.
  final bool done;
}

/// Submits the finished draft. Used by every screen that can end the data
/// collection (player/coach sports, kids list).
class CreateAccountController extends Notifier<CreateAccountState> {
  @override
  CreateAccountState build() => const CreateAccountState();

  Future<bool> submit() async {
    final draft = ref.read(signUpFlowProvider);
    if (draft == null || state.loading) return false;
    state = const CreateAccountState(loading: true);
    try {
      final created = await ref.read(createAccountUseCaseProvider)(draft);
      final token = created.token;
      if (token != null) {
        await ref.read(sessionControllerProvider.notifier).signedIn(token);
      }
      state = const CreateAccountState(done: true);
      return true;
    } on AppFailure catch (failure) {
      state = CreateAccountState(failure: failure);
      return false;
    }
  }

  void clearError() => state = const CreateAccountState();
}

final createAccountControllerProvider =
    NotifierProvider<CreateAccountController, CreateAccountState>(
      CreateAccountController.new,
    );
