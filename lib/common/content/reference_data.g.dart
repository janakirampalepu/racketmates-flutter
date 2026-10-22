// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReferenceDataResponse _$ReferenceDataResponseFromJson(
  Map<String, dynamic> json,
) => ReferenceDataResponse(
  referenceData: (json['reference_data'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : ReferenceItem.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$ReferenceDataResponseToJson(
  ReferenceDataResponse instance,
) => <String, dynamic>{'reference_data': instance.referenceData};

ReferenceItem _$ReferenceItemFromJson(Map<String, dynamic> json) =>
    ReferenceItem(
      id: (json['id'] as num?)?.toInt(),
      dataType: json['data_type'] as String?,
      key: json['key'] as String?,
      localizedLabel: json['localized_label'] as String?,
      localizedSubText: json['localized_sub_text'] as String?,
    );

Map<String, dynamic> _$ReferenceItemToJson(ReferenceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data_type': instance.dataType,
      'key': instance.key,
      'localized_label': instance.localizedLabel,
      'localized_sub_text': instance.localizedSubText,
    };
