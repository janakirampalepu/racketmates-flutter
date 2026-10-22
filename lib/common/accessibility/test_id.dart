import 'package:flutter/material.dart';

/// Marks a widget with a stable automation identifier for Appium.
///
/// `Semantics.identifier` is exposed as `accessibilityIdentifier` on iOS and
/// `resource-id` on Android. Identifiers are never localized and never derived
/// from server copy. Reuse the exact identifier used by the native apps when
/// the element already exists there. Screen-reader text belongs in
/// `Semantics.label`, not here.
class TestId extends StatelessWidget {
  const TestId(this.id, {required this.child, super.key});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(identifier: id, explicitChildNodes: true, child: child);
}
