import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';
import 'package:racketmates/screens/splash/usecases/decide_startup_destination.dart';

/// Cold-start sequence: restore the session, fetch metadata, then decide where
/// to go. Root detection and the downtime check are added in the next
/// milestone (they gate this same sequence).
class SplashViewModel extends AsyncNotifier<StartupDestination> {
  @override
  Future<StartupDestination> build() async {
    final session = ref.read(sessionControllerProvider.notifier);
    await session.restore();

    final content = ref.read(contentControllerProvider.notifier);
    // Persisted strings/labels first: screens have copy immediately and offline.
    try {
      await content.loadCache();
    } on Object {
      // A broken cache must never block startup; it is refreshed below.
    }

    final repo = ref.read(startupRepositoryProvider);
    final metadata = await repo.fetchMetadata();
    // Refresh stale strings / reference data in the background.
    unawaited(content.onMetadata(metadata));
    final upgrade = metadata?.appUpgradeCheck;
    final destination = decideStartupDestination(
      signedIn: ref.read(sessionControllerProvider) is SignedIn,
      upgrade: upgrade,
      lastPromptedVersion: await repo.lastPromptedVersion(),
    );
    if (destination == StartupDestination.appUpdate) {
      ref.read(pendingUpgradeProvider.notifier).set(upgrade);
    }
    return destination;
  }
}

final splashViewModelProvider =
    AsyncNotifierProvider<SplashViewModel, StartupDestination>(
      SplashViewModel.new,
    );
