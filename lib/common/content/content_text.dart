import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/content/content_controller.dart';

/// `ref.msg(MessageKeys.x, l10n.fallback)`: server text, else the local ARB
/// fallback. Rebuilds the widget when the strings are refreshed.
extension MessageRef on WidgetRef {
  String msg(String key, String fallback) =>
      watch(messagesProvider).text(key, fallback);

  /// Same for the pre-login string set (welcome, sign-in, sign-up).
  String preMsg(String key, String fallback) =>
      watch(preLoginMessagesProvider).text(key, fallback);

  /// Localized label of a backend key (`et_casual`), else [fallback].
  String refLabel(String? key, String fallback) =>
      watch(referenceDataProvider).label(key) ?? fallback;
}
