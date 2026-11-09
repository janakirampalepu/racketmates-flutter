import 'package:json_annotation/json_annotation.dart';

part 'place_models.g.dart';

/// Tolerates `distance` arriving as either a JSON number or a numeric
/// string — confirmed on a real device that the backend sends both across
/// different records in the very same `GET places` response (a first
/// search failed with "type 'double' is not a subtype of type 'String?'",
/// a second with the opposite: "type 'String' is not a subtype of type
/// 'num?'"). A plain `double?`/`String?` field is strict in either
/// direction with `json_serializable`; Android's own Gson-based model
/// never notices this inconsistency because Gson silently coerces either
/// shape into whichever Kotlin type the field declares.
class LenientDoubleConverter implements JsonConverter<double?, Object?> {
  const LenientDoubleConverter();

  @override
  double? fromJson(Object? json) => switch (json) {
    null => null,
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  @override
  Object? toJson(double? object) => object;
}

/// Same tolerance as [LenientDoubleConverter], for an id field. Applied
/// defensively to every id on this response (not just the one confirmed
/// inconsistent field, `distance`) since the backend has shown it isn't
/// reliably typed for this endpoint.
class LenientIntConverter implements JsonConverter<int?, Object?> {
  const LenientIntConverter();

  @override
  int? fromJson(Object? json) => switch (json) {
    null => null,
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };

  @override
  Object? toJson(int? object) => object;
}

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

  @LenientIntConverter()
  final int? id;
  final String? name;
  final String? address;

  /// Distance from the search position, in the user's unit, when the
  /// request carried a location — a number, not pre-formatted text (this
  /// field used to be typed `String?`, matching Android's own model; both
  /// were wrong — see `LenientDoubleConverter` above for the real, observed
  /// shape). iOS's own `RacketmatesPlace.distance` is `Double?` and formats
  /// it client-side (`String(format: "%.2f", distance)` + the unit) — see
  /// `formatDistance` below, which matches that exactly.
  @LenientDoubleConverter()
  final double? distance;

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

/// `"10.74 mi"` — matches iOS's `showDistanceString`
/// (`String(format: "%.2f", distance) + " " + unit`). Null for no distance
/// (no search position) or a zero distance (iOS treats 0 as "no distance"
/// too, `distance != 0`).
String? formatDistance(double? distance, String unit) =>
    distance == null || distance == 0
    ? null
    : '${distance.toStringAsFixed(2)} $unit';

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

  /// Same real-device-confirmed leniency-vs-strictness mismatch as
  /// `PlaceItem.distance` — the backend is not observed to be reliably
  /// typed for every numeric field on this response.
  @LenientDoubleConverter()
  final double? latitude;
  @LenientDoubleConverter()
  final double? longitude;

  Map<String, dynamic> toJson() => _$PlaceAddressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceCourt {
  const PlaceCourt({this.id, this.name, this.courtType, this.sportType});

  factory PlaceCourt.fromJson(Map<String, dynamic> json) =>
      _$PlaceCourtFromJson(json);

  @LenientIntConverter()
  final int? id;
  final String? name;

  /// `ct_indoor` / `ct_outdoor`.
  final String? courtType;
  final String? sportType;

  Map<String, dynamic> toJson() => _$PlaceCourtToJson(this);
}
