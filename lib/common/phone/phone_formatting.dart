import 'package:flutter/services.dart';
import 'package:racketmates/common/phone/country.dart';

String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Applies a `#` mask to digits; extra digits are appended unmasked.
String applyMask(String digits, String pattern) {
  final out = StringBuffer();
  var i = 0;
  for (final ch in pattern.split('')) {
    if (i >= digits.length) break;
    if (ch == '#') {
      out.write(digits[i++]);
    } else {
      out.write(ch);
    }
  }
  if (i < digits.length) out.write(digits.substring(i));
  return out.toString();
}

/// Formats the national number as the user types, keeping the cursor at the end.
class NationalNumberFormatter extends TextInputFormatter {
  NationalNumberFormatter(this.country);

  final Country country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOnly(newValue.text);
    if (digits.length > Country.maxDigits) {
      digits = digits.substring(0, Country.maxDigits);
    }
    final text = applyMask(digits, country.pattern);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

enum PhoneValidation { ok, required, invalid }

/// Client-side check before calling the server (which remains authoritative).
PhoneValidation validateNationalNumber(String input, Country country) {
  final digits = digitsOnly(input);
  if (digits.isEmpty) return PhoneValidation.required;
  if (digits.length < country.minDigits || digits.length > Country.maxDigits) {
    return PhoneValidation.invalid;
  }
  return PhoneValidation.ok;
}
