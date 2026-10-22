# API endpoint decisions

The backend serves two generations of some read endpoints: the Android app and the iOS app call different paths for similar data (see `CLAUDE.md` §1.12). This file records which one the Flutter app uses per feature and why. Confirm each row with the backend owners before release; do not mix generations within one screen.

| Feature | Flutter uses | Native Android | Native iOS | Why |
|---|---|---|---|---|
| Home / schedule lists (upcoming, past) | `GET schedule/scheduled_events` (`events_for`, `time_period`, `per_page`, `page`, `user_ids[]`, `event_roles[]`, `hour_format`) | same | `GET events/schedule_list`, `GET events/schedule` | Android's request/response models are fully readable and used by home and schedule; iOS's models are not yet inspected. Switch to iOS paths only on backend guidance. |
| Pending actions | `GET current_session/pending_actions` | same | `events/schedule_list` (no dedicated endpoint) | Dedicated endpoint with a typed response. |
| Activity summary | `GET current_session/stats_summary` | same | same | Identical on both platforms. |
| Latest updates (player cards) | `GET current_session/player_cards` (`card_types[]=pct_player_event_result_update`) | same | same | Identical on both platforms. |
| Event details | `GET events/{id}?hour_format&view_type=participant` | same | `GET events/{id}` | Identical path. |

Pagination follows the native schedule screens: `per_page=10`, `page` starts at 1, and the list is finished when a page returns no items (`schedule_items` empty). Home shows `per_page=3` of upcoming/past.
