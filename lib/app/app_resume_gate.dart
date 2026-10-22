import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/startup/app_gate.dart';

/// Re-runs the device and downtime checks whenever the app comes back to the
/// foreground (native `checkAppUpdateResuming` / the rooted check on resume).
class AppResumeGate extends ConsumerStatefulWidget {
  const AppResumeGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppResumeGate> createState() => _AppResumeGateState();
}

class _AppResumeGateState extends ConsumerState<AppResumeGate> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () => ref.read(appGateCheckerProvider).checkOnResume(),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
