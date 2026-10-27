import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// The "Activity" section shared by Home and Team Home (native
/// `fragment_home_activity_stats`, reused by both `HomeFragment` and
/// `TeamHomeFragment`): one page per year, swiped with a dot indicator
/// shown only when there is more than one year (native `TabLayoutMediator`,
/// wired only when `activityStats.size > 1`).
class HomeActivityCard extends StatefulWidget {
  const HomeActivityCard({
    required this.years,
    required this.yearBadgeId,
    super.key,
  });

  final List<HomePageStats> years;

  /// Test id for the year badge (differs between Home and Team Home).
  final String yearBadgeId;

  @override
  State<HomeActivityCard> createState() => _HomeActivityCardState();
}

class _HomeActivityCardState extends State<HomeActivityCard> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sdp = context.sdp;
    final years = widget.years;
    return Column(
      children: [
        SizedBox(
          height: sdp(260),
          child: PageView.builder(
            controller: _controller,
            itemCount: years.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) =>
                _YearPage(stats: years[i], yearBadgeId: widget.yearBadgeId),
          ),
        ),
        if (years.length > 1)
          Padding(
            padding: EdgeInsets.only(top: sdp(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < years.length; i++)
                  Container(
                    width: sdp(6),
                    height: sdp(6),
                    margin: EdgeInsets.symmetric(horizontal: sdp(3)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? context.native.colorPrimary
                          : context.native.borderSolidPrimary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _YearPage extends StatelessWidget {
  const _YearPage({required this.stats, required this.yearBadgeId});

  final HomePageStats stats;
  final String yearBadgeId;

  bool get _isEmpty =>
      (stats.totalEvents ?? 0) == 0 && (stats.totalHours ?? 0) == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final who = stats.user?.firstName;
    return Padding(
      padding: EdgeInsets.all(sdp(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (who != null && who.isNotEmpty)
                Expanded(
                  child: Text(
                    "$who's",
                    style: NativeText.semibold(sdp(14), n.textPrimary),
                  ),
                )
              else
                const Spacer(),
              if (stats.year != null)
                TestId(
                  yearBadgeId,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sdp(10),
                      vertical: sdp(4),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: n.colorPrimary),
                      borderRadius: BorderRadius.circular(sdp(24)),
                    ),
                    child: Text(
                      '${stats.year}',
                      style: NativeText.medium(sdp(12), n.textPrimary),
                    ),
                  ),
                ),
            ],
          ),
          if (_isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SvgIcon('ic_no_activity', size: 62),
                    SizedBox(height: sdp(8)),
                    Text(
                      l10n.activityNoActivityTitle,
                      style: NativeText.medium(sdp(14), n.textPrimary),
                    ),
                    SizedBox(height: sdp(4)),
                    Text(
                      l10n.activityNoActivityDescription,
                      textAlign: TextAlign.center,
                      style: NativeText.regular(sdp(12), n.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sdp(8)),
                    Row(
                      children: [
                        _StatTile(
                          icon: 'ic_stats_event',
                          value: stats.totalEvents,
                          label: l10n.statEvents,
                          color: n.textPrimary,
                        ),
                        SizedBox(width: sdp(6)),
                        _StatTile(
                          icon: 'ic_stats_wins',
                          value: stats.wins,
                          label: l10n.statWins,
                          // Native's wins count is the brand lime
                          // (`image_primery_color`), not a neutral color
                          // like the events tile.
                          color: n.imagePrimeryColor,
                        ),
                        SizedBox(width: sdp(6)),
                        _StatTile(
                          icon: 'ic_stats_lose',
                          value: stats.losses,
                          label: l10n.statLosses,
                          color: n.noClubsColor,
                        ),
                      ],
                    ),
                    SizedBox(height: sdp(8)),
                    Container(
                      padding: EdgeInsets.all(sdp(8)),
                      decoration: BoxDecoration(
                        color: n.windowBackgroundColor,
                        borderRadius: BorderRadius.circular(sdp(8)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ActivityRing(stats: stats, l10n: l10n),
                              SizedBox(width: sdp(12)),
                              Expanded(
                                child: Wrap(
                                  spacing: sdp(8),
                                  runSpacing: sdp(4),
                                  children: [
                                    _Legend(
                                      color: n.colorPrimary,
                                      hours: stats.gamesHours,
                                      label: l10n.activityLegendGames,
                                    ),
                                    _Legend(
                                      color: n.textTertiary,
                                      hours: stats.practiceHours,
                                      label: l10n.activityLegendPractice,
                                    ),
                                    _Legend(
                                      color: n.statusColorsLightBlue,
                                      hours: stats.lessonHours,
                                      label: l10n.activityLegendLessons,
                                    ),
                                    _Legend(
                                      color: n.lightRed,
                                      hours: stats.meetingHours,
                                      label: l10n.activityLegendMeetings,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if ((stats.weeklyAverageValue ?? '').isNotEmpty) ...[
                            Divider(
                              height: sdp(16),
                              color: n.borderStrokeBlack,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.activityWeeklyAverageLabel,
                                  style: NativeText.regular(
                                    sdp(12),
                                    n.textSecondary,
                                  ),
                                ),
                                SizedBox(width: sdp(4)),
                                Text(
                                  stats.weeklyAverageValue!,
                                  style: NativeText.semibold(
                                    sdp(12),
                                    n.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final String icon;
  final int? value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sdp(8), horizontal: sdp(4)),
        decoration: BoxDecoration(
          color: n.windowBackgroundColor,
          borderRadius: BorderRadius.circular(sdp(8)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${value ?? 0}',
                  style: NativeText.semibold(sdp(20), color),
                ),
                SizedBox(width: sdp(4)),
                SvgIcon(icon, size: sdp(14)),
              ],
            ),
            Text(label, style: NativeText.regular(sdp(12), n.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.hours,
    required this.label,
  });

  final Color color;
  final int? hours;
  final String label;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: sdp(8),
          height: sdp(12),
          margin: EdgeInsets.only(right: sdp(4)),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(sdp(2)),
          ),
        ),
        Text(
          '${hours ?? 0}h',
          style: NativeText.semibold(sdp(12), n.textPrimary),
        ),
        SizedBox(width: sdp(4)),
        Text(label, style: NativeText.regular(sdp(12), n.textSecondary)),
      ],
    );
  }
}

/// The hours-breakdown donut (native iOS `CircularProgressView`): one
/// rounded-cap arc segment per category, in the same order and colors as
/// [_Legend] below it, with the total hours in the center. Android has no
/// equivalent (legend only); the product's iOS screenshots are the design
/// reference here.
class _ActivityRing extends StatelessWidget {
  const _ActivityRing({required this.stats, required this.l10n});

  final HomePageStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final total = stats.totalHours ?? 0;
    final size = sdp(88);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ActivityRingPainter(
              total: total,
              segments: [
                (stats.gamesHours ?? 0, n.colorPrimary),
                (stats.practiceHours ?? 0, n.textTertiary),
                (stats.lessonHours ?? 0, n.statusColorsLightBlue),
                (stats.meetingHours ?? 0, n.lightRed),
              ],
              strokeWidth: sdp(10),
              trackColor: n.borderSolidPrimary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${total}h',
                style: NativeText.semibold(sdp(16), n.textPrimary),
              ),
              Text(
                l10n.activityTotalLabel,
                style: NativeText.regular(sdp(10), n.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  _ActivityRingPainter({
    required this.total,
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
  });

  final int total;
  final List<(int, Color)> segments;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (total <= 0) return;
    var startFraction = 0.0;
    for (final (value, color) in segments) {
      if (value <= 0) continue;
      final fraction = value / total;
      canvas.drawArc(
        rect,
        -math.pi / 2 + startFraction * 2 * math.pi,
        fraction * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startFraction += fraction;
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor ||
      !_segmentsEqual(oldDelegate.segments, segments);

  static bool _segmentsEqual(List<(int, Color)> a, List<(int, Color)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
