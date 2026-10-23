import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_status_style.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// One event row, shared by home and schedule. Date comes from `event_date`
/// (`yyyy-MM-dd`); time slot, place and status labels are server-provided
/// (native `CommonEventsAdapter`).
class EventTile extends ConsumerWidget {
  const EventTile({
    required this.item,
    required this.testId,
    this.onTap,
    super.key,
  });

  final ScheduleItem item;

  /// Appium identifier of the whole tile (`<screen>_event_<eventId>`).
  final String testId;
  final VoidCallback? onTap;

  static String _withMore(String text, int? more, AppLocalizations l10n) =>
      (more ?? 0) > 0 ? '$text ${l10n.moreSuffix(more!)}' : text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reference = ref.watch(referenceDataProvider);
    final date = item.date;
    final locale = Localizations.localeOf(context).toString();
    final day = date == null ? '' : DateFormat('dd', locale).format(date);
    final month = date == null
        ? ''
        : DateFormat('MMM', locale).format(date).toUpperCase();
    final time = _withMore(item.timeSlot ?? '', item.additionalTimings, l10n);
    final place = _withMore(item.placeName ?? '', item.additionalVenues, l10n);
    final status = item.eventStatusLabel ?? item.pastEventStatusLabel ?? '';
    final title =
        reference.label(item.eventType) ?? humanizeKey(item.eventType);
    final description = [
      title,
      time,
      place,
      status,
    ].where((s) => s.isNotEmpty).join(', ');
    final n = context.native;
    final sdp = context.sdp;
    final style = eventStatusStyle(n, item.participantStatus);
    final chip = item.participantStatusLabel ?? '';
    return TestId(
      testId,
      child: Semantics(
        label: description,
        button: onTap != null,
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: sdp(12)),
          child: Material(
            color: n.windowBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sdp(12)),
              side: BorderSide(color: style.stroke, width: sdp(1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, sdp(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: sdp(40),
                            margin: EdgeInsets.all(sdp(8)),
                            decoration: BoxDecoration(
                              color: style.date,
                              borderRadius: BorderRadius.circular(sdp(4)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: sdp(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: style.month,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(sdp(4)),
                                    ),
                                  ),
                                  child: Text(
                                    month,
                                    textAlign: TextAlign.center,
                                    style: NativeText.medium(
                                      sdp(10),
                                      n.textPrimary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: sdp(4)),
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: NativeText.medium(
                                      sdp(12),
                                      n.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: sdp(8),
                                right: sdp(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NativeText.semibold(
                                      sdp(14),
                                      n.textPrimary,
                                    ),
                                  ),
                                  if (status.isNotEmpty)
                                    Text(
                                      status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: NativeText.regular(
                                        sdp(11),
                                        n.textPrimary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (chip.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(
                                top: sdp(18),
                                right: sdp(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: sdp(6),
                                vertical: sdp(2),
                              ),
                              decoration: BoxDecoration(
                                color: style.month,
                                borderRadius: BorderRadius.circular(sdp(36)),
                              ),
                              child: Text(
                                chip,
                                style: NativeText.regular(
                                  sdp(8),
                                  style.statusText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (time.isNotEmpty)
                        _line(context, 'ic_schedule_date_time', time),
                      if (place.isNotEmpty)
                        _line(context, 'ic_schedule_location', place),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String icon, String text) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.fromLTRB(sdp(8), sdp(6), sdp(4), 0),
      child: Row(
        children: [
          SvgIcon(icon, size: sdp(14), color: n.textSecondary),
          SizedBox(width: sdp(6)),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NativeText.regular(sdp(12), n.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
