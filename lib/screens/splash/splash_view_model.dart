import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final repo = ref.read(startupRepositoryProvider);
    final metadata = await repo.fetchMetadata();
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
