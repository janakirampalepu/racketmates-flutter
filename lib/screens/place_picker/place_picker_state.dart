import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';

enum PlaceTab { search, favourites }

class PlaceListState {
  const PlaceListState({
    this.places = const [],
    this.loading = true,
    this.failure,
  });

  final List<PlaceItem> places;
  final bool loading;
  final AppFailure? failure;

  bool get isEmpty => !loading && failure == null && places.isEmpty;

  PlaceListState copyWith({
    List<PlaceItem>? places,
    bool? loading,
    AppFailure? Function()? failure,
  }) => PlaceListState(
    places: places ?? this.places,
    loading: loading ?? this.loading,
    failure: failure != null ? failure() : this.failure,
  );
}

class PlacePickerState {
  const PlacePickerState({
    this.query = '',
    this.search = const PlaceListState(),
    this.favourites = const PlaceListState(),
    this.togglingFavouriteFor,
  });

  final String query;
  final PlaceListState search;
  final PlaceListState favourites;
  final int? togglingFavouriteFor;

  PlacePickerState copyWith({
    String? query,
    PlaceListState? search,
    PlaceListState? favourites,
    int? Function()? togglingFavouriteFor,
  }) => PlacePickerState(
    query: query ?? this.query,
    search: search ?? this.search,
    favourites: favourites ?? this.favourites,
    togglingFavouriteFor: togglingFavouriteFor != null
        ? togglingFavouriteFor()
        : this.togglingFavouriteFor,
  );
}
