import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_palette.g.dart';

/// The native app's colours (`colors.xml`, day and night) on the theme.
class NativeColors extends ThemeExtension<NativeColors> {
  const NativeColors(this.palette);

  final NativePalette palette;

  @override
  NativeColors copyWith({NativePalette? palette}) =>
      NativeColors(palette ?? this.palette);

  // The palette switches with the brightness, so there is nothing to blend.
  @override
  NativeColors lerp(ThemeExtension<NativeColors>? other, double t) =>
      other is NativeColors && t >= 0.5 ? other : this;
}

extension NativeDesign on BuildContext {
  /// The native colour of the current brightness (`@color/...`).
  NativePalette get native =>
      Theme.of(this).extension<NativeColors>()?.palette ??
      (Theme.of(this).brightness == Brightness.dark
          ? NativePalette.dark
          : NativePalette.light);

  /// Native `sdp`/`ssp` units: the design was drawn at a 360 dp wide screen
  /// and scales with the screen's short side (`_16sdp` is 16 dp on a 360 dp
  /// phone). Kept between 0.8x and 1.35x so tablets and landscape stay sane.
  double sdp(num value) =>
      value *
      (MediaQuery.sizeOf(this).shortestSide / 360).clamp(0.8, 1.35).toDouble();
}

/// Native text: Inter in the weights the app ships (`res/font`).
abstract final class NativeText {
  static TextStyle light(double size, Color color) => _inter(300, size, color);
  static TextStyle regular(double size, Color color) =>
      _inter(400, size, color);
  static TextStyle medium(double size, Color color) => _inter(500, size, color);
  static TextStyle semibold(double size, Color color) =>
      _inter(600, size, color);
  static TextStyle bold(double size, Color color) => _inter(700, size, color);

  static TextStyle _inter(int weight, double size, Color color) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontSize: size,
    color: color,
  );
}
