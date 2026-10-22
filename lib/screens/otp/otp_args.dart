import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';

/// What the OTP screen needs from the phone-entry step (route `extra`).
class OtpArgs {
  const OtpArgs({
    required this.phone,
    required this.country,
    required this.mode,
  });

  final PhoneNumberParts phone;
  final Country country;
  final PhoneEntryMode mode;

  @override
  bool operator ==(Object other) =>
      other is OtpArgs &&
      other.phone.nationalNumber == phone.nationalNumber &&
      other.phone.countryCode == phone.countryCode &&
      other.phone.regionCode == phone.regionCode &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(
    phone.nationalNumber,
    phone.countryCode,
    phone.regionCode,
    mode,
  );
}
