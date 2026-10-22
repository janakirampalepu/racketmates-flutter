import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:racketmates/common/places/place_models.dart';

/// A link that opens [place] in the device's map app: Apple Maps on iOS,
/// Google Maps (which Android hands to the installed maps app) elsewhere.
/// Uses the coordinates when the venue has them, else its address.
Uri mapLinkFor(PlaceItem place, TargetPlatform platform) {
  final lat = place.addressDetail?.latitude;
  final lng = place.addressDetail?.longitude;
  final name = place.name ?? '';
  final text = [
    name,
    place.address ?? '',
  ].where((s) => s.isNotEmpty).join(', ');
  if (platform == TargetPlatform.iOS) {
    return Uri.https('maps.apple.com', '/', {
      if (lat != null && lng != null) 'll': '$lat,$lng',
      'q': name.isNotEmpty ? name : text,
    });
  }
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': lat != null && lng != null ? '$lat,$lng' : text,
  });
}

/// Whether there is anything to show on a map.
bool hasMapTarget(PlaceItem place) =>
    (place.addressDetail?.latitude != null &&
        place.addressDetail?.longitude != null) ||
    (place.address ?? '').isNotEmpty;
