# Pending items (as of 2026-10-23)

Everything built so far is committed and pushed to `main`. Nothing is half done. See `CLAUDE.md` (milestone table) and `docs/api-endpoint-decisions.md` for what exists and which payloads are unverified.

## 1. Needs other people or accounts

- **Backend answers**: send `docs/backend-verification.md` to the backend owners (items 1-29) and the QA/mobile lead (30-36). Items added since that doc was written, still to put on it:
  - Tie-breaks: a tie-break no longer entered is cleared by sending it blank with its `id`; the match tie-break is stored under `set: "6"` with `match_tie_breaker: true`.
  - `POST accept_scores` response.
  - `generate_event_rounds`: the 422 body (`result: egr_insufficient_confirmed_players`); `event_partner_pairs` takes user ids or participant ids, and replaces the server's pairs or not.
  - `assign_players`: emptying a side removes its players.
  - `reschedule_matches` without `timezone_info_id`.
  - RSVP preferences: `event_partner_id` is the participant id; the first status filter is right for the partner list; waitlist and rejoin carry `preferred_match_type`, `notes`, `event_partner_id`.
- **Real devices and consoles** (`docs/device-verification.md`): push (FCM/APNs), Sendbird, Play/App Store purchases, location, camera, TalkBack/VoiceOver, Appium locators. No Android emulator is installed on the dev machine.
- **CI and tooling**: `.github/workflows/ci.yml` has never run on GitHub; SonarCloud for Dart not set up (confirm plan support and project key); deploy lanes need secrets (Play service account, `match`, App Store Connect key); per-environment `env/<env>.json` from the CI secret store.
- **Product questions**: release version (`+318`), in-app theme toggle and RTL, Appium repo location.

## 2. Features still to build

- **RSVP**: the picker for events with several time options (round robins with several options are still blocked), editing a response.
- **Manage event**: several time options per match or defining a time later; rescheduling all matches at once; removing a server pair; changing a round match's type; adding matches or courts to a game; confirming a time option; defaulted/retired outcomes; team winner (`mark_winner`); editing the opponent or home team; undo cancel; the leaderboard; chat room setup.
- **Teams**: home pending actions and activity summary; entering and resetting ranking points; player settings; inviting by phone or email; creating a team from the event wizard.
- **Schedule**: filters (owner/sport), calendar view, the to-be-rescheduled list, the family/kid picker, alternate time options.
- **Account and app**: kid photo, signed-out contact us, deep and universal links, language selection, embedded map and venue creation, removing the player/coach role entirely.

## 3. Suggested order

1. Add the new items above to `docs/backend-verification.md` and send it out.
2. RSVP picker for several time options (most common missing player action).
3. Team pending actions and activity summary.
4. First GitHub CI run; fix whatever it shows.
