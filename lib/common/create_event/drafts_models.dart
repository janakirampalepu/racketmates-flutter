import 'package:json_annotation/json_annotation.dart';

part 'drafts_models.g.dart';

/// One saved draft in the list (native `DraftEvent`).
@JsonSerializable(fieldRename: FieldRename.snake)
class DraftSummary {
  const DraftSummary({
    this.eventId,
    this.eventType,
    this.sportType,
    this.courtsLabel,
    this.lastUpdatedAt,
  });

  factory DraftSummary.fromJson(Map<String, dynamic> json) =>
      _$DraftSummaryFromJson(json);

  final int? eventId;
  final String? eventType;
  final String? sportType;
  final String? courtsLabel;

  /// ISO timestamp of the last save.
  final String? lastUpdatedAt;

  Map<String, dynamic> toJson() => _$DraftSummaryToJson(this);

  DateTime? get updatedAt =>
      lastUpdatedAt == null ? null : DateTime.tryParse(lastUpdatedAt!);
}

/// `GET schedule/drafts`.
@JsonSerializable(fieldRename: FieldRename.snake)
class DraftsResponse {
  const DraftsResponse({this.scheduleItems});

  factory DraftsResponse.fromJson(Map<String, dynamic> json) =>
      _$DraftsResponseFromJson(json);

  final List<DraftSummary?>? scheduleItems;

  Map<String, dynamic> toJson() => _$DraftsResponseToJson(this);
}
