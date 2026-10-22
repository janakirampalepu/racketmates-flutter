import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the app's store page.
abstract class StoreLauncher {
  Future<void> openStorePage();
}

/// Android: `market://details?id=<package>` with the Play web URL as fallback
/// (native `AppUpdateActivity`). iOS: the App Store product page.
/// The iOS Apple ID below is the PRODUCTION app; non-production TestFlight
/// builds have their own IDs (not wired, see CLAUDE.md open questions).
class UrlStoreLauncher implements StoreLauncher {
  static const productionAppleId = '6753332856';

  @override
  Future<void> openStorePage() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrl(
        Uri.parse('https://apps.apple.com/app/id$productionAppleId'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    final id = (await PackageInfo.fromPlatform()).packageName;
    final market = Uri.parse('market://details?id=$id');
    if (await canLaunchUrl(market)) {
      await launchUrl(market);
    } else {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$id'),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

final storeLauncherProvider = Provider<StoreLauncher>(
  (ref) => UrlStoreLauncher(),
);
