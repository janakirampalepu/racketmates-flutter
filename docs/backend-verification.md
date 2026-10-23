# Backend verification checklist

Everything the Flutter app assumes about the backend that was read from the native code but never run against a server. For the backend owners (or whoever has a QA account): answer each row, then record the outcome in `docs/api-endpoint-decisions.md` and fix the code where the answer differs. Endpoint choices (Android vs iOS set) are in `docs/api-endpoint-decisions.md`.

Answer format per row: **OK**, **Different** (say how) or **Unknown**.

## A. Auth and sign-up
1. `oauth/token` password grant: `username` is national digits only (Android sends the field text; iOS a username value).
2. `verification_code` for sign-up/login comes from the `verify_sms_code` response.
3. `send_sms_code` accepts `UserAgent: iOS` on iOS (Android sends `Android`).
4. Removing the last kid (`DELETE users/{kidId}`) removes the parent role server-side.
5. `PUT users/{id}/change_mobile_number` needs only digits plus country/region codes (no verification code in the call).

## B. Home and schedule
6. Home/schedule accept `event_roles[]=managing&event_roles[]=participant` and the device `hour_format` (12/24).
7. `schedule_items` rows carry `event_date` as `yyyy-MM-dd` and server-formatted `time_slot` and status labels.
8. Event details: the first `event_schedule_options` entry is the one to show; `current_user_event_details[0]` is the signed-in user's standing; players are participants with `is_player`.
9. RSVP bodies: `event_schedule_option_ids` for accept/decline/rejoin, `{}` for waitlist, none for leave. iOS equivalents of the RSVP paths were never compared.

## C. Create event (all types)
10. Non-team events send `originator_type: ""`.
11. `start_time` is the venue's wall-clock time as `yyyy-MM-dd'T'HH:mm'Z'` with `timezone_info_id` from `timezone_infos/lookup`.
12. `player_pool = pp_invited_only` and `player_acceptance_type = pat_order_of_response` are right defaults for a single time option.
13. `event_screen = es_review` and the `screen_flow_path` strings (per type) are accepted.
14. Court selection is optional; at least one invitee is required (are these server rules, or only native UI rules?).
15. Lessons: `with_coach: true`, coaches as `is_coach` participants, at least one coach. Meetups: no `sport_type`, no courts, attendees as `is_audience`, `with_audience: false`.
16. Games and round robins: `place_court_id` per match, empty `event_venue_courts_attributes`, match sides (`ecs_top`/`ecs_bottom`, `epp_center`/`epp_left`/`epp_right`), `assign_type` values (`at_court_addition`, `at_assign_later`) with `pat_pick_manually`, round-robin fields (`no_of_courts`, courts with `order`, `game_type`, `partnership_type`, `event_sub_type`).
17. Minimum score defaults per scoring format from `minimum_scores` (native keeps the previous value; is that a bug?). Every match spot must be filled to assign now.
18. Team events: `originator_type: "Team"`, `originator_id`, one `event_teams_attributes` entry (`ett_home`, `logged_in_user_belongs_to_team: true`), `opponent_team_type` values, and team ids on match sides.

## D. Drafts
19. `POST events` with `request_save_as_draft: true` accepts a body with only `event_type` (all else absent).
20. `request_draft_event_id` replaces the old draft on save and on final create (no duplicate left behind).
21. `GET events/{id}?view_type=full` returns a draft in (nearly) the create request shape, wrapped in `event` or flat, with `event_screen`.
22. `GET schedule/drafts?status=es_draft` query parameters: is the empty `sport_types[]` that native sends needed? Row fields: `event_id, event_type, sport_type, courts_label, last_updated_at`.
23. `DELETE events/{id}` deletes a draft.

## E. Teams, profile, settings
24. Team create/update/archive/delete bodies and permission keys (`team.settings`, `team.archive`, `team.unarchive`, `team.destroy`, `team.team_players.*`, `team.events.create`); a missing permission means "not allowed".
25. `member_rankings` params (`ranking_period` keys, `match_type`) and the one-page-of-100 assumption.
26. Role/sport/kid endpoints (`users/{id}/user_roles`, multipart kid add/edit) accept the bodies listed in the decisions doc.
27. Account deletion is `POST current_session/user_feedbacks` with subject "Delete My Account".

## F. Subscriptions
28. `link_playstore_subscription` / `link_appstore_subscription`: does the backend accept the iOS raw JSON and the Android body from an authenticated client? Native Android posts without the bearer token: is the bearer needed or harmful?
29. Entitlement fields (`hasFullFeatureAccess`, trial days) and how restore, grace period, hold and cancellation appear.

## G. Needs devices or third-party consoles (not backend)
30. Sendbird: app id/token per environment, push (APNs certificates in the Sendbird dashboard), data-only Android notification.
31. Play licence tester and Apple sandbox account for purchase, pending, cancel, restore, renewal, redeem.
32. FCM/APNs delivery, Android 13 notification permission, `aps-environment` per environment.
33. Location permission flows and map links on real devices.

## H. Product questions (not technical)
34. Is `+318` (above native 317) the right release version?
35. In-app theme toggle and RTL: needed?
36. Appium repo location and locator inventory.
