import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/screens/otp/otp_args.dart';
import 'package:racketmates/screens/otp/otp_state.dart';
import 'package:racketmates/screens/otp/usecases/verify_otp.dart';

/// Resend cool-down (native `OTP_TIMER = 60 s`).
const otpResendSeconds = 60;

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>(
  (ref) => VerifyOtpUseCase(ref.watch(phoneVerificationRepositoryProvider)),
);

/// One-shot navigation requests the screen listens to.
sealed class OtpEvent {
  const OtpEvent();
}

class OtpSignUpNeeded extends OtpEvent {
  const OtpSignUpNeeded({required this.resume});

  final bool resume;
}

class OtpViewModel extends Notifier<OtpState> {
  OtpViewModel(this.args);

  final OtpArgs args;
  Timer? _timer;
  final _events = StreamController<OtpEvent>.broadcast();

  Stream<OtpEvent> get events => _events.stream;

  @override
  OtpState build() {
    ref.onDispose(() {
      _timer?.cancel();
      unawaited(_events.close());
    });
    _startTimer();
    return const OtpState(secondsLeft: otpResendSeconds);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.secondsLeft - 1;
      state = state.copyWith(secondsLeft: left < 0 ? 0 : left);
      if (left <= 0) timer.cancel();
    });
  }

  void setCode(String code) {
    state = state.copyWith(code: code, invalidCode: false, failure: () => null);
    if (code.length == OtpState.codeLength) unawaited(verify());
  }

  Future<void> verify() async {
    if (state.loading || state.code.length != OtpState.codeLength) return;
    state = state.copyWith(loading: true, failure: () => null);
    try {
      final outcome = await ref.read(verifyOtpUseCaseProvider)(
        args.phone,
        state.code,
      );
      switch (outcome) {
        case OtpSignedIn(token: final token):
          // The router redirects to home once the session is signed in.
          await ref.read(sessionControllerProvider.notifier).signedIn(token);
          state = state.copyWith(loading: false);
        case OtpSignUpRequired(
          resume: final resume,
          verificationCode: final verificationCode,
          token: final token,
        ):
          final timezone = await ref.read(deviceTimezoneProvider.future);
          // Start the flow BEFORE persisting a resumed session so the router
          // keeps the user in the sign-up screens.
          ref
              .read(signUpFlowProvider.notifier)
              .start(
                phone: args.phone,
                verificationCode: verificationCode,
                resume: resume,
                userId: token?.user?.id,
                timezone: timezone,
              );
          if (token != null) {
            await ref.read(sessionControllerProvider.notifier).signedIn(token);
          }
          state = state.copyWith(loading: false, code: '');
          _events.add(OtpSignUpNeeded(resume: resume));
        case OtpInvalidCode():
          state = state.copyWith(loading: false, invalidCode: true, code: '');
      }
    } on AppFailure catch (failure) {
      state = state.copyWith(loading: false, failure: () => failure, code: '');
    }
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    state = state.copyWith(
      secondsLeft: otpResendSeconds,
      code: '',
      invalidCode: false,
      failure: () => null,
    );
    _startTimer();
    try {
      await ref
          .read(phoneVerificationRepositoryProvider)
          .sendSmsCode(args.phone);
    } on AppFailure catch (failure) {
      state = state.copyWith(failure: () => failure);
    }
  }
}

final otpViewModelProvider = NotifierProvider.autoDispose
    .family<OtpViewModel, OtpState, OtpArgs>(OtpViewModel.new);
