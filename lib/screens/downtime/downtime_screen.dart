import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/startup/app_gate.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/downtime/downtime_test_ids.dart';
import 'package:racketmates/screens/splash/splash_view_model.dart';

/// The service is down or in maintenance (native `CompleteDowntimeActivity`):
/// the incident's title and text, and when a maintenance window ends. The app
/// restarts its startup as soon as the incident is gone: when the user taps
/// "Check again" or the app is resumed.
class DowntimeScreen extends ConsumerStatefulWidget {
  const DowntimeScreen({super.key});

  @override
  ConsumerState<DowntimeScreen> createState() => _DowntimeScreenState();
}

class _DowntimeScreenState extends ConsumerState<DowntimeScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    await ref.read(appGateCheckerProvider).checkDowntime();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final gate = ref.watch(appGateProvider);

    // The incident is over: run startup again (session, metadata, route).
    ref.listen(appGateProvider, (_, next) {
      if (next == null) {
        ref.invalidate(splashViewModelProvider);
        context.go(AppRoutes.splash);
      }
    });

    final incident = gate is Downtime ? gate.incident : null;
    final until = incident?.scheduledUntil?.toLocal();
    final back = until == null
        ? ''
        : ' ${l10n.downtimeBackBefore(DateFormat.jm(locale).format(until), DateFormat.yMMMd(locale).format(until))}';
    final title = (incident?.name ?? '').isEmpty
        ? l10n.downtimeFallbackTitle
        : incident!.name;
    final message = (incident?.message ?? '').isEmpty
        ? l10n.downtimeFallbackMessage
        : incident!.message;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: TestId(
          DowntimeTestIds.root,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TestId(
                        DowntimeTestIds.title,
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TestId(
                        DowntimeTestIds.message,
                        child: Text('$message$back'),
                      ),
                      const SizedBox(height: 24),
                      TestId(
                        DowntimeTestIds.checkAgain,
                        child: FilledButton(
                          onPressed: _checking ? null : _checkAgain,
                          child: _checking
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.downtimeCheckAgain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
