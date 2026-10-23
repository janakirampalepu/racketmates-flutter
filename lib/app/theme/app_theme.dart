import 'package:flutter/material.dart';
import 'package:racketmates/app/config/brand_config.dart';
import 'package:racketmates/app/theme/native_palette.g.dart';
import 'package:racketmates/app/theme/native_theme.dart';

/// Centralised Material 3 themes built from a [BrandConfig], carrying the
/// native app's palette (day and night) and font (Inter).
/// Widgets must read colors/typography from `Theme.of(context)` or
/// `context.native`.
abstract final class AppTheme {
  static ThemeData light(BrandConfig brand) => _build(brand, Brightness.light);

  static ThemeData dark(BrandConfig brand) => _build(brand, Brightness.dark);

  static ThemeData _build(BrandConfig brand, Brightness brightness) {
    final n = brightness == Brightness.dark
        ? NativePalette.dark
        : NativePalette.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brand.seedColor,
          brightness: brightness,
        ).copyWith(
          surface: n.windowBackgroundColor,
          onSurface: n.textPrimary,
          // Native night red (#FF0000) is too dark on dark cards; its softer red
          // (`no_clubs_color`) reads better there.
          error: brightness == Brightness.dark
              ? n.noClubsColor
              : n.statusColorsLightRed,
        );
    const radius = BorderRadius.all(Radius.circular(12));
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: n.windowBackgroundColor,
      extensions: [NativeColors(n)],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: n.windowBackgroundColor,
        foregroundColor: n.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: n.colorPrimary,
          foregroundColor: n.black,
          // Native shows a disabled button like an enabled one (same drawable);
          // only the label fades.
          disabledBackgroundColor: n.colorPrimary,
          disabledForegroundColor: n.black.withValues(alpha: 0.55),
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.14,
          ),
          elevation: 0,
        ),
      ),
      // Text buttons use the native dark olive (`main_tertiary`): the lime primary
      // does not have enough contrast on white.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: n.mainTertiary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: n.textPrimary,
          side: BorderSide(color: n.landingExploreBtnStroke),
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
