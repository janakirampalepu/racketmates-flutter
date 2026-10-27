import 'dart:ui';

import 'package:racketmates/app/theme/native_palette.g.dart';

/// The colours the native app gives an event card for the user's status
/// (`TextUtils.kt`: `getStrokeBackgroundColor`, `getMonthBackgroundColor`,
/// `getDateBackgroundColor`, `getStatusTextColor`).
class EventStatusStyle {
  const EventStatusStyle({
    required this.stroke,
    required this.month,
    required this.date,
    required this.statusText,
  });

  /// The card outline.
  final Color stroke;

  /// The month strip of the date box and the status chip.
  final Color month;

  /// The day part of the date box.
  final Color date;

  /// The chip's text.
  final Color statusText;
}

/// Color of the small status dot + label above the event title (native iOS
/// `AppColors.eventPresentStatusTextColor(EventPresentStatus)`, for the
/// event's own `es_*` status — not the signed-in user's RSVP status, which
/// is [eventStatusStyle] above). iOS's `scheduled`/`draft`/default case
/// returns a confusingly-named `StatusColors.white` token that is actually
/// an adaptive near-black/near-white neutral, not literal white; mapped to
/// `textSecondary` here as the closest existing token.
Color eventPresentStatusColor(NativePalette n, String? eventStatus) {
  switch (eventStatus) {
    case 'es_to_be_scheduled' || 'es_to_be_finalized':
      return n.statusColorsLightOrange;
    case 'es_cancelled':
      return n.statusColorsLightRed;
    case 'es_in_progress':
      return n.statusColorsLightBlue;
    case 'es_completed':
      return n.statusColorsLightGreen;
    case 'es_mixed':
      return n.statusColorsLightPurple;
    default:
      return n.textSecondary;
  }
}

EventStatusStyle eventStatusStyle(NativePalette n, String? status) {
  switch (status) {
    case 'eus_confirmed' || 'eus_confirmed_with_other_courts':
      return EventStatusStyle(
        stroke: n.backgroundSolidGreen1,
        month: n.statusColorsDarkGreen,
        date: n.backgroundSolidGreen4,
        statusText: n.textGreen,
      );
    case 'eus_mixed':
      return EventStatusStyle(
        stroke: n.statusColorsLightPurple,
        month: n.statusColorsLightPurple,
        date: n.statusColorsDarkPurple,
        statusText: n.textPrimary,
      );
    case 'eus_waitlisted':
      return EventStatusStyle(
        stroke: n.statusColorsLightOrange,
        month: n.statusColorsDarkOrange,
        date: n.statusColorsLightYellow20p,
        statusText: n.textPrimary,
      );
    case 'eus_declined' || 'eus_declined_with_other_courts' || 'eus_full':
      return EventStatusStyle(
        stroke: n.statusColorsLightRed,
        month: n.statusColorsMediumRed,
        date: n.statusColorsLightRed20P,
        statusText: n.textPrimary,
      );
    case 'eus_invited':
      return EventStatusStyle(
        stroke: n.statusColorsLightTeal,
        month: n.statusColorsMediumTeal,
        date: n.statusColorsDarkTeal,
        statusText: n.textPrimary,
      );
    case 'eus_to_be_confirmed':
      return EventStatusStyle(
        stroke: n.lightBlue,
        month: n.statusColorsDarkBlue,
        date: n.statusColorsLightBlue15p,
        statusText: n.textPrimary,
      );
    case 'eus_managing':
      return EventStatusStyle(
        stroke: n.statusColorsLightBrown,
        month: n.statusColorsMediumBrown,
        date: n.statusColorsMediumBrown,
        statusText: n.textPrimary,
      );
    default:
      return EventStatusStyle(
        stroke: n.borderSolidPrimary,
        month: n.statusColorsLightGray,
        date: n.statusColorsDarkGray,
        statusText: n.textPrimary,
      );
  }
}
