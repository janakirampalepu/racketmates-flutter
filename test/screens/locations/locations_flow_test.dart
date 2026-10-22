import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/location/location_platform.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/locations/locations_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

const _central = PlaceItem(
  id: 1,
  name: 'Central Courts',
  address: '1 Main St',
  distance: '2 mi',
  placeType: 'pt_club',
  requiresMembership: true,
  addressDetail: PlaceAddress(latitude: 40.1, longitude: -73.9),
  placeCourts: [
    PlaceCourt(
      id: 10,
      name: 'Court 1',
      courtType: 'ct_indoor',
      sportType: 'st_tennis',
    ),
    PlaceCourt(id: 11, name: 'Court 2', courtType: 'ct_outdoor'),
  ],
);
const _west = PlaceItem(
  id: 2,
  name: 'Club West',
  address: '9 West Rd',
  distance: '5 mi',
  favourite: true,
);

Future<void> _openLocations(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(HomeTestIds.settingsButton));
  await tester.pumpAndSettle();
  await tester.tap(_id(SettingsTestIds.locations));
  await tester.pumpAndSettle();
}

FakePlacesRepository _places() => FakePlacesRepository(
  places: [_central, _west],
  favouritePlaces: [_west],
  detailsById: {1: _central, 2: _west},
);

