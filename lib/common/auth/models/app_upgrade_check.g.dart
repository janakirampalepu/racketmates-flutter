// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_upgrade_check.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUpgradeCheck _$AppUpgradeCheckFromJson(Map<String, dynamic> json) =>
    AppUpgradeCheck(
      upgradeRequired: json['upgrade_required'] as bool?,
      upgradeType: json['upgrade_type'] as String?,
      newVersionNumber: json['new_version_number'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$AppUpgradeCheckToJson(AppUpgradeCheck instance) =>
    <String, dynamic>{
      'upgrade_required': instance.upgradeRequired,
      'upgrade_type': instance.upgradeType,
      'new_version_number': instance.newVersionNumber,
      'notes': instance.notes,
    };
