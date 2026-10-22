import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';

class PhoneEntryState {
  const PhoneEntryState({
    required this.mode,
    this.country,
    this.input = '',
    this.validation,
    this.loading = false,
    this.failure,
  });

  final PhoneEntryMode mode;
  final Country? country;
  final String input;

  /// Set after a submit attempt (shown inline); null while editing is clean.
  final PhoneValidation? validation;
  final bool loading;
  final AppFailure? failure;

  bool get canSubmit =>
      country != null &&
      !loading &&
      validateNationalNumber(input, country!) == PhoneValidation.ok;

  /// The entered number split as the backend expects. Requires [country].
  PhoneNumberParts get parts => PhoneNumberParts(
    nationalNumber: digitsOnly(input),
    countryCode: country!.dialDigits,
    regionCode: country!.regionCode,
  );

  PhoneEntryState copyWith({
    PhoneEntryMode? mode,
    Country? country,
    String? input,
    PhoneValidation? Function()? validation,
    bool? loading,
    AppFailure? Function()? failure,
  }) => PhoneEntryState(
    mode: mode ?? this.mode,
    country: country ?? this.country,
    input: input ?? this.input,
    validation: validation != null ? validation() : this.validation,
    loading: loading ?? this.loading,
    failure: failure != null ? failure() : this.failure,
  );
}
