import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:racketmates/app/config/app_environment.dart';

/// Environments that sell subscriptions (native
/// `AppController.isBillingSupportedAppEnvironment`: production, hotfix, qa
/// and staging); the others have no store products.
bool billingSupportedIn(AppEnvironment environment) => switch (environment) {
  AppEnvironment.production ||
  AppEnvironment.hotfix ||
  AppEnvironment.qa ||
  AppEnvironment.staging => true,
  _ => false,
};

/// Store product ids of the monthly and yearly plan, as configured in the
/// native apps. They are NOT the same on both stores: Android uses
/// `<env>.monthly|yearly` (`production`, `hotfix`, `qa`, `staging`); iOS reads
/// `SUBSCRIPTION_IDS` from its xcconfig (`monthly,yearly` for production,
/// `qamonthly,qayearly` for qa and hotfix, `stagingmonthly,stagingyearly` for
/// the Feature1 build that maps to staging here). `SUBSCRIPTION_IDS` (comma
/// separated, monthly first) overrides both.
({String monthly, String yearly}) productIdsFor(
  AppEnvironment environment,
  TargetPlatform platform, {
  String override = const String.fromEnvironment('SUBSCRIPTION_IDS'),
}) {
  final parts = override
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.length == 2) return (monthly: parts[0], yearly: parts[1]);
  if (platform == TargetPlatform.iOS) {
    return switch (environment) {
      AppEnvironment.production => (monthly: 'monthly', yearly: 'yearly'),
      AppEnvironment.staging => (
        monthly: 'stagingmonthly',
        yearly: 'stagingyearly',
      ),
      _ => (monthly: 'qamonthly', yearly: 'qayearly'),
    };
  }
  return switch (environment) {
    AppEnvironment.production => (
      monthly: 'production.monthly',
      yearly: 'production.yearly',
    ),
    AppEnvironment.hotfix => (
      monthly: 'hotfix.monthly',
      yearly: 'hotfix.yearly',
    ),
    AppEnvironment.staging => (
      monthly: 'staging.monthly',
      yearly: 'staging.yearly',
    ),
    _ => (monthly: 'qa.monthly', yearly: 'qa.yearly'),
  };
}
