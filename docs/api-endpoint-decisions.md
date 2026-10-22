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
| User search (players, coaches, meetup attendees) | `GET users?search[&roles[]=ur_player\|ur_coach][&sport_types[]=<sport>]` | Android (`getListOfEventPlayers`) | `roles[]` and sport are optional (meetups send neither). `include_user_ids[]`/`exclude_user_ids[]` not sent. |
| Scoring formats | `GET reference_data/scoring_formats?sport_type=&event_type=` -> `scoring_format_keys[]`, `minimum_scores{}` | Android (`getSportScoringFormats`) | Labels come from `reference_data` (`scoring_format`, `deciding_set_type`). |
| Teams list | `GET teams?query_type=user_teams&page=1&per_page=100&user_ids[]=&captain_teams=false` | Android (`getUserAllTeams`) | One page only (native `VALUE_HUNDRED`). Active teams (no `archived` flag). |
| Captained teams (event creation) | `GET teams?archived=false&query_type=user_teams&captain_teams=true&sport_types[]=&search_query=&user_ids[]=` | Android (`getTeamsListWithUserIds`) | Sport filter omitted for sport-less events. |
| Opponent teams (event creation) | `GET teams?archived=false&query_type=non_league_teams&captain_teams=false&exclude_team_id=<own team>&sport_types[]=&search_query=` | Android (`getTeamsListWithUserIds`, opponent mode) | No `user_ids[]`; one page of 100. |
| Team details | `GET teams/{id}` -> `{team, is_captain, ...}` | Android (`getTeamDetails`) | |
| Team members | `GET teams/{id}/team_players?roles[]=&sport_types[]=&search=&include_inactive_members=false&page=1&per_page=100` | Android (`getTeamsMemberListWithFilter`) | Used for the roster page and team-event player search. |
| Create team | `POST teams` `{team:{name, team_type, enable_player_ranking, team_sports_attributes[], team_players_attributes[]}}` | Android (`createTeam`) | iOS `Teams` endpoints not compared yet. |
| Venue timezone | `GET timezone_infos/lookup?latitude&longitude&time=yyyy-MM-dd'T'HH:mmZ` | Android | `timezone_info_id` goes into the schedule option. |
| Create event | `POST events` `{event: {...}}` | Android (`CreateEventRequest`) | Practice drill only; see the request builder and the assumptions list in `CLAUDE.md` (unverified against a live backend). |
