import 'package:json_annotation/json_annotation.dart';

part 'reference_data.g.dart';

/// `GET reference_data` response.
@JsonSerializable(fieldRename: FieldRename.snake)
class ReferenceDataResponse {
  const ReferenceDataResponse({this.referenceData});

  factory ReferenceDataResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferenceDataResponseFromJson(json);

  final List<ReferenceItem?>? referenceData;

  Map<String, dynamic> toJson() => _$ReferenceDataResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ReferenceItem {
  const ReferenceItem({
    this.id,
    this.dataType,
    this.key,
    this.localizedLabel,
    this.localizedSubText,
  });

  factory ReferenceItem.fromJson(Map<String, dynamic> json) =>
      _$ReferenceItemFromJson(json);

  final int? id;
  final String? dataType;
  final String? key;
  final String? localizedLabel;
  final String? localizedSubText;

  Map<String, dynamic> toJson() => _$ReferenceItemToJson(this);
}

/// `data_type` values (native `SharePrefKeys`).
abstract final class ReferenceTypes {
  static const eventType = 'event_type';
  static const eventSubType = 'event_sub_type';
  static const eventStatus = 'event_status';
  static const eventUserStatus = 'event_user_status';
  static const eventMatchStatus = 'event_match_status';
  static const matchType = 'match_type';
  static const scoringFormat = 'scoring_format';
  static const decidingSetType = 'deciding_set_type';
  static const attendanceDeadlineUnitType = 'attendance_deadline_unit_type';
  static const reminderUnitType = 'reminder_unit_type';
  static const distanceType = 'distance_type';
  static const placeType = 'place_type';
  static const teamType = 'team_type';
  static const rankingPeriodDuration = 'ranking_period_duration';
}

/// Backend enumerations with localized labels: the lists the pickers show and
/// the label for any key (`et_casual` -> "Casual game"). Replaces the
/// humanized-key fallback once loaded.
class ReferenceData {
  ReferenceData(Iterable<ReferenceItem> items) : _items = List.of(items) {
    for (final item in _items) {
      final key = item.key;
      if (key != null) _byKey[key] = item;
    }
  }

  factory ReferenceData.fromResponse(ReferenceDataResponse response) =>
      ReferenceData(
        response.referenceData?.whereType<ReferenceItem>() ?? const [],
      );

  static final empty = ReferenceData(const []);

  final List<ReferenceItem> _items;
  final Map<String, ReferenceItem> _byKey = {};

  bool get isEmpty => _items.isEmpty;

  /// Items of one `data_type`; event types are ordered by id (native).
  List<ReferenceItem> ofType(String dataType) {
    final list = [
      for (final i in _items)
        if (i.dataType == dataType) i,
    ];
    if (dataType == ReferenceTypes.eventType) {
      list.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    }
    return list;
  }

  String? label(String? key) =>
      key == null ? null : _byKey[key]?.localizedLabel;

  String? subText(String? key) =>
      key == null ? null : _byKey[key]?.localizedSubText;

  List<Map<String, dynamic>> toJsonList() => [
    for (final i in _items) i.toJson(),
  ];
}
