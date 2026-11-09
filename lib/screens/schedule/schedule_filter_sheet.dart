import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/schedule_filter.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

/// Owner/sport filter button + sheet (native `imageFilterEvents` /
/// `EventFilterPicker`), shared by the global Schedule screen and Team
/// Schedule. [isTeamContext] picks which persisted filter it reads/writes.
class ScheduleFilterButton extends ConsumerWidget {
  const ScheduleFilterButton({
    required this.isTeamContext,
    this.testId = ScheduleTestIds.filterButton,
    super.key,
  });

  final bool isTeamContext;
  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final filter = ref.watch(scheduleFilterProvider(isTeamContext));
    final sports = ref.watch(accountSportsProvider).value ?? const {};
    // Native's own "default" (`hasFilterInDefault`): both ownerships, and —
    // only when the account plays more than one sport — every one of them
    // selected. Narrowing either makes the icon switch to its filled/tinted
    // "active" state (`ic_event_filter_seleted`/a lit-up `slider.horizontal.3`).
    final isDefault =
        filter.ownerships.length == 2 &&
        (sports.length <= 1 || filter.sportTypes.length == sports.length);
    final color = isDefault ? n.textTertiary : n.colorPrimary;
    return TestId(
      testId,
      child: Tooltip(
        message: l10n.scheduleFilterAction,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _ScheduleFilterSheet(isTeamContext: isTeamContext),
          ),
          child: Container(
            width: sdp(42),
            height: sdp(42),
            margin: EdgeInsets.all(sdp(4)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            // Native's icon (`ic_event_filter`/iOS `slider.horizontal.3`) is
            // the standard 3-horizontal-sliders "tune" glyph, not a funnel.
            child: Icon(Icons.tune, size: sdp(18), color: color),
          ),
        ),
      ),
    );
  }
}

class _ScheduleFilterSheet extends ConsumerWidget {
  const _ScheduleFilterSheet({required this.isTeamContext});

  final bool isTeamContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final filter = ref.watch(scheduleFilterProvider(isTeamContext));
    final notifier = ref.read(scheduleFilterProvider(isTeamContext).notifier);
    final sports = ref.watch(accountSportsProvider).value ?? const {};

    void toggleOwnership(String key, bool? value) {
      final next = Set<String>.from(filter.ownerships);
      if (value ?? false) {
        next.add(key);
      } else {
        next.remove(key);
      }
      notifier.setOwnerships(next);
    }

    void toggleSport(String key, bool value) {
      final next = Set<String>.from(filter.sportTypes);
      if (value) {
        next.add(key);
      } else {
        next.remove(key);
      }
      notifier.setSportTypes(next);
    }

    return TestId(
      ScheduleFilterTestIds.sheet,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(sdp(16), sdp(16), sdp(16), sdp(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleFilterTitle,
                  style: TextStyle(
                    color: n.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: sdp(16),
                  ),
                ),
                SizedBox(height: sdp(8)),
                TestId(
                  ScheduleFilterTestIds.ownerManaging,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.scheduleFilterOwnerManaging),
                    value: filter.ownerships.contains(ownershipManaging),
                    onChanged: (v) => toggleOwnership(ownershipManaging, v),
                  ),
                ),
                TestId(
                  ScheduleFilterTestIds.ownerParticipant,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.scheduleFilterOwnerParticipant),
                    value: filter.ownerships.contains(ownershipParticipant),
                    onChanged: (v) => toggleOwnership(ownershipParticipant, v),
                  ),
                ),
                // Native only shows the sport section when the account plays
                // more than one sport (`getDefaultSportsType`); with one or
                // none, every sport is implicitly included.
                if (sports.length > 1) ...[
                  SizedBox(height: sdp(12)),
                  Text(
                    l10n.scheduleFilterSportsLabel,
                    style: TextStyle(
                      color: n.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: sdp(8),
                    children: [
                      for (final sport in sports)
                        TestId(
                          ScheduleFilterTestIds.sport(sport.key),
                          child: FilterChip(
                            avatar: SvgIcon(
                              sportIconName(sport),
                              size: sdp(16),
                              color: filter.sportTypes.contains(sport.key)
                                  ? n.imagePrimeryColor
                                  : n.textSecondary,
                            ),
                            label: Text(sportLabel(l10n, sport)),
                            selected: filter.sportTypes.contains(sport.key),
                            onSelected: (v) => toggleSport(sport.key, v),
                          ),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: sdp(12)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TestId(
                    ScheduleFilterTestIds.apply,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.scheduleFilterApply),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
