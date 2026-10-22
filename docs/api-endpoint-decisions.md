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
| Session info | `GET current_session/session_info?app_type&version` -> `{user, subscription}` | Android + iOS (identical) | Loaded on session start, token refresh and resume. |
| Update time zone | `PUT current_session/update_time_zone {timezone_identifier}` | Android + iOS (identical) | Only when the server's zone is empty or differs from the device's. |
| Update settings | `PUT events/{id}/update_settings` `{event:{...}}` | Android (`updateManageGeneralSettingsRequest`) | Response ignored; the event is reloaded. |
| Reschedule event | `PUT events/{id}/reschedule_event` `{event:{event_schedule_options_attributes, event_venue_courts_attributes, notes_for_event}}` | Android (`rescheduleEvent`) | Single time option only. |
| Update match scores | `POST events/{id}/event_matches/{matchId}/update_scores` `{event_match:{event_scores_attributes, request_unfinished_match, deciding_set_type}}` | Android (`updateScores`) | |
| Clear unfinished match | `PUT events/{id}/event_matches/{matchId}/unmark_as_unfinished_match` | Android (`removeUnfinished`) | |
| Confirm / remove / add people | `PUT events/{id}/pick_players {user_ids}`, `PUT events/{id}/remove_participants {user_ids, remove_from}`, `POST events/{id}/add_participants {user_ids, participant_role}` | Android (`eventPickPlayers`, `eventRemoveParticipents`, `eventAddParticipents`) | The participants list comes from `GET events/{id}`, not `GET events/{id}/event_participants`. |
| Venue timezone | `GET timezone_infos/lookup?latitude&longitude&time=yyyy-MM-dd'T'HH:mmZ` | Android | `timezone_info_id` goes into the schedule option. |
| Create event | `POST events` `{event: {...}}` | Android (`CreateEventRequest`) | Practice drill only; see the request builder and the assumptions list in `CLAUDE.md` (unverified against a live backend). |
| Event reminders | `GET/POST users/{id}/user_reminder_preferences`, `DELETE users/{id}/user_reminder_preferences/{reminderId}`; body `{user_reminder_preference:{reminder_unit, reminder_unit_type: rut_minute\|rut_hour\|rut_day}}` | Android (`CreateRrmainderRequest`) | iOS not compared. Values: 5-55 min (step 5), 1-23 h, 1-28 d. |
| Text consent | `PUT current_session/update_text_consent?text_consent=<bool>` | Android | |
| Register device token | `POST current_session/register_device_token` — Android: form-encoded `device_token` (FCM), `platform=android`, `preferred_language`; iOS: JSON `{device_token (raw APNs hex), platform: ios, preferred_language}` | Android + iOS (they differ) | Sent only when the token or user changes. |
| Revoke device token | `POST current_session/revoke_device_token {device_token}` | Android + iOS | Before the session is revoked on log out; failure does not block log out. |
| Sendbird token | `GET current_session/sendbird_token` -> `{token, expires_at}` (a `data` wrapper is tolerated) | Android + iOS | Sendbird user id is the session user's `uid`. Refetched when Sendbird rejects the token. |
| Default chat rooms | `POST current_session/setup_default_chat_rooms` | Android | Called after each successful chat connection (creates the support room). |
| Link Play subscription | `POST current_session/link_playstore_subscription` JSON `{orderId, packageName, productId, purchaseTime, purchaseState, purchaseToken, autoRenewing, acknowledged}` | Android (`SubscriptionPurchaseRequest`) | Native sends it with a client that has no token interceptor; Flutter sends it authenticated. Confirm the backend accepts that. |
| Link App Store subscription | `POST current_session/link_appstore_subscription` raw body = StoreKit `Transaction.jsonRepresentation` (JSON) | iOS (`linkAppstoreSubscription(jsonData:)`) | Sent untouched with `Content-Type: application/json`. |
| Players chat room | `PUT events/{id}/setup_players_chat_room {team_id}` -> `{chat_room:{id, channel_url}}` | Android (`playersChatRoom`) | `team_id` may be null for non-team events. iOS not compared. |
| Captains chat room | `PUT events/{id}/setup_captains_chat_room` -> `{chat_room:{id, channel_url}}` | Android (`captainsChatRoom`) | |
| One-to-one chat room | `POST chat_rooms {chat_room:{chat_room_type:crt_direct, uids:[own, other]}}` -> `{chat_room:{id, channel_url}}` | Android (`createChatRoomWithUserIds`) | `uids` are the users' `uid` (Sendbird user ids). |
| Player search (1:1) | `GET users?search&exclude_user_ids[]=<me>&is_signed_up=true` | Android (`getListOfPlayers`) | |
| Venue search with a position | `GET places?place_types[]=&latitude=&longitude=&distance=&per_page=20&search=&exclude_logged_in_user_club_ids=false[&sport_type=]` | Android (`getLocationList`) | `latitude`/`longitude`/`distance` only when the device position is known; `distance` is in the user's unit (`distance_type`), default 30. |
| Team schedule | `GET schedule/scheduled_events?events_for=upcoming\|past&time_period=future\|past&team_id=&page&per_page=10&user_ids[]&event_roles[]&hour_format` | Android (`getScheduledEventsListV2`) | Same as the main schedule plus `team_id`. |
| Team member rankings | `GET teams/{id}/team_players/member_rankings?page&per_page=100&sport_type&search&ranking_period&match_type` -> `team_players[]` with `current_rank, previous_rank, wins, losses, total_points` | Android (`getTeamsMemberRankingListWithFilter`) | `ranking_period` is a `ranking_period_duration` key, `match_type` `mt_singles`/`mt_doubles` or omitted. |
| Update member roles | `PUT teams/{id}/team_players/{pid}` `{team_player:{is_captain,is_coach,is_player}}` | Android (`updateTeamMemberRoles`) | |
| Deactivate / reactivate member | `POST teams/{id}/team_players/{pid}/inactivate` / `.../reactivate` | Android | |
| Remove member | `DELETE teams/{id}/team_players/{pid}` | Android (`deleteTeamMember`) | |
| Add members to a team | `PUT teams/{id}` `{team:{team_players_attributes:[{user_id,is_captain,is_player,is_coach}]}}` | Android (`inviteMembersToTeam`) | |
| Players outside a team | `GET users?search&exclude_team_id&is_signed_up=true&sport_types[]` | Android (`getListOfPlayersForTeam`) | |
| Update team | `PUT teams/{id}` `{team:{id, name, team_type, enable_player_ranking, team_sports_attributes:[{id?, sport_type, _destroy?}]}}` | Android (`updateTeam`, `TeamViewModel.teamRequest`) | Same path as adding members (different body). Sports: ticked ones keep their id, new ones have no id, removed ones carry `_destroy: true`. |
| Archive / unarchive team | `POST teams/{id}/archive`, `POST teams/{id}/unarchive` | Android | |
| Delete team | `DELETE teams/{id}` | Android (`deleteTeam`) | |
