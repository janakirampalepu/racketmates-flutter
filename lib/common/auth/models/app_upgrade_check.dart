import 'package:json_annotation/json_annotation.dart';

part 'app_upgrade_check.g.dart';

/// `app_upgrade_check` object of `GET resources/metadata`.
@JsonSerializable(fieldRename: FieldRename.snake)
class AppUpgradeCheck {
  const AppUpgradeCheck({
    this.upgradeRequired,
    this.upgradeType,
    this.newVersionNumber,
    this.notes,
  });

  factory AppUpgradeCheck.fromJson(Map<String, dynamic> json) =>
      _$AppUpgradeCheckFromJson(json);

  final bool? upgradeRequired;

  /// `mandatory` or `optional`.
  final String? upgradeType;
  final String? newVersionNumber;
  final String? notes;

  Map<String, dynamic> toJson() => _$AppUpgradeCheckToJson(this);

  bool get isMandatory => upgradeType == 'mandatory';
}
