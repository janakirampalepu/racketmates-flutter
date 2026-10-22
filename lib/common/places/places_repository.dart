import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_api.dart';

/// All place types, the native default filter (`placeTypeSet.size == 5`).
const allPlaceTypes = [
  'pt_club',
  'pt_school',
  'pt_park',
  'pt_community_center',
  'pt_other',
];

/// Native page size for place searches (`VALUE_TWENTY`).
const placesPageSize = 20;

abstract class PlacesRepository {
  /// Text search. [sportType] limits to places with courts for that sport
  /// (`st_tennis`, ...). Location-based ordering (latitude/longitude/distance)
  /// is added with the locations milestone.
  Future<List<PlaceItem>> search({String query = '', String? sportType});

  Future<List<PlaceItem>> favourites();

  /// Full place (with courts).
  Future<PlaceItem> details(int id);

  Future<void> setFavourite(int id, {required bool favourite});
}

class PlacesRepositoryImpl implements PlacesRepository {
  const PlacesRepositoryImpl(this.api);

  final PlacesApi api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<List<PlaceItem>> search({String query = '', String? sportType}) async {
    final response = await _guard(
      () => api.search(
        placeTypes: allPlaceTypes,
        perPage: placesPageSize,
        search: query.trim(),
        excludeLoggedInUserClubIds: false,
        sportType: sportType,
      ),
    );
    return response.places ?? const [];
  }

  @override
  Future<List<PlaceItem>> favourites() async =>
      (await _guard(api.favourites)).places ?? const [];

  @override
  Future<PlaceItem> details(int id) async {
    final place = (await _guard(() => api.details(id))).place;
    if (place == null) throw const ParseFailure('place missing');
    return place;
  }

  @override
  Future<void> setFavourite(int id, {required bool favourite}) => _guard(
    () => favourite ? api.markAsFavourite(id) : api.removeFromFavourites(id),
  );
}

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepositoryImpl(PlacesApi(ref.watch(apiDioProvider))),
);
