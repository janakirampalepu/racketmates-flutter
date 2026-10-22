import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';

const _us = Country(
  name: 'United States',
  flag: '🇺🇸',
  regionCode: 'US',
  dialCode: '+1',
  pattern: '(###) ### - ####',
);
const _bare = Country(
  name: 'Germany',
  flag: '🇩🇪',
  regionCode: 'DE',
  dialCode: '+49',
  pattern: '#',
);

void main() {
  test('applyMask formats and keeps extra digits', () {
    expect(applyMask('5551234567', _us.pattern), '(555) 123 - 4567');
    expect(applyMask('555', _us.pattern), '(555');
    expect(applyMask('55512345678', _us.pattern), '(555) 123 - 45678');
  });

  test('formatter keeps digits only and caps at 15', () {
    final f = NationalNumberFormatter(_bare);
    final out = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '12-34 56 789 012 345 6789'),
    );
    expect(digitsOnly(out.text).length, 15);
  });

  test('validation: required / invalid / ok with a floor of 6 digits', () {
    expect(validateNationalNumber('', _us), PhoneValidation.required);
    expect(validateNationalNumber('555123', _us), PhoneValidation.invalid);
    expect(validateNationalNumber('(555) 123 - 4567', _us), PhoneValidation.ok);
    expect(validateNationalNumber('123456', _bare), PhoneValidation.ok);
    expect(validateNationalNumber('12345', _bare), PhoneValidation.invalid);
  });

  test('country dial digits and min digits', () {
    expect(_us.dialDigits, '1');
    expect(_us.minDigits, 10);
    expect(_bare.minDigits, 6);
  });

  test('bundled country list loads with ISO region codes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final countries = await loadCountries(rootBundle);
    expect(countries.length, greaterThan(200));
    expect(
      countries.every((c) => RegExp(r'^[A-Z]{2}$').hasMatch(c.regionCode)),
      isTrue,
    );
    expect(countries.firstWhere((c) => c.regionCode == 'US').dialDigits, '1');
    expect(countries.firstWhere((c) => c.regionCode == 'IN').dialDigits, '91');
    expect(defaultCountry(countries, 'ZZ'), countries.first);
  });
}
