import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';

/// Shown instead of a blank screen when the build was made without its
/// compile-time configuration. Names the missing values only, never their
/// contents. Developer-facing, so it is not localized.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.problems, super.key});

  static const testId = 'config_error_screen';

  final List<String> problems;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
    home: Scaffold(
      body: SafeArea(
        child: TestId(
          testId,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  'This build is not configured',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Build with --dart-define-from-file=env/<environment>.json '
                '(see env/dev.example.json). Problems found:',
              ),
              const SizedBox(height: 12),
              for (final problem in problems) Text('• $problem'),
            ],
          ),
        ),
      ),
    ),
  );
}