void main() {
  group('locations list', () {
    testWidgets('lists venues near the user with their distance', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      final platform = FakeLocationPlatform();
      await tester.pumpWidget(signedInApp(places: places, location: platform));
      await _openLocations(tester);
      expect(_id(LocationsTestIds.root), findsOneWidget);
      expect(find.text('Central Courts'), findsOneWidget);
      expect(find.textContaining('2 mi'), findsOneWidget);
      expect(
        find.textContaining('Near your current location · Within 30 mi'),
        findsOneWidget,
      );
      expect(places.locations.last, (
        latitude: 40.7128,
        longitude: -74.006,
        distance: 30,
      ));
      expect(platform.requests, 1);
      handle.dispose();
    });

    testWidgets('without permission it searches by text and offers settings', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      final platform = FakeLocationPlatform(
        answerToRequest: LocationPermission.denied,
      );
      await tester.pumpWidget(signedInApp(places: places, location: platform));
      await _openLocations(tester);
      expect(find.text('Central Courts'), findsOneWidget);
      expect(places.locations.last.latitude, isNull);
      expect(_id(LocationsTestIds.filterButton), findsNothing);
      await tester.tap(_id(LocationsTestIds.openSettings));
      expect(platform.settingsOpened, 1);
      handle.dispose();
    });

    testWidgets('the distance filter narrows the search and can be reset', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      final store = InMemoryDistanceStore();
      await tester.pumpWidget(
        signedInApp(places: places, distanceStore: store),
      );
      await _openLocations(tester);
      await tester.tap(_id(LocationsTestIds.filterButton));
      await tester.pumpAndSettle();
      expect(_id(LocationsTestIds.filterSheet), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(15);
      await tester.pump();
      await tester.tap(_id(LocationsTestIds.filterApply));
      await tester.pumpAndSettle();
      expect(store.value, 15);
      expect(places.locations.last.distance, 15);
      expect(find.textContaining('Within 15 mi'), findsOneWidget);

      await tester.tap(_id(LocationsTestIds.filterButton));
      await tester.pumpAndSettle();
      await tester.tap(_id(LocationsTestIds.filterReset));
      await tester.pumpAndSettle();
      expect(store.value, 30);
      expect(places.locations.last.distance, 30);
      handle.dispose();
    });

    testWidgets('searching by name', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      await tester.pumpWidget(signedInApp(places: places));
      await _openLocations(tester);
      await tester.enterText(find.byType(TextField), 'west');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(places.searches.last.query, 'west');
      expect(find.text('Club West'), findsOneWidget);
      expect(find.text('Central Courts'), findsNothing);
      handle.dispose();
    });

    testWidgets('favourites tab and the star', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      await tester.pumpWidget(signedInApp(places: places));
      await _openLocations(tester);
      await tester.tap(_id(LocationsTestIds.tabFavourites));
      await tester.pumpAndSettle();
      expect(find.text('Club West'), findsOneWidget);
      expect(find.text('Central Courts'), findsNothing);
      await tester.tap(_id(LocationsTestIds.tabNearby));
      await tester.pumpAndSettle();
      await tester.tap(_id(LocationsTestIds.favourite(1)));
      await tester.pumpAndSettle();
      expect(places.favouriteCalls, [(1, true)]);
      handle.dispose();
    });

    testWidgets('an empty list and a failing search', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = FakePlacesRepository();
      await tester.pumpWidget(signedInApp(places: places));
      await _openLocations(tester);
      expect(_id(LocationsTestIds.empty), findsWidgets);
      places.failing = true;
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(_id(LocationsTestIds.error), findsOneWidget);
      places.failing = false;
      await tester.tap(_id(LocationsTestIds.retry));
      await tester.pumpAndSettle();
      expect(_id(LocationsTestIds.error), findsNothing);
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('meets guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(signedInApp(places: _places()));
        await _openLocations(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('venue page', () {
    Future<void> openCentral(
      WidgetTester tester, {
      FakePlacesRepository? places,
      FakeExternalLinks? links,
    }) async {
      await tester.pumpWidget(
        signedInApp(places: places ?? _places(), links: links),
      );
      await _openLocations(tester);
      await tester.tap(_id(LocationsTestIds.place(1)));
      await tester.pumpAndSettle();
    }

    testWidgets('shows address, distance, membership and courts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await openCentral(tester);
      expect(_id(VenueTestIds.root), findsOneWidget);
      expect(find.text('1 Main St'), findsOneWidget);
      expect(_id(VenueTestIds.distance), findsOneWidget);
      expect(_id(VenueTestIds.membership), findsOneWidget);
      expect(_id(VenueTestIds.court(10)), findsOneWidget);
      expect(find.textContaining('Indoor'), findsOneWidget);
      expect(find.textContaining('Outdoor'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('directions open the map app', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final links = FakeExternalLinks();
      await openCentral(tester, links: links);
      await tester.tap(_id(VenueTestIds.directions));
      expect(links.opened.single.host, 'www.google.com');
      expect(links.opened.single.queryParameters['query'], '40.1,-73.9');
      handle.dispose();
    });

    testWidgets('a venue without courts or a location', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          places: FakePlacesRepository(
            places: const [PlaceItem(id: 3, name: 'Park')],
            detailsById: const {3: PlaceItem(id: 3, name: 'Park')},
          ),
        ),
      );
      await _openLocations(tester);
      await tester.tap(_id(LocationsTestIds.place(3)));
      await tester.pumpAndSettle();
      expect(_id(VenueTestIds.noCourts), findsOneWidget);
      expect(_id(VenueTestIds.directions), findsNothing);
      handle.dispose();
    });

    testWidgets('the star works from the venue page', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = _places();
      await openCentral(tester, places: places);
      await tester.tap(_id(VenueTestIds.favourite));
      await tester.pumpAndSettle();
      expect(places.favouriteCalls, [(1, true)]);
      expect(find.byIcon(Icons.star), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a venue that fails to load can be retried', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final places = FakePlacesRepository(
        places: [_central],
        detailsById: const {},
      );
      await openCentral(tester, places: places);
      expect(_id(VenueTestIds.error), findsOneWidget);
      places.detailsById = {1: _central};
      await tester.tap(_id(VenueTestIds.retry));
      await tester.pumpAndSettle();
      expect(_id(VenueTestIds.court(10)), findsOneWidget);
      handle.dispose();
    });

    testWidgets('iOS opens Apple Maps', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final links = FakeExternalLinks();
      await openCentral(tester, links: links);
      await tester.tap(_id(VenueTestIds.directions));
      expect(links.opened.single.host, 'maps.apple.com');
      debugDefaultTargetPlatformOverride = null;
      handle.dispose();
    });
  });
}
