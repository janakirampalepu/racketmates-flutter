import 'dart:ui';

/// Typed brand configuration. Selected at build time; separate from
/// environment configuration. Add a brand by adding a const instance and
/// selecting it from the flavor entrypoint; screens must not branch on brand.
class BrandConfig {
  const BrandConfig({
    required this.id,
    required this.displayName,
    required this.seedColor,
  });

  final String id;
  final String displayName;

  /// Seed for the Material 3 color scheme. The full native palette
  /// (`colors.xml` / `config_colors.xml`, day and night) is ported per
  /// screen as design tokens in `app/theme/`.
  final Color seedColor;

  /// Racketmates primary (`colorPrimary` #C1D72E in the Android app).
  static const racketmates = BrandConfig(
    id: 'racketmates',
    displayName: 'Racketmates',
    seedColor: Color(0xFFC1D72E),
  );
}
