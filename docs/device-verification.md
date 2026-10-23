# Build pipeline and device verification

What was run, and what still needs a person with a device, an account or a console. Update the status column as items are done.

## Verified (2026-10-23, on a Mac, no secrets)

| Check | Result |
| --- | --- |
| `flutter build apk --debug --flavor qa` | OK |
| `flutter build apk --release --flavor qa` | OK after two fixes: `fluttertoast` (pulled in by `sendbird_uikit`) is compiled against API 33, which androidx rejects, so `android/build.gradle.kts` raises it to 36; the app now declares the `SendbirdIcons` font (`pubspec.yaml`), without which Sendbird UIKit icons are blank in release builds |
| `flutter build appbundle --release --flavor qa` | OK (73 MB) |
| `flutter build ios --simulator --debug --flavor qa` | OK |
| `bundle exec fastlane quality` | OK (format, SSL pin check, analyze, 840+ tests with coverage) |
| `bundle exec fastlane android qa_automation env:qa` | OK (APK) |
| `bundle exec fastlane ios qa_simulator env:qa` | OK after a fix (zip paths); writes `build/Racketmates-qa-simulator.zip` |
| iPhone 16 Pro simulator, build with dummy config | Reaches the welcome screen (Sign in / Sign up). A first launch once sat on the splash spinner for minutes and could not be reproduced |
| Simulator, build without config | Used to be a blank white screen; now shows "This build is not configured" and names the missing values |
| `qlty check --all` | No issues (secrets scan, dependency vulnerabilities, shell). ktlint, rubocop and radarlint are not enabled |

## Pipeline, not yet run anywhere but locally

- `.github/workflows/ci.yml`: quality job (format, pins, analyze, tests, coverage artifact, QLTY check, coverage publish on `main` when `QLTY_COVERAGE_TOKEN` is set), Android qa release APK, iOS qa simulator build. Needs a first run on GitHub to confirm the runner images, the QLTY installer and the Flutter cache work.
- SonarCloud for the Flutter repo is **not** set up: confirm that SonarCloud supports Dart/Flutter on your plan and which project key to use, then add a scan step reading `coverage/lcov.info`.
- Not run (need secrets): `android deploy` (Play service-account JSON in `GOOGLE_PLAY_JSON_KEY_PATH`), `ios build` / `ios deploy` (`match` repo access plus App Store Connect API key: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_PATH`), signing, Firebase/BrowserStack upload.
- Per-environment config (`env/<env>.json`: API base URL, API version, OAuth client, Sendbird app id) must come from the CI secret store; only `env/dev.example.json` is in git.

## Needs a device or an account

Run on a real Android phone (API 33+) and a real iPhone, build `qa` with the real `env/qa.json`.

| # | Area | What to check |
| --- | --- | --- |
| 1 | Launch | Splash to welcome in a few seconds on first and later launches; sign up, sign in, sign out |
| 2 | TLS pinning | Requests succeed against the QA/production hosts (`tool/verify_ssl_pins.sh --live api-qa.racketmatesapp.com`), and fail against a proxy |
| 3 | Push (FCM / APNs) | Needs `google-services.json` and `aps-environment` per environment. Token registers and revokes on login and logout; a notification opens the right screen; the Android 13+ permission prompt appears once |
| 4 | Chat (Sendbird) | Needs the Sendbird app id. Channel list, open a channel, send text and image, token refresh after expiry, push for a new message on both platforms, icons visible in a release build |
| 5 | Subscriptions | Needs a Play licence tester and an Apple sandbox account. Product query, purchase, pending, cancel, restore, renewal, redeem code, and the backend accepting the link call |
| 6 | Location | When-in-use permission asked once, fix obtained, denied state handled, venue distance sorting, map links open Google/Apple Maps |
| 7 | Camera and photos | Profile photo from camera and library; permission denied path |
| 8 | Accessibility | TalkBack and VoiceOver read each screen; large text; dark mode |
| 9 | Appium | The existing suites find the test ids (`resource-id` on Android, `accessibilityIdentifier` on iOS) on the QA build |
| 10 | Release build size and startup | Compare with the native apps |

## Local setup gaps

- No Android emulator is installed on this machine (`emulator -list-avds` is empty); Android was verified by building only. Create an AVD (API 34+, Google APIs) to run it.
