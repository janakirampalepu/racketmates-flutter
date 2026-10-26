import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/config/config_providers.dart';

/// An incident or maintenance window from the Statuspage (native
/// `BaseIncident`): its name, the latest update text and, for maintenance,
/// when it ends.
class Incident {
  const Incident({
    required this.name,
    this.message = '',
    this.scheduledUntil,
    this.components = const [],
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final updates = json['incident_updates'];
    final firstUpdate = updates is List && updates.isNotEmpty
        ? updates.first
        : null;
    return Incident(
      name: json['name'] as String? ?? '',
      message: firstUpdate is Map<String, dynamic>
          ? firstUpdate['body'] as String? ?? ''
          : '',
      scheduledUntil: DateTime.tryParse(
        json['scheduled_until'] as String? ?? '',
      ),
      components: [
        for (final c in (json['components'] as List?) ?? const [])
          if (c is Map<String, dynamic> && c['name'] is String)
            c['name'] as String,
      ],
    );
  }

  final String name;
  final String message;

  /// End of a scheduled maintenance, when there is one.
  final DateTime? scheduledUntil;
  final List<String> components;

  bool affects(String component) => components.contains(component);
}

/// The first incident among [incidents] that affects [component].
Incident? firstAffecting(Iterable<Incident> incidents, String component) {
  for (final i in incidents) {
    if (i.affects(component)) return i;
  }
  return null;
}

abstract class DowntimeRepository {
  /// The incident taking the API down right now (`unresolved`), or null (also
  /// when the status page cannot be reached: the check never blocks on its
  /// own failure). Drives the full-screen gate (native
  /// `CompleteDowntimeActivity`).
  Future<Incident?> currentIncident();

  /// A maintenance window that is scheduled or under way (`active_maintenance`)
  /// but does not block use of the app: native's dismissible home-screen
  /// banner (`showMaintenanceBanner`/iOS `appScheduledDownTimeBanner`), kept
  /// separate from the blocking check above.
  Future<Incident?> scheduledMaintenance();
}

/// Native `refreshServerStatus`: `pages/{id}/incidents/unresolved` blocks the
/// app; `.../active_maintenance` only informs it (see [scheduledMaintenance]).
/// Both are matched on the API component's name.
class StatusPageDowntimeRepository implements DowntimeRepository {
  const StatusPageDowntimeRepository({
    required this.dio,
    required this.pageId,
    required this.apiKey,
    required this.component,
  });

  final Dio dio;
  final String pageId;
  final String apiKey;
  final String component;

  Future<List<Incident>> _incidents(String kind) async {
    final response = await dio.get<List<dynamic>>(
      'pages/$pageId/incidents/$kind',
      queryParameters: {'api_key': apiKey},
    );
    return [
      for (final j in response.data ?? const [])
        if (j is Map<String, dynamic>) Incident.fromJson(j),
    ];
  }

  @override
  Future<Incident?> currentIncident() async {
    if (pageId.isEmpty || apiKey.isEmpty) return null;
    try {
      return firstAffecting(await _incidents('unresolved'), component);
    } on DioException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<Incident?> scheduledMaintenance() async {
    if (pageId.isEmpty || apiKey.isEmpty) return null;
    try {
      return firstAffecting(await _incidents('active_maintenance'), component);
    } on DioException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

final downtimeRepositoryProvider = Provider<DowntimeRepository>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return StatusPageDowntimeRepository(
    dio: Dio(
      BaseOptions(
        baseUrl: config.statusPageBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    ),
    pageId: config.statusPageId,
    apiKey: config.statusPageApiKey,
    component: config.statusPageComponent,
  );
});

/// The home screen's dismissible maintenance banner (native
/// `showMaintenanceBanner`); re-fetched whenever home refreshes.
final scheduledMaintenanceProvider = FutureProvider.autoDispose<Incident?>(
  (ref) => ref.watch(downtimeRepositoryProvider).scheduledMaintenance(),
);
