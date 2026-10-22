import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_state.dart';
import 'package:racketmates/screens/phone_entry/usecases/submit_phone_number.dart';

final submitPhoneNumberUseCaseProvider = Provider<SubmitPhoneNumberUseCase>(
  (ref) =>
      SubmitPhoneNumberUseCase(ref.watch(phoneVerificationRepositoryProvider)),
);

class PhoneEntryViewModel extends Notifier<PhoneEntryState> {
  PhoneEntryViewModel(this._initialMode);

  final PhoneEntryMode _initialMode;

  static Country _deviceCountry(List<Country> countries) => defaultCountry(
    countries,
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );

  @override
  PhoneEntryState build() {
    // The country list loads asynchronously: pick the device's country when it
    // arrives, without resetting anything the user already typed.
    ref.listen(countriesProvider, (_, next) {
      final countries = next.value;
      if (countries != null && state.country == null) {
        state = state.copyWith(country: _deviceCountry(countries));
      }
    });
    final loaded = ref.read(countriesProvider).value;
    return PhoneEntryState(
      mode: _initialMode,
      country: loaded == null ? null : _deviceCountry(loaded),
    );
  }

  void setCountry(Country country) => state = state.copyWith(
    country: country,
    input: digitsOnly(state.input),
    validation: () => null,
  );

  void setInput(String value) => state = state.copyWith(
    input: value,
    validation: () => null,
    failure: () => null,
  );

  void setMode(PhoneEntryMode mode) => state = state.copyWith(mode: mode);

  /// Validates locally, then asks the backend. Returns the outcome for the
  /// screen to act on (navigate / show the mismatch dialog), or null when
  /// validation failed or the request failed (state carries the reason).
  Future<SubmitPhoneResult?> submit() =>
      _run((useCase, parts) => useCase(parts, state.mode), validate: true);

  /// User accepted the mode-switch dialog.
  Future<SubmitPhoneResult?> confirmModeSwitch(PhoneEntryMode mode) {
    setMode(mode);
    return _run((useCase, parts) => useCase.sendCode(parts, mode));
  }

  Future<SubmitPhoneResult?> _run(
    Future<SubmitPhoneResult> Function(
      SubmitPhoneNumberUseCase useCase,
      PhoneNumberParts parts,
    )
    action, {
    bool validate = false,
  }) async {
    final country = state.country;
    if (country == null) return null;
    final parts = state.parts;
    if (validate) {
      final result = validateNationalNumber(state.input, country);
      if (result != PhoneValidation.ok) {
        state = state.copyWith(validation: () => result);
        return null;
      }
    }
    state = state.copyWith(loading: true, failure: () => null);
    try {
      final result = await action(
        ref.read(submitPhoneNumberUseCaseProvider),
        parts,
      );
      state = state.copyWith(loading: false);
      return result;
    } on AppFailure catch (failure) {
      state = state.copyWith(loading: false, failure: () => failure);
      return null;
    }
  }
}

/// Family keyed by the entry mode the screen was opened with.
final phoneEntryViewModelProvider = NotifierProvider.autoDispose
    .family<PhoneEntryViewModel, PhoneEntryState, PhoneEntryMode>(
      PhoneEntryViewModel.new,
    );
