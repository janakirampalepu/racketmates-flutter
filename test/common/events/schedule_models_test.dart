import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';

import '../../support/fixtures.dart';

void main() {
  test('schedule list parses items, tolerates unknown keys and nulls', () {
    final response = ScheduleListResponse.fromJson(
      apiFixture('schedule_scheduled_events'),
    );
    final items = response.scheduleItems!;
    expect(items, hasLength(2));
    final first = items.first;
    expect(first.eventId, 101);
    expect(first.eventDate, '2026-11-03');
    expect(first.date, DateTime(2026, 11, 3));
    expect(first.eventType, 'et_game');
    expect(first.sportType, 'st_tennis');
    expect(first.additionalTimings, 1);
    // Sent as a JSON number by the backend (iOS's own model for this same
    // endpoint, and this app's own EventParticipant.waitlistNumber for the
    // related endpoint, both type it as a number) — confirms the field
    // tolerates a numeric value instead of throwing a cast error.
    expect(first.waitlistNumber, 3);
    // Same bug, confirmed live after fixing waitlistNumber alone: a second
    // field the backend also sends as a number was still typed String?.
    expect(first.userParticipantCount, 4);
    expect(first.eventUsers!.single.firstName, 'Sam');
    expect(items[1].additionalVenues, 2);
    expect(items[1].notes, isNull);
    expect(items[1].eventUsers, isNull);
    expect(response.meta!.otherEvents!.draftsLabel, 'Drafts (1)');
  });

  test('pending actions, stats and player cards', () {
    final pending = PendingActionsResponse.fromJson(
      apiFixture('current_session_pending_actions'),
    ).pendingActions!.single;
    expect(pending.eventId, 103);
    expect(pending.eventParticipantUser!.displayName, 'Sam Lee');
    expect(pending.primarySwipeAction, 'user_action_submit_scores');

    final stats = StatsSummaryResponse.fromJson(
      apiFixture('current_session_stats_summary'),
    ).homePageStats!.single;
    expect(
      (stats.wins, stats.losses, stats.totalEvents, stats.totalHours),
      (5, 3, 9, 18),
    );

    final card = PlayerCardsResponse.fromJson(
      apiFixture('current_session_player_cards'),
    ).playerCards!.single;
    expect(card.eventId, 98);
    expect(card.playerCardType!.cardType, playerCardEventResultUpdate);
    expect(card.playerCardType!.indicateSeen, isTrue);
  });

  test('event details subset', () {
    final event = EventDetailsResponse.fromJson(apiFixture('events_show'))
        .event!;
    expect(event.id, 101);
    expect(event.status, 'es_scheduled');
    expect(event.regularSpotsLeft, 1);
    final option = event.eventScheduleOptions!.single;
    expect(option.place!.name, 'Central Courts');
    expect(option.start, DateTime.utc(2026, 11, 3, 23));
    expect(event.players.map((p) => p.userId), [7, 8]); // coach excluded
    expect(event.currentUserEventDetails!.single.statusTitle, "You're going");
  });

  test('humanizeKey turns backend keys into readable fallbacks', () {
    expect(humanizeKey('et_game'), 'Game');
    expect(humanizeKey('es_to_be_scheduled'), 'To Be Scheduled');
    expect(humanizeKey(null), '');
    expect(humanizeKey(''), '');
  });
}
