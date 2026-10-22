import 'package:dio/dio.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:retrofit/retrofit.dart';

part 'places_api.g.dart';

/// Existing `places` endpoints (native `ApiServices`).
@RestApi()
abstract class PlacesApi {
  factory PlacesApi(Dio dio, {String? baseUrl}) = _PlacesApi;

  @GET('places')
  Future<PlacesListResponse> search({
    @Query('place_types[]') List<String>? placeTypes,
    @Query('latitude') String? latitude,
    @Query('longitude') String? longitude,
    @Query('distance') int? distance,
    @Query('per_page') int? perPage,
    @Query('search') String? search,
    @Query('exclude_logged_in_user_club_ids') bool? excludeLoggedInUserClubIds,
    @Query('include_tennis_courts') String? includeTennisCourts,
    @Query('sport_type') String? sportType,
  });

  @GET('current_session/my_favourite_places')
  Future<PlacesListResponse> favourites();

  @GET('places/{id}')
  Future<PlaceDetailsResponse> details(@Path('id') int id);

  @PUT('places/{id}/mark_as_favourite')
  Future<void> markAsFavourite(@Path('id') int id);

  @PUT('places/{id}/remove_from_favourites')
  Future<void> removeFromFavourites(@Path('id') int id);
}
