import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Maps a failure to display text: the server's own message when it sent
/// one, otherwise [fallback] (a screen-specific message, e.g. "Could not
/// load venues.") or, if that's omitted, the app-wide generic fallback
/// (server-driven strings replace these later).
String failureMessage(AppLocalizations l10n, AppFailure failure, {String? fallback}) =>
    switch (failure) {
      ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
      UnauthorizedFailure(message: final m) when m != null && m.isNotEmpty => m,
      // Only the app-wide network message when the caller has no
      // screen-specific fallback of its own; a load-error screen's own
      // "could not load X" already covers an offline device just fine, and
      // keeping it avoids a second, differently-worded message appearing
      // depending on failure type.
      OfflineFailure() || TimeoutFailure() when fallback == null =>
        l10n.networkErrorMessage,
      _ => fallback ?? l10n.genericErrorMessage,
    };

/// Debug-only detail for a load failure, even for a failure type whose
/// `message` is null by design (`OfflineFailure`/`TimeoutFailure`) or whose
/// body didn't match `extractServerMessage`'s expected keys — otherwise a
/// failure with no message looks identical to one that was never caught at
/// all, which is indistinguishable from "nothing extra showed up" in a bug
/// report. Gate the call site on `kDebugMode`; this never belongs in a
/// release build (a `ParseFailure`/`UnknownFailure`'s message is a raw Dart
/// exception string, not something to show a user).
String? debugFailureDetail(Object? error) {
  if (error is ServerFailure) {
    final message = error.message;
    return 'HTTP ${error.statusCode}${message != null && message.isNotEmpty ? ': $message' : ''}';
  }
  if (error is AppFailure) {
    final message = error.message;
    return '${error.runtimeType}${message != null && message.isNotEmpty ? ': $message' : ''}';
  }
  return error?.toString();
}
