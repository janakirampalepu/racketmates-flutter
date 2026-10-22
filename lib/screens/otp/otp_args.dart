import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';

/// What the OTP screen needs from the phone-entry step (held in `pendingOtpArgsProvider`).
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

/// Hand-off from phone entry to the OTP screen. A provider instead of a route
/// `extra`: go_router drops `extra` when it rebuilds routes (e.g. on refresh).
class PendingOtpArgs extends Notifier<OtpArgs?> {
  @override
  OtpArgs? build() => null;

  // ignore: use_setters_to_change_properties
  void set(OtpArgs? value) => state = value;
}

final pendingOtpArgsProvider = NotifierProvider<PendingOtpArgs, OtpArgs?>(
  PendingOtpArgs.new,
);
