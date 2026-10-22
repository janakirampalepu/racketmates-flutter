import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/l10n/app_localizations.dart';

String sportLabel(AppLocalizations l10n, SportKey sport) => switch (sport) {
  SportKey.badminton => l10n.sportBadminton,
  SportKey.padel => l10n.sportPadel,
  SportKey.pickleball => l10n.sportPickleball,
  SportKey.tennis => l10n.sportTennis,
};
