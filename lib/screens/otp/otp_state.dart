import 'package:racketmates/common/errors/app_failure.dart';

class OtpState {
  const OtpState({
    required this.secondsLeft,
    this.code = '',
    this.loading = false,
    this.invalidCode = false,
    this.failure,
  });

  static const codeLength = 6;

  final int secondsLeft;
  final String code;
  final bool loading;
  final bool invalidCode;
  final AppFailure? failure;

  bool get canResend => secondsLeft == 0 && !loading;

  OtpState copyWith({
    int? secondsLeft,
    String? code,
    bool? loading,
    bool? invalidCode,
    AppFailure? Function()? failure,
  }) => OtpState(
    secondsLeft: secondsLeft ?? this.secondsLeft,
    code: code ?? this.code,
    loading: loading ?? this.loading,
    invalidCode: invalidCode ?? this.invalidCode,
    failure: failure != null ? failure() : this.failure,
  );
}
