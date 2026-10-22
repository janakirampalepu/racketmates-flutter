import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/models/app_upgrade_check.dart';

/// Upgrade prompt decided at startup (null = none). A mandatory upgrade makes
/// the router lock navigation to the app-update screen.
class PendingUpgrade extends Notifier<AppUpgradeCheck?> {
  @override
  AppUpgradeCheck? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(AppUpgradeCheck? value) => state = value;
}

final pendingUpgradeProvider =
    NotifierProvider<PendingUpgrade, AppUpgradeCheck?>(PendingUpgrade.new);
