import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

/// List or calendar view (native's actual toggle on the Schedule screen —
/// there is no Upcoming/Past tab on either platform; "Past events" is a
/// separate screen reached from [ScheduleTopRow]). Calendar view (a day
/// picker + that day's events, native `displayCalendarView`/`.calendar`) is
/// not built — selecting it shows a placeholder instead of silently doing
/// nothing.
enum ScheduleViewMode { list, calendar }

/// The pill-shaped List/Calendar toggle (native `layoutOptionsBtns`
/// Android, `segmentedControlView` iOS): two equal-width segments in one
/// bordered, rounded container; the selected side gets a tinted fill and a
/// `colorPrimary` border.
class ScheduleViewToggle extends StatelessWidget {
  const ScheduleViewToggle({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final ScheduleViewMode mode;
  final ValueChanged<ScheduleViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    Widget segment(
      ScheduleViewMode value,
      IconData icon,
      String label,
      String testId,
      BorderRadius radius,
    ) {
      final selected = value == mode;
      return Expanded(
        child: TestId(
          testId,
          child: InkWell(
            borderRadius: radius,
            onTap: () => onChanged(value),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: sdp(8)),
              decoration: BoxDecoration(
                color: selected
                    ? n.backgroundGradientGreen10p
                    : Colors.transparent,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? n.colorPrimary : n.borderSolidPrimary,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: sdp(16),
                    color: selected ? n.imagePrimeryColor : n.textTertiary,
                  ),
                  SizedBox(width: sdp(6)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: sdp(13),
                      fontWeight: FontWeight.w500,
                      color: selected ? n.textPrimary : n.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        segment(
          ScheduleViewMode.list,
          Icons.view_agenda_outlined,
          'List',
          ScheduleTestIds.viewToggleList,
          BorderRadius.horizontal(left: Radius.circular(sdp(8))),
        ),
        segment(
          ScheduleViewMode.calendar,
          Icons.calendar_month_outlined,
          'Calendar',
          ScheduleTestIds.viewToggleCalendar,
          BorderRadius.horizontal(right: Radius.circular(sdp(8))),
        ),
      ],
    );
  }
}

/// A full-width "go to this list" entry (native Android's stacked
/// `btnDraftEvent`/`btnToBeScheduledEvent`/`btnPastEvents` buttons above the
/// recycler; iOS's `EventListTopRowView` rows at the top of the same list).
/// Built as one shared card-style row rather than two different per-platform
/// looks, since both are simple icon+text(+chevron) entries.
class ScheduleTopRow extends StatelessWidget {
  const ScheduleTopRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.onTap,
    this.testId,
    this.borderColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;

  /// `null` draws no border (native's "Past events" row has none on iOS;
  /// Android's own buttons likewise have no stroke).
  final Color? borderColor;
  final VoidCallback onTap;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final sdp = context.sdp;
    final row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(sdp(8)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sdp(16), vertical: sdp(14)),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(sdp(8)),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          children: [
            Icon(icon, size: sdp(20), color: iconColor),
            SizedBox(width: sdp(12)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: sdp(14),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: sdp(20), color: iconColor),
          ],
        ),
      ),
    );
    return testId == null ? row : TestId(testId!, child: row);
  }
}
