import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/config/config_providers.dart';

/// The status filter the native app applies to partner lists: the first of
/// `resources/event_participants_status_filter_options`. Null when the list
/// cannot be loaded (the partner list then is not narrowed by status).
final participantStatusFilterKeyProvider = FutureProvider<String?>((ref) async {
  final config = ref.watch(environmentConfigProvider);
  try {
    final data = await ref
        .watch(authApiProvider)
        .participantStatusFilterOptions(
          config.oauthClientId,
          config.oauthClientSecret,
        );
    final options = data is Map ? data['filter_options'] : null;
    final first = options is List && options.isNotEmpty ? options.first : null;
    final key = first is Map ? first['key'] : null;
    return key is String && key.isNotEmpty ? key : null;
  } on Object {
    return null;
  }
});
