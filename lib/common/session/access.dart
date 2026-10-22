import 'package:racketmates/common/events/models/event_details.dart';

/// What a feature button does for the signed-in user, from its permission in
/// `session_info` (native `AccessState` handling, e.g. in `ActiveTeamsFragment`).
enum AccessDecision {
  /// Go ahead (also when the permission is unknown, e.g. before the first
  /// `session_info` answer).
  allowed,

  /// `up_not_available`: do not show the feature.
  hidden,

  /// `up_requires_subscription` for someone without full access: offer the
  /// subscription instead.
  needsSubscription,

  /// `up_disabled`: show the server's message.
  blocked,
}

AccessDecision decideAccess(AccessInfo? info, {required bool subscribed}) =>
    switch (info?.access) {
      'up_not_available' => AccessDecision.hidden,
      'up_requires_subscription' when !subscribed =>
        AccessDecision.needsSubscription,
      'up_disabled' => AccessDecision.blocked,
      _ => AccessDecision.allowed,
    };
