import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_actions.dart';

import '../../support/fixtures.dart';

EventDetails _event(String fixture) =>
    EventDetailsResponse.fromJson(apiFixture(fixture)).event!;

List<(RsvpAction, RsvpBlock?)> _plan(String fixture) => [
  for (final o in rsvpOptionsFor(_event(fixture))) (o.action, o.block),
];

void main() {
  test('invited: accept (primary) and decline (secondary), both direct', () {
    expect(_plan('events_show_invited'), [
      (RsvpAction.accept, null),
      (RsvpAction.decline, null),
    ]);
  });

  test('accepted: edit response needs the picker, leave is direct', () {
    expect(_plan('events_show_accepted'), [
      (RsvpAction.editResponse, RsvpBlock.needsOptionPicker),
      (RsvpAction.leave, null),
    ]);
  });

  test('declined: rejoin with a single option is direct', () {
    expect(_plan('events_show_declined'), [(RsvpAction.rejoin, null)]);
  });

  test('several assigned options need the picker for accept', () {
    expect(_plan('events_show_multi_option'), [
      (RsvpAction.accept, RsvpBlock.needsOptionPicker),
      (RsvpAction.decline, null),
    ]);
  });

  test('full event offers the waitlist', () {
    expect(_plan('events_show_full'), [
      (RsvpAction.joinWaitlist, null),
      (RsvpAction.decline, null),
    ]);
  });

  test('subscription-gated action is surfaced with the server message', () {
    final accept = rsvpOptionsFor(_event('events_show_subscription')).first;
    expect(accept.block, RsvpBlock.requiresSubscription);
    expect(accept.message, 'Upgrade to respond');
  });

  test('disabled / unknown actions are hidden; no current user means none', () {
    final base = _event('events_show_invited');
    final hidden = EventDetails(
      id: base.id,
      currentUserEventDetails: const [
        CurrentUserEventDetail(
          eventParticipantId: 1,
          primaryAction: EventAction(
            action: 'event_view_action_accept',
            access: 'up_disabled',
          ),
          secondaryAction: EventAction(
            action: 'event_view_action_directions',
            access: 'up_enabled',
          ),
        ),
      ],
    );
    expect(rsvpOptionsFor(hidden), isEmpty);
    expect(rsvpOptionsFor(const EventDetails(id: 1)), isEmpty);
  });

  test(
    'round-robin with mixed games or fixed partners needs partner input',
    () {
      const event = EventDetails(
        eventType: 'et_round_robin',
        gameType: 'egt_both',
        currentUserEventDetails: [
          CurrentUserEventDetail(
            eventParticipantId: 1,
            isPlayer: true,
            groupedEventScheduleOptions: [GroupedScheduleOption(id: 1)],
            primaryAction: EventAction(
              action: 'event_view_action_accept',
              access: 'up_enabled',
            ),
          ),
        ],
      );
      expect(rsvpOptionsFor(event).single.block, RsvpBlock.needsOptionPicker);
    },
  );

  test('cancelled or to-be-scheduled options are not counted', () {
    const mine = CurrentUserEventDetail(
      groupedEventScheduleOptions: [
        GroupedScheduleOption(id: 1),
        GroupedScheduleOption(id: 2, cancelled: true, toBeScheduled: true),
      ],
    );
    expect(mine.assignedOptions.map((o) => o.id), [1]);
  });
}
