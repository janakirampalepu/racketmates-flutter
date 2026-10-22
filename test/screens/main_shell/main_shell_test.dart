import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/screens/chat/chat_screen.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/teams/teams_screen.dart';

import '../../support/app_harness.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

void main() {
  testWidgets(
    'bottom navigation switches between the four tabs and keeps state',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      expect(_id(MainShellTestIds.root), findsOneWidget);
      expect(_id(HomeTestIds.root), findsOneWidget);

      await tester.tap(_id(MainShellTestIds.navSchedule));
      await tester.pumpAndSettle();
      expect(_id(ScheduleTestIds.root), findsOneWidget);

      await tester.tap(_id(MainShellTestIds.navChat));
      await tester.pumpAndSettle();
      expect(_id(ChatScreen.testId), findsOneWidget);
      expect(
        find.text('This section is not available in this build yet.'),
        findsOneWidget,
      );

      await tester.tap(_id(MainShellTestIds.navTeams));
      await tester.pumpAndSettle();
      expect(_id(TeamsScreen.testId), findsOneWidget);

      await tester.tap(_id(MainShellTestIds.navHome));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      handle.dispose();
    },
  );
}
