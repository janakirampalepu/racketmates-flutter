# API endpoint decisions

The backend serves two generations of some read endpoints: the Android app and the iOS app call different paths for similar data (see `CLAUDE.md` §1.12). This file records which one the Flutter app uses per feature and why. Confirm each row with the backend owners before release; do not mix generations within one screen.

| Feature | Flutter uses | Native Android | Native iOS | Why |
|---|---|---|---|---|
| Home / schedule lists (upcoming, past) | `GET schedule/scheduled_events` (`events_for`, `time_period`, `per_page`, `page`, `user_ids[]`, `event_roles[]`, `hour_format`) | same | `GET events/schedule_list`, `GET events/schedule` | Android's request/response models are fully readable and used by home and schedule; iOS's models are not yet inspected. Switch to iOS paths only on backend guidance. |
| Pending actions | `GET current_session/pending_actions` | same | `events/schedule_list` (no dedicated endpoint) | Dedicated endpoint with a typed response. |
| Activity summary | `GET current_session/stats_summary` | same | same | Identical on both platforms. |
| Latest updates (player cards) | `GET current_session/player_cards` (`card_types[]=pct_player_event_result_update`) | same | same | Identical on both platforms. |
| RSVP (accept, decline, rejoin, leave, waitlist) | `POST events/{id}/event_participants/{participantId}/{accept_invite,decline_invite,rejoin_event,leave_event,join_waitlist}` | same | `accept_invite` etc. not compared yet | Only the Android paths were read; iOS equivalents are unverified. Bodies: `event_schedule_option_ids` (accept/decline/rejoin), `{}` (waitlist), none (leave). |
| Cancel event | `PUT events/{id}/cancel_event` `{cancellation_reason?, remove_event}` | same | iOS has `events/{id}/cancel` and `undo_cancel` | Android path used; iOS `cancel`/`undo_cancel` not compared. Confirm with backend owners. |
| Event details | `GET events/{id}?hour_format&view_type=participant` | same | `GET events/{id}` | Identical path. |

Pagination follows the native schedule screens: `per_page=10`, `page` starts at 1, and the list is finished when a page returns no items (`schedule_items` empty). Home shows `per_page=3` of upcoming/past.

## Content, venues and event creation (milestone 5b)

| Feature | Flutter uses | Source | Notes |
|---|---|---|---|
| Server-driven strings | `GET resources/messages`, `GET resources/pre_login_messages` (`client_id`, `client_secret` in the query) | Android + iOS | Read by dot path with a local fallback (`MessageKeys`); cached; refetched when `resource_strings_latest_version` (metadata) or the device language changes. |
| Reference data | `GET reference_data` (`client_id`, `client_secret`) | Android + iOS | Flat `{id, data_type, key, localized_label, localized_sub_text}`; refetched on `reference_data_last_updated`. |
| Venue search | `GET places` (`place_types[]` all five, `per_page=20`, `search`, `exclude_logged_in_user_club_ids=false`, `sport_type`) | Android | No latitude/longitude/distance yet (needs location permission, locations milestone). |
| Favourite venues | `GET current_session/my_favourite_places`, `PUT places/{id}/mark_as_favourite`, `PUT places/{id}/remove_from_favourites`, `GET places/{id}` | Android | iOS equivalents (`my_clubs`, `add_to_my_clubs`, ...) are a different concept ('clubs') and were not compared. |
| Player search | `GET users?search&roles[]=ur_player&sport_types[]=<sport>` | Android (`getListOfEventPlayers`) | `include_user_ids[]`/`exclude_user_ids[]` not sent. |
| Venue timezone | `GET timezone_infos/lookup?latitude&longitude&time=yyyy-MM-dd'T'HH:mmZ` | Android | `timezone_info_id` goes into the schedule option. |
| Create event | `POST events` `{event: {...}}` | Android (`CreateEventRequest`) | Practice drill only; see the request builder and the assumptions list in `CLAUDE.md` (unverified against a live backend). |
