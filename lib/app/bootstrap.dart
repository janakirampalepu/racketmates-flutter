import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/network/network_providers.dart';
import 'package:racketmates/common/network/ssl_pinning.dart';

final environmentConfigProvider = Provider<EnvironmentConfig>(
  (ref) => throw UnimplementedError('Override in bootstrap()'),
);

/// Common startup for every flavor entrypoint. Fails fast on invalid config.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EnvironmentConfig.fromDefines(environment)..validate();
  final pins = pinsFor(sslPinning: environment.sslPinning);
  final pinnedAdapter = pins.isEmpty ? null : await createPinnedAdapter(pins);
  runApp(
    ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(config),
        if (pinnedAdapter != null)
          apiHttpClientAdapterProvider.overrideWithValue(pinnedAdapter),
      ],
      child: const RacketmatesApp(),
    ),
  );
}
