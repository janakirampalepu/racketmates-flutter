// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMetadata _$AppMetadataFromJson(Map<String, dynamic> json) => AppMetadata(
  referenceDataLastUpdated: (json['reference_data_last_updated'] as num?)
      ?.toInt(),
  resourceStringsLatestVersion:
      (json['resource_strings_latest_version'] as num?)?.toInt(),
  analyticsDataLastUpdated: (json['analytics_data_last_updated'] as num?)
      ?.toInt(),
  appUpgradeCheck: json['app_upgrade_check'] == null
      ? null
      : AppUpgradeCheck.fromJson(
          json['app_upgrade_check'] as Map<String, dynamic>,
        ),
  supportedLanguages: (json['supported_languages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AppMetadataToJson(AppMetadata instance) =>
    <String, dynamic>{
      'reference_data_last_updated': instance.referenceDataLastUpdated,
      'resource_strings_latest_version': instance.resourceStringsLatestVersion,
      'analytics_data_last_updated': instance.analyticsDataLastUpdated,
      'app_upgrade_check': instance.appUpgradeCheck,
      'supported_languages': instance.supportedLanguages,
    };
