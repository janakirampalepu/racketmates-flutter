import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A selectable country for phone entry. Data comes from the same list the
/// native iOS app bundles (`JsonCountryDetails.json`): name, flag, ISO region
/// code (sent as `region_code`), dial code, and the national-number mask.
/// Source quirks fixed in our copy: the iOS list has region codes `1` (United
/// States) and `91` (India); they are `US` and `IN` here (Android sends ISO
/// regions). Confirm with QA that the backend expects ISO regions.
class Country {
  const Country({
    required this.name,
    required this.flag,
    required this.regionCode,
    required this.dialCode,
    required this.pattern,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json['name'] as String,
    flag: json['flag'] as String,
    regionCode: json['code'] as String,
    dialCode: json['dialCode'] as String,
    pattern: json['pattern'] as String,
  );

  final String name;
  final String flag;

  /// ISO 3166-1 alpha-2, e.g. `US` (API `region_code`).
  final String regionCode;

  /// With plus sign, e.g. `+1`.
  final String dialCode;

  /// Mask for the national number, `#` = digit (e.g. `### ### ####`).
  final String pattern;

  /// Dial code digits only (API `country_code`), e.g. `1`.
  String get dialDigits => dialCode.replaceAll(RegExp(r'\D'), '');

  /// Digits the national number needs before we call the server. Uses the
  /// mask's digit count with a floor of 6 (many native masks are a bare `#`
  /// placeholder); the server stays authoritative.
  int get minDigits {
    final masked = '#'.allMatches(pattern).length;
    return masked < 6 ? 6 : masked;
  }

  static const maxDigits = 15;
}

Future<List<Country>> loadCountries(AssetBundle bundle) async {
  // cache: false -- the parsed list is held by `countriesProvider`; not caching
  // the raw string also keeps tests from sharing a future across fake-async zones.
  final raw = jsonDecode(
    await bundle.loadString('assets/data/countries.json', cache: false),
  ) as List<dynamic>;
  return [
    for (final item in raw) Country.fromJson(item as Map<String, dynamic>),
  ];
}

final countriesProvider = FutureProvider<List<Country>>(
  (ref) => loadCountries(rootBundle),
);

/// Picks the country matching a device region (e.g. `US`), else the first.
Country defaultCountry(List<Country> countries, String? deviceRegion) =>
    countries.firstWhere(
      (c) => c.regionCode == deviceRegion,
      orElse: () => countries.first,
    );
