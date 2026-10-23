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
