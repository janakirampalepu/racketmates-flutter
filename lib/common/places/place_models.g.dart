// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlacesListResponse _$PlacesListResponseFromJson(Map<String, dynamic> json) =>
    PlacesListResponse(
      places: (json['places'] as List<dynamic>?)
          ?.map((e) => PlaceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlacesListResponseToJson(PlacesListResponse instance) =>
    <String, dynamic>{'places': instance.places};

PlaceDetailsResponse _$PlaceDetailsResponseFromJson(
  Map<String, dynamic> json,
) => PlaceDetailsResponse(
  place: json['place'] == null
      ? null
      : PlaceItem.fromJson(json['place'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlaceDetailsResponseToJson(
  PlaceDetailsResponse instance,
) => <String, dynamic>{'place': instance.place};

PlaceItem _$PlaceItemFromJson(Map<String, dynamic> json) => PlaceItem(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  address: json['address'] as String?,
  distance: json['distance'] as String?,
  placeType: json['place_type'] as String?,
  addressDetail: json['address_detail'] == null
      ? null
      : PlaceAddress.fromJson(json['address_detail'] as Map<String, dynamic>),
  favourite: json['favourite'] as bool?,
  recent: json['recent'] as bool?,
  requiresMembership: json['requires_membership'] as bool?,
  placeCourts: (json['place_courts'] as List<dynamic>?)
      ?.map((e) => PlaceCourt.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlaceItemToJson(PlaceItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'distance': instance.distance,
  'place_type': instance.placeType,
  'address_detail': instance.addressDetail,
  'favourite': instance.favourite,
  'recent': instance.recent,
  'requires_membership': instance.requiresMembership,
  'place_courts': instance.placeCourts,
};

PlaceAddress _$PlaceAddressFromJson(Map<String, dynamic> json) => PlaceAddress(
  cityName: json['city_name'] as String?,
  stateAbbreviation: json['state_abbreviation'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PlaceAddressToJson(PlaceAddress instance) =>
    <String, dynamic>{
      'city_name': instance.cityName,
      'state_abbreviation': instance.stateAbbreviation,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

PlaceCourt _$PlaceCourtFromJson(Map<String, dynamic> json) => PlaceCourt(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  courtType: json['court_type'] as String?,
  sportType: json['sport_type'] as String?,
);

Map<String, dynamic> _$PlaceCourtToJson(PlaceCourt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'court_type': instance.courtType,
      'sport_type': instance.sportType,
    };
