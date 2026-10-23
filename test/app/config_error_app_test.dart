import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config_error_app.dart';

void main() {
  testWidgets('a build without configuration says what is missing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const ConfigErrorApp(
        problems: ['API_VERSION is missing', 'OAUTH_CLIENT_ID is missing'],
      ),
    );
    expect(find.bySemanticsIdentifier(ConfigErrorApp.testId), findsOneWidget);
    expect(find.text('This build is not configured'), findsOneWidget);
    expect(find.text('• API_VERSION is missing'), findsOneWidget);
    expect(find.text('• OAUTH_CLIENT_ID is missing'), findsOneWidget);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
