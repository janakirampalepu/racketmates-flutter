import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Maps a failure to display text: the server's own message when it sent one,
/// otherwise localized fallbacks (server-driven strings replace these later).
String failureMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      OfflineFailure() || TimeoutFailure() => l10n.networkErrorMessage,
      ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
      UnauthorizedFailure(message: final m) when m != null && m.isNotEmpty => m,
      _ => l10n.genericErrorMessage,
    };
