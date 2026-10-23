import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// Change the mobile number (native sign-up screens opened from the profile):
/// the new number is checked, a code is texted to it, and once the code is
/// right the number is changed on the account.
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _number = TextEditingController();
  final _code = TextEditingController();
  Country? _country;
  PhoneValidation? _validation;
  PhoneNumberParts? _parts;
  bool _taken = false;
  bool _same = false;
  bool _wrongCode = false;
  bool _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _number.dispose();
    _code.dispose();
    super.dispose();
  }

  PhoneVerificationRepository get _phone =>
      ref.read(phoneVerificationRepositoryProvider);

  Future<void> _pickCountry() async {
    final picked = await context.push<Country>(AppRoutes.countryPicker);
    if (picked == null) return;
    setState(() {
      _country = picked;
      _number.clear();
      _validation = null;
    });
  }

  /// Checks the number, then texts it a code.
  Future<void> _send() async {
    final country = _country;
    if (country == null || _busy) return;
    final validation = validateNationalNumber(_number.text, country);
    setState(() {
      _validation = validation;
      _taken = false;
      _same = false;
      _failure = null;
    });
    if (validation != PhoneValidation.ok) return;
    final parts = PhoneNumberParts(
      nationalNumber: digitsOnly(_number.text),
      countryCode: country.dialDigits,
      regionCode: country.regionCode,
    );
    final current = ref.read(userProfileProvider).value;
    if (parts.nationalNumber == digitsOnly(current?.mobileNumber ?? '') &&
        parts.regionCode ==
            (current?.country?.regionCode ?? parts.regionCode)) {
      setState(() => _same = true);
      return;
    }
    setState(() => _busy = true);
    try {
      final status = await _phone.validateMobileNumber(parts);
      if (status.userExist ?? false) {
        if (mounted) {
          setState(() {
            _busy = false;
            _taken = true;
          });
        }
        return;
      }
      await _phone.sendSmsCode(parts);
      if (mounted) {
        setState(() {
          _busy = false;
          _parts = parts;
        });
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  Future<void> _resend() async {
    final parts = _parts;
    if (parts == null || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await _phone.sendSmsCode(parts);
    } on AppFailure catch (failure) {
      if (mounted) _failure = failure;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Verifies the code, then changes the number.
  Future<void> _verify() async {
    final parts = _parts;
    final id = ref.read(userProfileProvider).value?.id;
    if (parts == null || id == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _wrongCode = false;
      _failure = null;
    });
    try {
      final result = await _phone.verifySmsCode(parts, _code.text.trim());
      if (result.valid != true) {
        if (mounted) {
          setState(() {
            _busy = false;
            _wrongCode = true;
          });
        }
        return;
      }
      await ref
          .read(userRepositoryProvider)
          .changeMobileNumber(
            id,
            changeMobileBody(
              nationalNumber: parts.nationalNumber,
              countryCode: parts.countryCode,
              regionCode: parts.regionCode,
            ),
          );
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.phoneChangeDone)));
      context.pop();
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    // Start with the country of the account, else the device's.
    final countries = ref.watch(countriesProvider).value;
    if (_country == null && countries != null) {
      final region =
          ref.read(userProfileProvider).value?.country?.regionCode ??
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      _country = defaultCountry(countries, region);
    }
    final country = _country;
    final codeStage = _parts != null;

    final numberError = switch (_validation) {
      PhoneValidation.required => l10n.phoneRequiredError,
      PhoneValidation.invalid => l10n.phoneInvalidError,
      _ =>
        _taken
            ? l10n.phoneChangeTaken
            : _same
            ? l10n.phoneChangeSame
            : null,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          ChangePhoneTestIds.title,
          child: Semantics(header: true, child: Text(l10n.phoneChangeTitle)),
        ),
      ),
      body: TestId(
        ChangePhoneTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!codeStage) ...[
              Text(l10n.phoneChangeHint),
              const SizedBox(height: 24),
              TestId(
                ChangePhoneTestIds.country,
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
                ChangePhoneTestIds.number,
                child: TextField(
                  controller: _number,
                  enabled: country != null && !_busy,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    if (country != null) NationalNumberFormatter(country),
                    LengthLimitingTextInputFormatter(32),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumberLabel,
                    prefixText: country == null ? null : '${country.dialCode} ',
                    errorText: numberError,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(height: 24),
              TestId(
                ChangePhoneTestIds.send,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: country == null || _busy ? null : _send,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.phoneChangeSend),
                ),
              ),
            ] else ...[
              Text(
                l10n.phoneChangeCodeHint(
                  '${country?.dialCode ?? ''} ${_number.text}',
                ),
              ),
              const SizedBox(height: 24),
              TestId(
                ChangePhoneTestIds.code,
                child: TextField(
                  controller: _code,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.phoneChangeCodeLabel,
                    errorText: _wrongCode ? l10n.phoneChangeCodeInvalid : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 24),
              TestId(
                ChangePhoneTestIds.verify,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _busy ? null : _verify,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.phoneChangeVerify),
                ),
              ),
              TestId(
                ChangePhoneTestIds.resend,
                child: TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(l10n.phoneChangeResend),
                ),
              ),
            ],
            if (_failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TestId(
                  ChangePhoneTestIds.error,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      failureMessage(l10n, _failure!),
                      style: TextStyle(color: errorColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
