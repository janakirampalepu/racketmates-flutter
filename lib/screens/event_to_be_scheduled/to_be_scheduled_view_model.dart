import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_filter.dart';
import 'package:racketmates/common/events/schedule_repository.dart';

/// Events that still need a time picked (native `btnToBeScheduledEvent`'s
/// destination screen). Not paginated, same as Android; reuses the global
/// Schedule filter (native has no separate filter state for this screen).
final toBeScheduledProvider = FutureProvider.autoDispose<List<ScheduleItem>>((
  ref,
) {
  final filter = ref.watch(scheduleFilterProvider(false));
  return ref
      .watch(scheduleRepositoryProvider)
      .toBeScheduled(
        userIds: ref.watch(selectedUserIdsProvider),
        eventRoles: filter.eventRoles,
        sportTypes: filter.sportTypesOrNull,
      );
});
