import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/places/place_models.dart';

void main() {
  group('PlaceItem.distance', () {
    test('parses a JSON number', () {
      final place = PlaceItem.fromJson({'id': 1, 'distance': 10.74});
      expect(place.distance, 10.74);
    });

    test('parses a numeric string', () {
      // Confirmed on a real device: the backend sends `distance` as a
      // string for some records in the very same `GET places` response
      // that sends it as a number for others.
      final place = PlaceItem.fromJson({'id': 2, 'distance': '16.47'});
      expect(place.distance, 16.47);
    });

    test('is null for a missing or null distance', () {
      expect(PlaceItem.fromJson({'id': 3}).distance, isNull);
      expect(PlaceItem.fromJson({'id': 4, 'distance': null}).distance, isNull);
    });

    test('a response mixing both shapes across records parses cleanly', () {
      final response = PlacesListResponse.fromJson({
        'places': [
          {'id': 1, 'distance': 10.74},
          {'id': 2, 'distance': '16.47'},
        ],
      });
      expect(response.places!.map((p) => p.distance), [10.74, 16.47]);
    });
  });

  group('id fields', () {
    test('PlaceItem.id and PlaceCourt.id parse a numeric string', () {
      final place = PlaceItem.fromJson({
        'id': '127',
        'place_courts': [
          {'id': '10', 'name': 'Court 1'},
        ],
      });
      expect(place.id, 127);
      expect(place.placeCourts!.single.id, 10);
    });
  });

  group('PlaceAddress', () {
    test('latitude/longitude parse a numeric string', () {
      final address = PlaceAddress.fromJson({
        'latitude': '40.1',
        'longitude': '-73.9',
      });
      expect(address.latitude, 40.1);
      expect(address.longitude, -73.9);
    });
  });

  group('formatDistance', () {
    test('matches iOS: two decimal places plus the unit', () {
      expect(formatDistance(10.74, 'mi'), '10.74 mi');
      expect(formatDistance(2, 'mi'), '2.00 mi');
    });

    test('null for no distance or a zero distance', () {
      expect(formatDistance(null, 'mi'), isNull);
      expect(formatDistance(0, 'mi'), isNull);
    });
  });
}
