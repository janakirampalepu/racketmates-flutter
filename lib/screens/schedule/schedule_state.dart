import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';

class ScheduleListState {
  const ScheduleListState({
    this.items = const [],
    this.nextPage = 1,
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.failure,
  });

  final List<ScheduleItem> items;

  /// Next page to request (native page numbers start at 1).
  final int nextPage;

  /// First page in flight.
  final bool loading;
  final bool loadingMore;

  /// Native rule: more pages exist until a page comes back empty.
  final bool hasMore;
  final AppFailure? failure;

  bool get isEmpty => !loading && failure == null && items.isEmpty;

  ScheduleListState copyWith({
    List<ScheduleItem>? items,
    int? nextPage,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    AppFailure? Function()? failure,
  }) => ScheduleListState(
    items: items ?? this.items,
    nextPage: nextPage ?? this.nextPage,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    failure: failure != null ? failure() : this.failure,
  );
}
