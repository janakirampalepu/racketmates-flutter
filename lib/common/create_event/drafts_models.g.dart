// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drafts_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftSummary _$DraftSummaryFromJson(Map<String, dynamic> json) => DraftSummary(
  eventId: (json['event_id'] as num?)?.toInt(),
  eventType: json['event_type'] as String?,
  sportType: json['sport_type'] as String?,
  courtsLabel: json['courts_label'] as String?,
  lastUpdatedAt: json['last_updated_at'] as String?,
);

Map<String, dynamic> _$DraftSummaryToJson(DraftSummary instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'event_type': instance.eventType,
      'sport_type': instance.sportType,
      'courts_label': instance.courtsLabel,
      'last_updated_at': instance.lastUpdatedAt,
    };

DraftsResponse _$DraftsResponseFromJson(Map<String, dynamic> json) =>
    DraftsResponse(
      scheduleItems: (json['schedule_items'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : DraftSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$DraftsResponseToJson(DraftsResponse instance) =>
    <String, dynamic>{'schedule_items': instance.scheduleItems};
