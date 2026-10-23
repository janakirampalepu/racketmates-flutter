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
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/otp/otp_args.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_test_ids.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_view_model.dart';
import 'package:racketmates/screens/phone_entry/usecases/submit_phone_number.dart';

/// Mobile number entry shared by sign-in and sign-up (native `SignUpFragment`).
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({required this.mode, super.key});

  final PhoneEntryMode mode;

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PhoneEntryViewModel get _vm =>
      ref.read(phoneEntryViewModelProvider(widget.mode).notifier);

  Future<void> _pickCountry() async {
    final picked = await context.push<Country>(AppRoutes.countryPicker);
    if (picked == null) return;
    _vm.setCountry(picked);
    _controller.clear();
  }

  Future<void> _submit() async {
    final result = await _vm.submit();
    if (!mounted || result == null) return;
    await _handle(result);
  }

  Future<void> _handle(SubmitPhoneResult result) async {
    final state = ref.read(phoneEntryViewModelProvider(widget.mode));
    switch (result) {
      case CodeSent(mode: final mode):
        ref
            .read(pendingOtpArgsProvider.notifier)
            .set(
              OtpArgs(phone: state.parts, country: state.country!, mode: mode),
            );
        await context.push(AppRoutes.otp);
      case ModeMismatch(suggestedMode: final suggested):
        final accepted = await _confirmSwitch(suggested);
        if (accepted != true || !mounted) return;
        final next = await _vm.confirmModeSwitch(suggested);
        if (next != null && mounted) await _handle(next);
    }
  }

  Future<bool?> _confirmSwitch(PhoneEntryMode suggested) {
    final l10n = AppLocalizations.of(context);
    final toSignIn = suggested == PhoneEntryMode.signIn;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: TestId(
          PhoneEntryTestIds.dialogTitle,
          child: Text(
            toSignIn ? l10n.alreadyRegisteredTitle : l10n.notRegisteredTitle,
          ),
        ),
        content: TestId(
          PhoneEntryTestIds.dialogMessage,
          child: Text(
            toSignIn
                ? l10n.alreadyRegisteredMessage
                : l10n.notRegisteredMessage,
          ),
        ),
        actions: [
          TestId(
            PhoneEntryTestIds.dialogClose,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.closeAction),
            ),
          ),
          TestId(
            PhoneEntryTestIds.dialogContinue,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.continueAction),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(phoneEntryViewModelProvider(widget.mode));
    final country = state.country;
    final error = switch (state.validation) {
      PhoneValidation.required => ref.preMsg(
        MessageKeys.prePhoneRequired,
        l10n.phoneRequiredError,
      ),
      PhoneValidation.invalid => ref.preMsg(
        MessageKeys.prePhoneInvalid,
        l10n.phoneInvalidError,
      ),
      _ => state.failure == null ? null : failureMessage(l10n, state.failure!),
    };
    final n = context.native;
    final sdp = context.sdp;
    return NativeAuthScaffold(
      onBack: () => context.pop(),
      backId: PhoneEntryTestIds.backButton,
      body: TestId(
        PhoneEntryTestIds.root,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(16), sdp(80), sdp(16), 0),
              child: TestId(
                PhoneEntryTestIds.title,
                child: Text(
                  state.mode == PhoneEntryMode.signIn
                      ? ref.preMsg(
                          MessageKeys.preSignInTitle,
                          l10n.phoneEntrySignInTitle,
                        )
                      : ref.preMsg(
                          MessageKeys.preSignUpTitle,
                          l10n.phoneEntrySignUpTitle,
                        ),
                  textAlign: TextAlign.center,
                  style: NativeText.semibold(sdp(24), n.textPrimary),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(32), sdp(8), sdp(32), 0),
              child: TestId(
                PhoneEntryTestIds.description,
                child: Text(
                  l10n.phoneEntryDescription,
                  textAlign: TextAlign.center,
                  style: NativeText.regular(sdp(14), n.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(16), sdp(32), sdp(16), sdp(8)),
              child: Container(
                padding: EdgeInsets.all(sdp(4)),
                decoration: BoxDecoration(
                  color: n.signupViewColor,
                  borderRadius: BorderRadius.circular(sdp(10)),
                  border: Border.all(color: n.colorPrimary, width: sdp(1)),
                ),
                child: Row(
                  children: [
                    TestId(
                      PhoneEntryTestIds.countryButton,
                      child: InkWell(
                        onTap: country == null ? null : _pickCountry,
                        borderRadius: BorderRadius.circular(sdp(8)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Semantics(
                            button: true,
                            label: country == null
                                ? l10n.countryLabel
                                : '${country.name} ${country.dialCode}',
                            child: ExcludeSemantics(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: sdp(32),
                                    child: Center(
                                      child: Text(
                                        country?.flag ?? '',
                                        style: TextStyle(
                                          fontSize: sdp(24),
                                          color: n.scheduleDayColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: sdp(4),
                                      right: sdp(8),
                                    ),
                                    child: Text(
                                      country?.dialCode ?? '',
                                      style: NativeText.regular(
                                        sdp(12),
                                        n.textSecondary,
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
                    Container(
                      width: sdp(1),
                      height: sdp(32),
                      margin: EdgeInsets.symmetric(vertical: sdp(4)),
                      color: n.signupFieldViewColor,
                    ),
                    Expanded(
                      child: TestId(
                        PhoneEntryTestIds.numberField,
                        child: TextField(
                          controller: _controller,
                          enabled: country != null && !state.loading,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [
                            AutofillHints.telephoneNumberNational,
                          ],
                          inputFormatters: [
                            if (country != null)
                              NationalNumberFormatter(country),
                            LengthLimitingTextInputFormatter(32),
                          ],
                          style: NativeText.regular(sdp(12), n.textColor),
                          cursorColor: n.textColor,
                          decoration: InputDecoration(
                            hintText: l10n.mobileNumberLabel,
                            hintStyle: NativeText.regular(
                              sdp(12),
                              n.textSecondary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: sdp(12),
                              vertical: sdp(12),
                            ),
                          ),
                          onChanged: (v) {
                            _vm.setInput(v);
                            setState(() {});
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        icon: SvgIcon(
                          'ic_clear_mob',
                          size: sdp(23),
                          color: n.clearImgBg,
                        ),
                        onPressed: () {
                          _controller.clear();
                          _vm.setInput('');
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(sdp(12), sdp(4), sdp(12), 0),
                child: TestId(
                  PhoneEntryTestIds.errorText,
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
                              style: NativeText.regular(
                                sdp(12),
                                n.noClubsColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(16), sdp(4), sdp(16), 0),
              child: TestId(
                PhoneEntryTestIds.continueButton,
                child: FilledButton(
                  onPressed: state.canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(sdp(50)),
                    backgroundColor: n.colorPrimary,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .primary,
                    disabledForegroundColor: n.black.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sdp(12)),
                    ),
                    textStyle: NativeText.bold(sdp(14), n.black),
                  ),
                  child: state.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.continueAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
