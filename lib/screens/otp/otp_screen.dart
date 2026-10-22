import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/failure_message.dart';
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

    final number =
        '${widget.args.country.dialCode} ${widget.args.phone.nationalNumber}';
    final error = state.invalidCode
        ? l10n.otpInvalidCodeError
        : (state.failure == null ? null : failureMessage(l10n, state.failure!));

    return _EventListener(
      stream: vm.events,
      onEvent: (event) {
        if (event is OtpSignUpNeeded) {
          context.push(AppRoutes.signUp, extra: event.resume);
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        body: TestId(
          OtpTestIds.root,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TestId(
                  OtpTestIds.title,
                  child: Text(
                    l10n.otpTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                TestId(
                  OtpTestIds.description,
                  child: Text(l10n.otpDescription(number)),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TestId(
                    OtpTestIds.change,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.otpChangeNumber),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TestId(
                  OtpTestIds.inputField,
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !state.loading,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(letterSpacing: 8),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(OtpState.codeLength),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.otpCodeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: vm.setCode,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TestId(
                      OtpTestIds.errorMessage,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (state.loading)
                  const Center(child: CircularProgressIndicator())
                else
                  TestId(
                    OtpTestIds.resendButton,
                    child: TextButton(
                      onPressed: state.canResend ? vm.resend : null,
                      child: Text(
                        state.canResend
                            ? l10n.otpResendAction
                            : l10n.otpResendIn(state.secondsLeft),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
