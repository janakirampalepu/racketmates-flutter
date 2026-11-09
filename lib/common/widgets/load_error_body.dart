import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Load-failure content shared by list/detail screens: the server's own
/// message when the failure carries one, [fallbackText] otherwise, a
/// debug-build-only technical detail line (never shown in release — see
/// `debugFailureDetail`) when there's no server message, and a retry
/// button. Callers keep their own `Center`/`Padding` wrapper around this —
/// it's just the `Column` of text + button, so it drops into the same spot
/// a screen's old `Text(l10n.xxxLoadError)` sat in.
///
/// Every one of these screens used to render `error: (_, _) => ...` and
/// throw the actual failure away, so a genuine server error looked
/// identical to an offline device or a response-shape mismatch — this is
/// the fix for that, applied codebase-wide (see the "Choose a venue"
/// investigation this pattern comes from).
class LoadErrorBody extends StatelessWidget {
  const LoadErrorBody({
    required this.error,
    required this.fallbackText,
    this.retryId,
    this.onRetry,
    this.errorTestId,
    super.key,
  });

  /// The failure the screen caught (an `AppFailure`, or whatever an
  /// `AsyncValue.error` callback hands back — not every call site is
  /// guaranteed to be an `AppFailure`, so this stays untyped).
  final Object? error;

  /// Shown when [error] isn't an `AppFailure` with its own message, or is a
  /// technical one (`ParseFailure`/`UnknownFailure`) whose raw message
  /// isn't meant for a user.
  final String fallbackText;

  /// Omit both to render without a retry button (a few screens, e.g. a
  /// read-only error line with no retry action, have none).
  final String? retryId;
  final VoidCallback? onRetry;

  /// Wraps the message text in a `TestId`, for screens whose existing tests
  /// already look up a dedicated error element.
  final String? errorTestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = error;
    final text = failure is AppFailure
        ? failureMessage(l10n, failure, fallback: fallbackText)
        : fallbackText;
    final debugDetail = kDebugMode ? debugFailureDetail(failure) : null;
    final textWidget = Text(text, textAlign: TextAlign.center);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        errorTestId == null
            ? textWidget
            : TestId(errorTestId!, child: textWidget),
        if (debugDetail != null && debugDetail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              debugDetail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (retryId != null && onRetry != null)
          TestId(
            retryId!,
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ),
      ],
    );
  }
}
