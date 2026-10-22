import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/screens/place_picker/place_picker_test_ids.dart';
import 'package:racketmates/screens/place_picker/place_picker_view_model.dart';
import 'package:racketmates/screens/place_picker/place_picker_screen.dart';

import '../../support/fakes.dart';

const _central = PlaceItem(
  id: 1,
  name: 'Central Courts',
  address: '1 Main St',
  distance: '2 mi',
);
const _west = PlaceItem(
  id: 2,
  name: 'Club West',
  address: '9 West Rd',
  favourite: true,
);

Finder _id(String id) => find.bySemanticsIdentifier(id);

Widget _host(FakePlacesRepository repo, {ValueSetter<PlaceItem?>? onResult}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final place = await context.push<PlaceItem>('/picker');
              onResult?.call(place);
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/picker',
        builder: (context, _) =>
            const PlacePickerScreen(sportType: 'st_tennis'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [placesRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('PlacePickerViewModel', () {
    ProviderContainer container(FakePlacesRepository repo) {
      final c = ProviderContainer(
        overrides: [placesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'loads the search list (all place types, sport filter) and favourites',
      () async {
        final repo = FakePlacesRepository(
          places: [_central, _west],
          favouritePlaces: [_west],
        );
        final c = container(repo);
        final provider = placePickerViewModelProvider('st_tennis');
        final sub = c.listen(provider, (_, _) {});
        addTearDown(sub.close);
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(c.read(provider).search.places, hasLength(2));
        expect(c.read(provider).favourites.places.single.id, 2);
        expect(repo.searches.single.sport, 'st_tennis');
      },
    );

    test(
      'typing is debounced into a single search and stale answers are ignored',
      () {
        fakeAsync((async) {
          final repo = FakePlacesRepository(places: [_central, _west]);
          final c = container(repo);
          final provider = placePickerViewModelProvider(null);
          final sub = c.listen(provider, (_, _) {});
          async.flushMicrotasks();
          repo.searches.clear();

          final vm = c.read(provider.notifier);
          vm
            ..setQuery('c')
            ..setQuery('ce')
            ..setQuery('cen');
          async.elapse(placeSearchDebounce - const Duration(milliseconds: 1));
          expect(repo.searches, isEmpty);
          async.elapse(const Duration(milliseconds: 2));
          async.flushMicrotasks();
          expect(repo.searches.map((s) => s.query), ['cen']);
          expect(c.read(provider).search.places.single.name, 'Central Courts');
          sub.close();
        });
      },
    );

    test('a failed search can be retried', () async {
      final repo = FakePlacesRepository(places: [_central])..failing = true;
      final c = container(repo);
      final provider = placePickerViewModelProvider(null);
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.read(provider).search.failure, isNotNull);
      repo.failing = false;
      await c.read(provider.notifier).loadSearch();
      expect(c.read(provider).search.places, hasLength(1));
      expect(c.read(provider).search.failure, isNull);
    });

    test(
      'favouriting updates both lists; failures leave them unchanged',
      () async {
        final repo = FakePlacesRepository(
          places: [_central, _west],
          favouritePlaces: [_west],
        );
        final c = container(repo);
        final provider = placePickerViewModelProvider(null);
        final sub = c.listen(provider, (_, _) {});
        addTearDown(sub.close);
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        await c.read(provider.notifier).toggleFavourite(_central);
        expect(repo.favouriteCalls, [(1, true)]);
        expect(c.read(provider).search.places.first.favourite, isTrue);
        expect(
          c.read(provider).favourites.places.map((p) => p.id),
          containsAll([1, 2]),
        );

        repo.failing = true;
        await c.read(provider.notifier).toggleFavourite(_west);
        expect(c.read(provider).togglingFavouriteFor, isNull);
        expect(
          c.read(provider).favourites.places.map((p) => p.id),
          containsAll([1, 2]),
        );
      },
    );
  });

  group('PlacePickerScreen', () {
    testWidgets('lists venues, searches, and returns the chosen one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakePlacesRepository(places: [_central, _west]);
      PlaceItem? result;
      await tester.pumpWidget(_host(repo, onResult: (p) => result = p));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(_id(PlacePickerTestIds.place(1)), findsOneWidget);
      expect(_id(PlacePickerTestIds.place(2)), findsOneWidget);
      expect(find.text('1 Main St · 2 mi'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: _id(PlacePickerTestIds.search),
          matching: find.byType(TextField),
        ),
        'west',
      );
      await tester.pump(placeSearchDebounce + const Duration(milliseconds: 10));
      await tester.pumpAndSettle();
      expect(_id(PlacePickerTestIds.place(1)), findsNothing);
      expect(repo.searches.last.query, 'west');

      await tester.tap(_id(PlacePickerTestIds.place(2)));
      await tester.pumpAndSettle();
      expect(result?.id, 2);
      handle.dispose();
    });

    testWidgets('favourites tab, empty state and error with retry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakePlacesRepository(places: [_central]);
      await tester.pumpWidget(_host(repo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(_id(PlacePickerTestIds.tabFavourites));
      await tester.pumpAndSettle();
      expect(find.text('You have no favourite venues yet.'), findsOneWidget);

      repo.failing = true;
      await tester.tap(_id(PlacePickerTestIds.tabSearch));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: _id(PlacePickerTestIds.search),
          matching: find.byType(TextField),
        ),
        'x',
      );
      await tester.pump(placeSearchDebounce + const Duration(milliseconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Could not load venues.'), findsOneWidget);
      repo.failing = false;
      await tester.tap(_id(PlacePickerTestIds.retry));
      await tester.pumpAndSettle();
      expect(find.text('Could not load venues.'), findsNothing);
      handle.dispose();
    });

    testWidgets('star button toggles a favourite', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakePlacesRepository(places: [_central, _west]);
      await tester.pumpWidget(_host(repo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(_id(PlacePickerTestIds.favourite(1)));
      await tester.pumpAndSettle();
      expect(repo.favouriteCalls, [(1, true)]);
      handle.dispose();
    });
  });
}
