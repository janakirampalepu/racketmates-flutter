import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/create_event/drafts_api.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:racketmates/common/errors/app_failure.dart';

/// Native `AppConstants.EVENT_DRAFT`.
const draftStatus = 'es_draft';

/// Native `EVENT_VIEW_TYPE_FULL`.
const fullView = 'full';

abstract class DraftsRepository {
  Future<List<DraftSummary>> list({required List<String> userIds});

  /// The saved request of a draft (`{event: {...}}`).
  Future<Map<String, dynamic>> request(int id, {required int hourFormat});

  /// `DELETE events/{id}`.
  Future<void> delete(int id);
}

class DraftsRepositoryImpl implements DraftsRepository {
  const DraftsRepositoryImpl(this.api);

  final DraftsApi api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<List<DraftSummary>> list({required List<String> userIds}) async {
    final response = await _guard(
      () => api.drafts(
        userIds: userIds,
        status: draftStatus,
        sportTypes: const [],
      ),
    );
    return response.scheduleItems?.whereType<DraftSummary>().toList() ??
        const [];
  }

  @override
  Future<Map<String, dynamic>> request(
    int id, {
    required int hourFormat,
  }) async {
    final body = await _guard(
      () => api.draft(id, hourFormat: hourFormat, viewType: fullView),
    );
    if (body is! Map<String, dynamic>) throw const ParseFailure();
    return body;
  }

  @override
  Future<void> delete(int id) => _guard(() => api.delete(id));
}

final draftsRepositoryProvider = Provider<DraftsRepository>(
  (ref) => DraftsRepositoryImpl(DraftsApi(ref.watch(apiDioProvider))),
);
