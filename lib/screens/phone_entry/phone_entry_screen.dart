import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
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
        await context.push(
          AppRoutes.otp,
          extra: OtpArgs(
            phone: state.parts,
            country: state.country!,
            mode: mode,
          ),
        );
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
      PhoneValidation.required => l10n.phoneRequiredError,
      PhoneValidation.invalid => l10n.phoneInvalidError,
      _ => state.failure == null ? null : failureMessage(l10n, state.failure!),
    };
    return Scaffold(
      appBar: AppBar(
        leading: TestId(
          PhoneEntryTestIds.backButton,
          child: BackButton(onPressed: () => context.pop()),
        ),
      ),
      body: TestId(
        PhoneEntryTestIds.root,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TestId(
                PhoneEntryTestIds.title,
                child: Text(
                  state.mode == PhoneEntryMode.signIn
                      ? l10n.phoneEntrySignInTitle
                      : l10n.phoneEntrySignUpTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              TestId(
                PhoneEntryTestIds.description,
                child: Text(l10n.phoneEntryDescription),
              ),
              const SizedBox(height: 24),
              TestId(
                PhoneEntryTestIds.countryButton,
                child: OutlinedButton(
                  onPressed: country == null ? null : _pickCountry,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    country == null
                        ? l10n.countryLabel
                        : '${country.flag}  ${country.name}  ${country.dialCode}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TestId(
                PhoneEntryTestIds.numberField,
                child: TextField(
                  controller: _controller,
                  enabled: country != null && !state.loading,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    if (country != null) NationalNumberFormatter(country),
                    LengthLimitingTextInputFormatter(32),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumberLabel,
                    prefixText: country == null ? null : '${country.dialCode} ',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _vm.setInput,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 24),
              TestId(
                PhoneEntryTestIds.continueButton,
                child: FilledButton(
                  onPressed: state.canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: state.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.continueAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
