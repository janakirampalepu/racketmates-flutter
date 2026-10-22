import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/auth/models/app_upgrade_check.dart';

part 'app_metadata.g.dart';

/// Response of `GET resources/metadata`. Version numbers let the app skip
/// refetching reference data / resource strings / analytics settings.
@JsonSerializable(fieldRename: FieldRename.snake)
class AppMetadata {
  const AppMetadata({
    this.referenceDataLastUpdated,
    this.resourceStringsLatestVersion,
    this.analyticsDataLastUpdated,
    this.appUpgradeCheck,
    this.supportedLanguages,
  });

  factory AppMetadata.fromJson(Map<String, dynamic> json) =>
      _$AppMetadataFromJson(json);

  final int? referenceDataLastUpdated;
  final int? resourceStringsLatestVersion;
  final int? analyticsDataLastUpdated;
  final AppUpgradeCheck? appUpgradeCheck;
  final List<String>? supportedLanguages;

  Map<String, dynamic> toJson() => _$AppMetadataToJson(this);
}
