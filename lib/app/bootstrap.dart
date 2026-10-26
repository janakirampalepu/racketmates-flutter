import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config_error_app.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/network/network_inspector.dart';
import 'package:racketmates/common/network/network_providers.dart';
import 'package:racketmates/common/network/ssl_pinning.dart';

/// Common startup for every flavor entrypoint. Fails fast on invalid config.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EnvironmentConfig.fromDefines(environment);
  final problems = config.problems();
  if (problems.isNotEmpty) {
    runApp(ConfigErrorApp(problems: problems));
    return;
  }
  if (environment != AppEnvironment.production) {
    enableNetworkInspector();
  }
  final appVersion = (await PackageInfo.fromPlatform()).version;
  final pins = pinsFor(sslPinning: environment.sslPinning);
  final pinnedAdapter = pins.isEmpty ? null : await createPinnedAdapter(pins);
  runApp(
    ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(config),
        appVersionProvider.overrideWithValue(appVersion),
        if (pinnedAdapter != null)
          apiHttpClientAdapterProvider.overrideWithValue(pinnedAdapter),
      ],
      child: const RacketmatesApp(),
    ),
  );
}
