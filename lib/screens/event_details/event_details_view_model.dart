import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/schedule_repository.dart';

/// Read-only event details (`GET events/{id}`), keyed by event id.
final eventDetailsProvider = FutureProvider.autoDispose
    .family<EventDetails, int>(
      (ref, id) => ref
          .watch(scheduleRepositoryProvider)
          .eventDetails(id, hourFormat: ref.watch(hourFormatProvider)),
    );
