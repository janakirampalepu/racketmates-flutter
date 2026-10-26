import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

/// The incident name (if any) the home banner was last dismissed for;
/// cleared when a different incident starts.
class _DismissedMaintenanceNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void dismiss(String name) => state = name;
}

final _dismissedMaintenanceProvider =
    NotifierProvider<_DismissedMaintenanceNotifier, String?>(
      _DismissedMaintenanceNotifier.new,
    );

/// Home's dismissible scheduled-maintenance notice (native
/// `scheduledDownLayout`/iOS `appScheduledDownTimeBanner`): informational
/// only, unlike the full-screen downtime gate the app also runs at startup.
class HomeDowntimeBanner extends ConsumerWidget {
  const HomeDowntimeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenance = ref.watch(scheduledMaintenanceProvider).value;
    final dismissed = ref.watch(_dismissedMaintenanceProvider);
    if (maintenance == null || maintenance.name == dismissed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final until = maintenance.scheduledUntil?.toLocal();
    final text = until == null
        ? maintenance.name
        : '${maintenance.name} (${MaterialLocalizations.of(context).formatMediumDate(until)})';
    return TestId(
      HomeTestIds.maintenanceBanner,
      child: Container(
        margin: EdgeInsets.fromLTRB(sdp(10), sdp(8), sdp(10), 0),
        padding: EdgeInsets.symmetric(horizontal: sdp(12), vertical: sdp(8)),
        decoration: BoxDecoration(
          color: n.colorPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(sdp(6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: NativeText.medium(sdp(12), n.textPrimary),
              ),
            ),
            TestId(
              HomeTestIds.maintenanceBannerDismiss,
              child: IconButton(
                tooltip: l10n.homeMaintenanceDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.close, size: sdp(18)),
                onPressed: () => ref
                    .read(_dismissedMaintenanceProvider.notifier)
                    .dismiss(maintenance.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
