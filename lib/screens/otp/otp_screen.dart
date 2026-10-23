import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/otp/otp_args.dart';
import 'package:racketmates/screens/otp/otp_state.dart';
import 'package:racketmates/screens/otp/otp_test_ids.dart';
import 'package:racketmates/screens/otp/otp_view_model.dart';

/// 6-digit SMS code entry with a 60 s resend timer (native `OtpFragment`).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.args, super.key});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = otpViewModelProvider(widget.args);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);

    ref.listen(provider.select((s) => s.code), (_, code) {
      if (code.isEmpty && _controller.text.isNotEmpty) _controller.clear();
    });

    final n = context.native;
    final sdp = context.sdp;
    final number =
        '${widget.args.country.dialCode} ${widget.args.phone.nationalNumber}';
    final error = state.invalidCode
        ? ref.preMsg(MessageKeys.preCodeInvalid, l10n.otpInvalidCodeError)
        : (state.failure == null ? null : failureMessage(l10n, state.failure!));

    return _EventListener(
      stream: vm.events,
      onEvent: (event) {
        if (event is OtpSignUpNeeded) {
          context.push(AppRoutes.signUp);
        }
      },
      child: NativeAuthScaffold(
        onBack: () => context.pop(),
        body: TestId(
          OtpTestIds.root,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(sdp(16), sdp(80), sdp(16), 0),
                child: TestId(
                  OtpTestIds.title,
                  child: Text(
                    ref.preMsg(MessageKeys.preCodeTitle, l10n.otpTitle),
                    textAlign: TextAlign.center,
                    style: NativeText.semibold(sdp(24), n.textPrimary),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(sdp(30), sdp(8), sdp(32), 0),
                child: TestId(
                  OtpTestIds.description,
                  child: Text(
                    l10n.otpDescriptionShort,
                    textAlign: TextAlign.center,
                    style: NativeText.regular(
                      sdp(14),
                      n.textSecondary,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TestId(
                    OtpTestIds.mobileNumber,
                    child: Text(
                      number,
                      style: NativeText.semibold(sdp(14), n.textPrimary),
                    ),
                  ),
                  SizedBox(width: sdp(6)),
                  TestId(
                    OtpTestIds.change,
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        child: Center(
                          child: Text(
                            l10n.otpChangeNumber,
                            style: NativeText.bold(sdp(14), n.iconPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sdp(34) - 24),
              _OtpBoxes(
                controller: _controller,
                enabled: !state.loading,
                label: l10n.otpCodeLabel,
                onChanged: vm.setCode,
              ),
              if (error != null)
                Center(
                  child: SizedBox(
                    width: sdp(276),
                    child: Padding(
                      padding: EdgeInsets.only(top: sdp(4), left: sdp(2)),
                      child: TestId(
                        OtpTestIds.errorMessage,
                        child: Semantics(
                          liveRegion: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SvgIcon('ic_error_info'),
                              SizedBox(width: sdp(4)),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    error,
                                    style: NativeText.bold(
                                      sdp(10),
                                      n.statusColorsLightRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: sdp(24)),
              if (state.loading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: TestId(
                    OtpTestIds.resendButton,
                    child: InkWell(
                      onTap: state.canResend ? vm.resend : null,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: EdgeInsets.all(sdp(10)),
                          child: Text(
                            state.canResend
                                ? l10n.otpResendAction
                                : l10n.otpResendIn(state.secondsLeft),
                            style: NativeText.bold(
                              sdp(14),
                              state.canResend
                                  ? n.mainTertiary
                                  : n.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six code boxes (native `OtpView`: 40 wide, 38 tall, 7 apart, field colours
/// `otp_boxes_bg` / `otp_boxes_stroke`). A transparent text field on top
/// takes the typing, so paste, autofill and the keyboard behave normally.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final boxWidth = sdp(40);
    final gap = sdp(7);
    final width =
        OtpState.codeLength * boxWidth + (OtpState.codeLength - 1) * gap;
    return Center(
      child: SizedBox(
        width: width,
        height: sdp(48) < 48 ? 48 : sdp(48),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final digits = value.text;
            return Stack(
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < OtpState.codeLength; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Container(
                          width: boxWidth,
                          height: sdp(38),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: n.otpBoxesBg,
                            borderRadius: BorderRadius.circular(sdp(10)),
                            border: Border.all(
                              color: i == digits.length && enabled
                                  ? n.textColor
                                  : n.otpBoxesStroke,
                              width: sdp(1),
                            ),
                          ),
                          child: Text(
                            i < digits.length ? digits[i] : '',
                            style: NativeText.regular(sdp(16), n.textcolor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TestId(
                  OtpTestIds.inputField,
                  child: Semantics(
                    label: label,
                    textField: true,
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      showCursor: false,
                      enableInteractiveSelection: false,
                      style: const TextStyle(color: Colors.transparent),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(OtpState.codeLength),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        counterText: '',
                        fillColor: Colors.transparent,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bridges a one-shot event stream to a callback for the widget's lifetime.
class _EventListener extends StatefulWidget {
  const _EventListener({
    required this.stream,
    required this.onEvent,
    required this.child,
  });

  final Stream<OtpEvent> stream;
  final void Function(OtpEvent event) onEvent;
  final Widget child;

  @override
  State<_EventListener> createState() => _EventListenerState();
}

class _EventListenerState extends State<_EventListener> {
  StreamSubscription<OtpEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen(widget.onEvent);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
