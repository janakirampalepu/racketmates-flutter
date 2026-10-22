import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';

/// Whether push can work on this build and what the user decided.
typedef PushStatus = ({bool available, PushPermission permission});

final pushStatusProvider = FutureProvider.autoDispose<PushStatus>((ref) async {
  final platform = ref.read(pushPlatformProvider);
  final available = await platform.initialize();
  if (!available) return (available: false, permission: PushPermission.denied);
  return (available: true, permission: await platform.permission());
});
