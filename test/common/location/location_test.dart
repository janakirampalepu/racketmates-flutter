import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/location/location_platform.dart';
import 'package:racketmates/common/location/user_location.dart';
import 'package:racketmates/common/places/map_links.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_api.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/common/session/session_info_models.dart';

import '../../support/fakes.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'places': <Object>[]}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _container({
  FakeLocationPlatform? platform,
  InMemoryDistanceStore? store,
}) {
  final c = ProviderContainer(
    overrides: [
      locationPlatformProvider.overrideWithValue(
        platform ?? FakeLocationPlatform(),
      ),
      distanceFilterStoreProvider.overrideWithValue(
        store ?? InMemoryDistanceStore(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('UserLocation', () {
    test('asks while undecided, then reads the position', () async {
      final platform = FakeLocationPlatform();
      final c = _container(platform: platform);
      await c.read(userLocationProvider.notifier).ensure();
      final s = c.read(userLocationProvider);
      expect(platform.requests, 1);
      expect(s.permission, LocationPermission.granted);
      expect(s.position, const LatLng(40.7128, -74.006));
      expect(s.loading, isFalse);
    });

    test('already granted: no prompt', () async {
      final platform = FakeLocationPlatform(state: LocationPermission.granted);
      final c = _container(platform: platform);
      await c.read(userLocationProvider.notifier).ensure();
      expect(platform.requests, 0);
      expect(c.read(userLocationProvider).known, isTrue);
    });

    test('a refusal leaves no position and is not asked again', () async {
      final platform = FakeLocationPlatform(
        answerToRequest: LocationPermission.denied,
      );
      final c = _container(platform: platform);
      final location = c.read(userLocationProvider.notifier);
      await location.ensure();
      await location.ensure();
      expect(platform.requests, 1);
      expect(platform.fixes, 0);
      expect(
        c.read(userLocationProvider).permission,
        LocationPermission.denied,
      );
      expect(c.read(userLocationProvider).known, isFalse);
    });

    test('granted but no fix leaves no position', () async {
      final platform = FakeLocationPlatform(
        state: LocationPermission.granted,
        position: null,
      );
      final c = _container(platform: platform);
      await c.read(userLocationProvider.notifier).ensure();
      expect(c.read(userLocationProvider).known, isFalse);
      expect(
        c.read(userLocationProvider).permission,
        LocationPermission.granted,
      );
    });

    test('a known position is kept unless refreshed', () async {
      final platform = FakeLocationPlatform(state: LocationPermission.granted);
      final c = _container(platform: platform);
      final location = c.read(userLocationProvider.notifier);
      await location.ensure();
      await location.ensure();
      expect(platform.fixes, 1);
      platform.position = const LatLng(1, 2);
      await location.ensure(refresh: true);
      expect(platform.fixes, 2);
      expect(c.read(userLocationProvider).position, const LatLng(1, 2));
    });

    test('recheck picks up a permission given in the settings', () async {
      final platform = FakeLocationPlatform(state: LocationPermission.denied);
      final c = _container(platform: platform);
      final location = c.read(userLocationProvider.notifier);
      await location.ensure();
      expect(c.read(userLocationProvider).known, isFalse);
      platform.state = LocationPermission.granted;
      await location.recheck();
      expect(c.read(userLocationProvider).known, isTrue);
    });

    test('settings can be opened', () async {
      final platform = FakeLocationPlatform();
      final c = _container(platform: platform);
      await c.read(userLocationProvider.notifier).openSettings();
      expect(platform.settingsOpened, 1);
    });
  });

  group('search distance', () {
    test('defaults to 30 and remembers changes', () async {
      final store = InMemoryDistanceStore();
      final c = _container(store: store);
      expect(await c.read(searchDistanceProvider.future), 30);
      await c.read(searchDistanceProvider.notifier).set(12);
      expect(c.read(searchDistanceProvider).value, 12);
      expect(store.value, 12);
      await c.read(searchDistanceProvider.notifier).reset();
      expect(store.value, 30);
    });

    test('starts from the saved value', () async {
      final c = _container(store: InMemoryDistanceStore()..value = 8);
      expect(await c.read(searchDistanceProvider.future), 8);
    });
  });

  group('place search request', () {
    late _Adapter adapter;
    late PlacesRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = PlacesRepositoryImpl(
        PlacesApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('with a position it sends latitude, longitude and distance', () async {
      await repo.search(
        query: 'club',
        latitude: 40.5,
        longitude: -74.25,
        distance: 15,
      );
      final q = adapter.requests.single.uri.queryParametersAll;
      expect(q['latitude'], ['40.5']);
      expect(q['longitude'], ['-74.25']);
      expect(q['distance'], ['15']);
      expect(q['search'], ['club']);
    });

    test('without one it sends none of them', () async {
      await repo.search(distance: 15, latitude: 1);
      final q = adapter.requests.single.uri.queryParametersAll;
      expect(q.containsKey('latitude'), isFalse);
      expect(q.containsKey('longitude'), isFalse);
      expect(q.containsKey('distance'), isFalse);
    });
  });

  group('map links', () {
    const withCoords = PlaceItem(
      name: 'Central Courts',
      address: '1 Main St',
      addressDetail: PlaceAddress(latitude: 40.1, longitude: -73.9),
    );

    test('Android: Google Maps by coordinates', () {
      final uri = mapLinkFor(withCoords, TargetPlatform.android);
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters, {'api': '1', 'query': '40.1,-73.9'});
    });

    test('iOS: Apple Maps with the coordinates and the name', () {
      final uri = mapLinkFor(withCoords, TargetPlatform.iOS);
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters, {'ll': '40.1,-73.9', 'q': 'Central Courts'});
    });

    test('without coordinates the address is searched', () {
      const place = PlaceItem(name: 'Club', address: '9 West Rd');
      expect(
        mapLinkFor(place, TargetPlatform.android).queryParameters['query'],
        'Club, 9 West Rd',
      );
      expect(mapLinkFor(place, TargetPlatform.iOS).queryParameters, {
        'q': 'Club',
      });
    });

    test('there is something to show only with coordinates or an address', () {
      expect(hasMapTarget(withCoords), isTrue);
      expect(hasMapTarget(const PlaceItem(address: 'x')), isTrue);
      expect(hasMapTarget(const PlaceItem(name: 'x')), isFalse);
    });
  });

  test('session_info carries the distance unit', () {
    expect(
      SessionInfoUser.fromJson({'distance_type': 'dt_miles'}).distanceType,
      'dt_miles',
    );
  });
}
