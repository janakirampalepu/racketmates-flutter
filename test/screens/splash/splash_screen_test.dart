import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/app/config/brand_config.dart';
import 'package:racketmates/app/theme/app_theme.dart';
import 'package:racketmates/screens/splash/splash_test_ids.dart';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('splash exposes test ids and passes a11y guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const ProviderScope(child: RacketmatesApp()));
      await tester.pump();

      expect(find.bySemanticsIdentifier(SplashTestIds.root), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(SplashTestIds.progress),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  test('light and dark themes are Material 3 with the brand seed', () {
    const brand = BrandConfig.racketmates;
    expect(AppTheme.light(brand).useMaterial3, isTrue);
    expect(AppTheme.light(brand).brightness, Brightness.light);
    expect(AppTheme.dark(brand).brightness, Brightness.dark);
  });
}
