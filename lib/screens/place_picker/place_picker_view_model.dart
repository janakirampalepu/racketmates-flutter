import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/location/user_location.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/screens/place_picker/place_picker_state.dart';

/// Search debounce (typing pauses before the request).
const placeSearchDebounce = Duration(milliseconds: 400);

class PlacePickerViewModel extends Notifier<PlacePickerState> {
  PlacePickerViewModel(this.sportType);

  /// Backend sport key limiting the search (`st_tennis`), or null.
  final String? sportType;
  Timer? _debounce;
  int _searchToken = 0;

  @override
  PlacePickerState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() async {
      // Nearby venues first: ask for the position (once), then search.
      await ref.read(userLocationProvider.notifier).ensure();
      if (!ref.mounted) return;
      await Future.wait([loadSearch(), loadFavourites()]);
    });
    return const PlacePickerState();
  }

  PlacesRepository get _repo => ref.read(placesRepositoryProvider);

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(placeSearchDebounce, loadSearch);
  }

  Future<void> loadSearch() async {
    final token = ++_searchToken;
    state = state.copyWith(
      search: state.search.copyWith(loading: true, failure: () => null),
    );
    try {
      final location = ref.read(userLocationProvider).position;
      final places = await _repo.search(
        query: state.query,
        sportType: sportType,
        latitude: location?.latitude,
        longitude: location?.longitude,
        distance: location == null
            ? null
            : ref.read(searchDistanceProvider).value ?? defaultSearchDistance,
      );
      // Ignore answers to a query the user has already replaced.
      if (!ref.mounted || token != _searchToken) return;
      state = state.copyWith(
        search: PlaceListState(places: places, loading: false),
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted || token != _searchToken) return;
      state = state.copyWith(
        search: PlaceListState(loading: false, failure: failure),
      );
    }
  }

  Future<void> loadFavourites() async {
    state = state.copyWith(
      favourites: state.favourites.copyWith(loading: true, failure: () => null),
    );
    try {
      final places = await _repo.favourites();
      if (!ref.mounted) return;
      state = state.copyWith(
        favourites: PlaceListState(places: places, loading: false),
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        favourites: PlaceListState(loading: false, failure: failure),
      );
    }
  }

  /// Adds/removes a favourite and reflects it in both lists.
  Future<void> toggleFavourite(PlaceItem place) async {
    final id = place.id;
    if (id == null || state.togglingFavouriteFor != null) return;
    final makeFavourite = !(place.favourite ?? false);
    state = state.copyWith(togglingFavouriteFor: () => id);
    try {
      await _repo.setFavourite(id, favourite: makeFavourite);
      if (!ref.mounted) return;
      PlaceListState update(PlaceListState list) => list.copyWith(
        places: [
          for (final p in list.places)
            if (p.id == id) p.copyWith(favourite: makeFavourite) else p,
        ],
      );
      state = state.copyWith(
        search: update(state.search),
        togglingFavouriteFor: () => null,
      );
      await loadFavourites();
    } on AppFailure {
      if (!ref.mounted) return;
      state = state.copyWith(togglingFavouriteFor: () => null);
    }
  }
}

final placePickerViewModelProvider = NotifierProvider.autoDispose
    .family<PlacePickerViewModel, PlacePickerState, String?>(
      PlacePickerViewModel.new,
    );
