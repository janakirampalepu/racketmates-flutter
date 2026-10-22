// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingLabel => 'Loading';

  @override
  String get welcomePlaceholder => 'Welcome';

  @override
  String get homePlaceholder => 'Home';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get appUpdateTitle => 'A new version is available';

  @override
  String get appUpdateAction => 'Update';

  @override
  String get appUpdateLaterAction => 'Later';
}
