import 'package:flutter/material.dart';
import 'package:racketmates/app/config/brand_config.dart';

/// Centralised Material 3 themes built from a [BrandConfig].
/// Widgets must read colors/typography from `Theme.of(context)`.
abstract final class AppTheme {
  static ThemeData light(BrandConfig brand) => _build(brand, Brightness.light);

  static ThemeData dark(BrandConfig brand) => _build(brand, Brightness.dark);

  static ThemeData _build(BrandConfig brand, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand.seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
