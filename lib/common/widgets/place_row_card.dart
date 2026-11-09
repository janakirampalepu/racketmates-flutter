import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/places/place_models.dart';

/// Leading icon for a venue row: native shows a favourite icon (star) for
/// a favourited place, else a place-type icon — never a generic marker and
/// never a separate star badge layered on the row (Android
/// `getIconBasedOnPlaceType`/`FavoritePlacesListAdapter`, iOS
/// `PlaceType.imageIcon` / `"star_fill_icon"`). The real per-type assets
/// (park/building/book/travel/meeting icons) aren't ported here; these are
/// the closest Material equivalents.
IconData placeRowIcon(PlaceItem place) {
  if (place.favourite ?? false) return Icons.star;
  return switch (place.placeType) {
    'pt_club' => Icons.sports_tennis,
    'pt_school' => Icons.school,
    'pt_park' => Icons.park,
    'pt_community_center' => Icons.groups,
    _ => Icons.place,
  };
}

/// One venue row, matching native's gradient-bordered card (Android
/// `item_place_details.xml`, iOS `placeRow`/`locationRow`) instead of a
/// plain list-with-divider row: a leading icon with the distance stacked
/// underneath, the name and address in the middle, and a trailing slot.
/// Rows are spaced with a vertical gap (card margin), never a divider —
/// neither native app draws one between rows.
class PlaceRowCard extends StatelessWidget {
  const PlaceRowCard({
    required this.place,
    required this.distanceText,
    required this.testId,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final PlaceItem place;
  final String? distanceText;
  final String testId;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      testId,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sdp(8)),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: sdp(6)),
          padding: EdgeInsets.all(sdp(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sdp(8)),
            border: Border.all(color: n.statusColorsDarkGray),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                n.backgroundGradientGreen15p,
                n.backgroundGradientBlack0p,
                n.backgroundGradientGreen15p,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    placeRowIcon(place),
                    size: sdp(24),
                    color: n.imagePrimeryColor,
                  ),
                  if (distanceText != null) ...[
                    SizedBox(height: sdp(2)),
                    Text(
                      distanceText!,
                      style: TextStyle(
                        fontSize: sdp(11),
                        color: n.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(width: sdp(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: sdp(13),
                        fontWeight: FontWeight.w600,
                        color: n.textPrimary,
                      ),
                    ),
                    if ((place.address ?? '').isNotEmpty)
                      Text(
                        place.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: sdp(12),
                          color: n.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
