import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_status_style.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
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
    final statusColor = eventPresentStatusColor(n, item.eventStatus);
    final chip = item.participantStatusLabel ?? '';
    final sport = SportKey.fromKey(item.sportType);
    final sportIcon = sport == null ? null : sportIconName(sport);
    final thirdLine = item.courtsLabel?.isNotEmpty ?? false
        ? (icon: Icons.sports_tennis_outlined, text: item.courtsLabel!)
        : item.coachLabel?.isNotEmpty ?? false
        ? (icon: Icons.school_outlined, text: item.coachLabel!)
        : item.notes?.isNotEmpty ?? false
        ? (icon: Icons.notes_outlined, text: item.notes!)
        : (icon: Icons.notes_outlined, text: l10n.eventNoNotes);
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
              child: Stack(
                children: [
                  if (sportIcon != null)
                    Positioned(
                      top: -sdp(10),
                      right: -sdp(10),
                      child: SvgIcon(
                        sportIcon,
                        size: sdp(64),
                        color: n.imagePrimeryColor.withValues(alpha: 0.12),
                      ),
                    ),
                  ConstrainedBox(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        Padding(
                                          padding: EdgeInsets.only(top: sdp(2)),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: sdp(6),
                                                height: sdp(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: statusColor,
                                                ),
                                              ),
                                              SizedBox(width: sdp(6)),
                                              Flexible(
                                                child: Text(
                                                  status,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: NativeText.regular(
                                                    sdp(11),
                                                    statusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                    borderRadius: BorderRadius.circular(
                                      sdp(36),
                                    ),
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
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              sdp(8),
                              sdp(6),
                              sdp(8),
                              0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  thirdLine.icon,
                                  size: sdp(14),
                                  color: n.textSecondary,
                                ),
                                SizedBox(width: sdp(6)),
                                Expanded(
                                  child: Text(
                                    thirdLine.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NativeText.regular(
                                      sdp(12),
                                      n.textSecondary,
                                    ),
                                  ),
                                ),
                                _ParticipantAvatars(
                                  users: item.eventUsers ?? const [],
                                  more: item.additionalParticipants ?? 0,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              sdp(8),
                              sdp(10),
                              sdp(8),
                              0,
                            ),
                            child: _EventActionButtons(
                              l10n: l10n,
                              left: item.swipeLeft,
                              right: item.swipeRight,
                              onTap: onTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

/// Up to 3 participant avatars, overlapping, plus a "+N" circle for the
/// rest (native `showTeamIconAndAvatars`/`displayEventAddedParticipentesPics`).
class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars({required this.users, required this.more});

  final List<AppUser> users;
  final int more;

  @override
  Widget build(BuildContext context) {
    final shown = users.take(3).toList();
    final overflow = more + (users.length - shown.length);
    if (shown.isEmpty && overflow <= 0) return const SizedBox.shrink();
    final sdp = context.sdp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, user) in shown.indexed)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : sdp(16)),
            child: _Avatar(user: user),
          ),
        if (overflow > 0)
          Padding(
            padding: EdgeInsets.only(left: shown.isEmpty ? 0 : sdp(16)),
            child: _Avatar(overflowCount: overflow),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.user, this.overflowCount});

  final AppUser? user;
  final int? overflowCount;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    String first(String? s) =>
        (s == null || s.trim().isEmpty) ? '' : s.trim()[0].toUpperCase();
    final url = user?.thumbnailAttachmentUrl ?? user?.avatarFileAttachmentUrl;
    return Container(
      width: sdp(24),
      height: sdp(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: n.windowBackgroundColor,
        border: Border.all(color: n.borderSolidPrimary, width: sdp(1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: overflowCount != null
          ? Text(
              '+$overflowCount',
              style: NativeText.medium(sdp(9), n.textSecondary),
            )
          : (url == null || url.isEmpty)
          ? Text(
              '${first(user?.firstName)}${first(user?.lastName)}',
              style: NativeText.medium(sdp(10), n.mainTertiary),
            )
          : Image.network(url, fit: BoxFit.cover),
    );
  }
}

/// Native raw action values shared with the pending-actions card
/// (`EventViewAction`/`PermissionActionType`) — the set an upcoming-event
/// card actually renders a button for (`canShowUpcomingAction`: excludes
/// the scores actions, which only appear on past events).
class _EventActionButtons extends StatelessWidget {
  const _EventActionButtons({
    required this.l10n,
    required this.left,
    required this.right,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final EventSwipeAction? left;
  final EventSwipeAction? right;
  final VoidCallback? onTap;

  static const _notAvailable = 'up_not_available';

  bool _usable(EventSwipeAction? action) =>
      action?.action != null && action?.access != _notAvailable;

  @override
  Widget build(BuildContext context) {
    final sdp = context.sdp;
    final hasLeft = _usable(left);
    final hasRight = _usable(right);
    final buttons = [
      if (hasLeft) _buttonFor(context, left!),
      if (hasRight) _buttonFor(context, right!),
    ];
    if (buttons.isEmpty) {
      buttons.add(
        _ActionButton(
          icon: Icons.visibility_outlined,
          label: l10n.eventViewAction,
          onTap: onTap,
        ),
      );
    }
    return Row(
      children: [
        for (final (i, button) in buttons.indexed) ...[
          if (i > 0) SizedBox(width: sdp(8)),
          Expanded(child: button),
        ],
      ],
    );
  }

  Widget _buttonFor(BuildContext context, EventSwipeAction action) {
    switch (action.action) {
      case 'event_view_action_decline':
        return _ActionButton(
          icon: Icons.close,
          label: l10n.rsvpDecline,
          onTap: onTap,
          outlined: true,
        );
      case 'event_view_action_accept':
        return _ActionButton(
          icon: Icons.check,
          label: l10n.rsvpAccept,
          onTap: onTap,
          filled: true,
        );
      case 'event_view_action_edit_response':
        return _ActionButton(
          icon: Icons.edit_outlined,
          label: l10n.rsvpEditResponse,
          onTap: onTap,
        );
      case 'user_action_manage_event':
        return _ActionButton(
          icon: Icons.settings_outlined,
          label: l10n.eventManageAction,
          onTap: onTap,
        );
      case 'event_view_action_directions':
        return _ActionButton(
          icon: Icons.directions_outlined,
          label: l10n.eventGetDirections,
          onTap: onTap,
        );
      case 'event_view_action_leave':
        return _ActionButton(
          icon: Icons.logout,
          label: l10n.rsvpLeave,
          onTap: onTap,
        );
      case 'event_view_action_rejoin':
        return _ActionButton(
          icon: Icons.replay,
          label: l10n.rsvpRejoin,
          onTap: onTap,
          filled: true,
        );
      case 'event_view_action_join_waitlist':
        return _ActionButton(
          icon: Icons.hourglass_bottom,
          label: l10n.rsvpJoinWaitlist,
          onTap: onTap,
          filled: true,
        );
      case 'user_action_view_event':
      default:
        return _ActionButton(
          icon: Icons.visibility_outlined,
          label: l10n.eventViewAction,
          onTap: onTap,
        );
    }
  }
}

/// One action button: tapping any of them opens the event (same as tapping
/// the card) rather than acting in place — the accept/decline/directions
/// flows already live on the event/manage screens, so wiring a second,
/// parallel action path here was out of scope for this visual-parity pass.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );
    final iconWidget = Icon(icon, size: 16);
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: iconWidget,
        label: child,
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
        ),
      );
    }
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: iconWidget,
        label: child,
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: iconWidget,
      label: child,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      ),
    );
  }
}
