import 'package:racketmates/common/auth/models/app_upgrade_check.dart';

enum StartupDestination { appUpdate, home, welcome }

/// Whether to show the upgrade screen. Native rule (`AppController.getMetaDataInfo`):
/// `upgrade_required` and either the upgrade is `mandatory`, or the offered
/// `new_version_number` differs from the one already prompted (persisted).
bool shouldPromptUpgrade(
  AppUpgradeCheck? check, {
  String? lastPromptedVersion,
}) {
  if (check == null || check.upgradeRequired != true) return false;
  return check.isMandatory || check.newVersionNumber != lastPromptedVersion;
}

StartupDestination decideStartupDestination({
  required bool signedIn,
  required AppUpgradeCheck? upgrade,
  String? lastPromptedVersion,
}) {
  if (shouldPromptUpgrade(upgrade, lastPromptedVersion: lastPromptedVersion)) {
    return StartupDestination.appUpdate;
  }
  return signedIn ? StartupDestination.home : StartupDestination.welcome;
}
