import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/kid_edit/kid_edit_screen.dart';

import '../../support/fakes.dart';

/// A fixed signed-in session (user id 7), so `userProfileProvider` fetches
/// through the fake repository below rather than going through sign-in.
class _FixedSessionController extends SessionController {
  @override
  SessionState build() =>
      const SignedIn(SessionToken(user: SessionTokenUser(id: 7)));
}

Widget _host(FakeUserRepository users) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(_FixedSessionController.new),
    userRepositoryProvider.overrideWithValue(users),
  ],
  child: const MaterialApp(
    home: KidEditScreen(),
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

void main() {
  group('KidEditScreen', () {
    testWidgets('a server failure message replaces the generic text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final users = FakeUserRepository()
        ..failure = const ServerFailure(500, 'Could not load this kid.');
      await tester.pumpWidget(_host(users));
      await tester.pumpAndSettle();
      expect(find.text('Could not load this kid.'), findsOneWidget);
      handle.dispose();
    });
  });
}
