import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// One event row, shared by home and schedule. Date comes from `event_date`
/// (`yyyy-MM-dd`); time slot, place and status labels are server-provided
/// (native `CommonEventsAdapter`).
class EventTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = item.date;
    final locale = Localizations.localeOf(context).toString();
    final day = date == null ? '' : DateFormat('dd', locale).format(date);
    final month = date == null
        ? ''
        : DateFormat('MMM', locale).format(date).toUpperCase();
    final time = _withMore(item.timeSlot ?? '', item.additionalTimings, l10n);
    final place = _withMore(item.placeName ?? '', item.additionalVenues, l10n);
    final status = item.eventStatusLabel ?? item.pastEventStatusLabel ?? '';
    final title = humanizeKey(item.eventType);
    final description = [
      title,
      time,
      place,
      status,
    ].where((s) => s.isNotEmpty).join(', ');
    return TestId(
      testId,
      child: Semantics(
        label: description,
        button: onTap != null,
        excludeSemantics: true,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Column(
                        children: [
                          Text(day, style: theme.textTheme.titleLarge),
                          Text(month, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium),
                          if (time.isNotEmpty) Text(time),
                          if (place.isNotEmpty) Text(place),
                          if (status.isNotEmpty)
                            Text(status, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
