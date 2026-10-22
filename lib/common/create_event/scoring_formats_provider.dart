import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_api.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';

/// Scoring formats for (sport key, event type key).
final scoringFormatsProvider = FutureProvider.autoDispose
    .family<ScoringFormatsResponse, ({String sport, String eventType})>(
      (ref, args) => ref
          .watch(createEventRepositoryProvider)
          .scoringFormats(sportKey: args.sport, eventType: args.eventType),
    );
