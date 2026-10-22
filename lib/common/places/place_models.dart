import 'package:json_annotation/json_annotation.dart';

part 'place_models.g.dart';

/// `GET places` and `GET current_session/my_favourite_places` response.
@JsonSerializable(fieldRename: FieldRename.snake)
class PlacesListResponse {
  const PlacesListResponse({this.places});

  factory PlacesListResponse.fromJson(Map<String, dynamic> json) =>
      _$PlacesListResponseFromJson(json);

  final List<PlaceItem>? places;

  Map<String, dynamic> toJson() => _$PlacesListResponseToJson(this);
}

/// `GET places/{id}` response.
@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceDetailsResponse {
  const PlaceDetailsResponse({this.place});

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaceDetailsResponseFromJson(json);

  final PlaceItem? place;

  Map<String, dynamic> toJson() => _$PlaceDetailsResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceItem {
  const PlaceItem({
    this.id,
    this.name,
    this.address,
    this.distance,
    this.placeType,
    this.addressDetail,
    this.favourite,
    this.recent,
    this.requiresMembership,
    this.placeCourts,
  });

  factory PlaceItem.fromJson(Map<String, dynamic> json) =>
      _$PlaceItemFromJson(json);

  final int? id;
  final String? name;
  final String? address;

  /// Server-formatted distance text, when the request carried a location.
  final String? distance;

  /// `pt_club`, `pt_school`, `pt_park`, `pt_community_center`, `pt_other`.
  final String? placeType;
  final PlaceAddress? addressDetail;
  final bool? favourite;
  final bool? recent;
  final bool? requiresMembership;
  final List<PlaceCourt>? placeCourts;

  Map<String, dynamic> toJson() => _$PlaceItemToJson(this);

  PlaceItem copyWith({bool? favourite, List<PlaceCourt>? placeCourts}) =>
      PlaceItem(
        id: id,
        name: name,
        address: address,
        distance: distance,
        placeType: placeType,
        addressDetail: addressDetail,
        favourite: favourite ?? this.favourite,
        recent: recent,
        requiresMembership: requiresMembership,
        placeCourts: placeCourts ?? this.placeCourts,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceAddress {
  const PlaceAddress({
    this.cityName,
    this.stateAbbreviation,
    this.latitude,
    this.longitude,
  });

  factory PlaceAddress.fromJson(Map<String, dynamic> json) =>
      _$PlaceAddressFromJson(json);

  final String? cityName;
  final String? stateAbbreviation;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => _$PlaceAddressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceCourt {
  const PlaceCourt({this.id, this.name, this.courtType, this.sportType});

  factory PlaceCourt.fromJson(Map<String, dynamic> json) =>
      _$PlaceCourtFromJson(json);

  final int? id;
  final String? name;

  /// `ct_indoor` / `ct_outdoor`.
  final String? courtType;
  final String? sportType;

  Map<String, dynamic> toJson() => _$PlaceCourtToJson(this);
}
