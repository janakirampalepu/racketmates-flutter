# Racketmates (Flutter)

Flutter migration of the native Racketmates Android and iOS apps. Read `CLAUDE.md` first: it holds the verified findings from both native apps, the architecture rules and the checklists.

## Prerequisites
- Flutter **3.47.7** (stable), pinned in `.fvmrc`. Use FVM or point `FLUTTER_BIN` / `PATH` at that SDK.
- Ruby + Bundler for Fastlane (`bundle install`).
- Android SDK (JDK 17) and Xcode for platform builds.

## Run
Environment values are not committed. Copy `env/dev.example.json` to `env/<env>.json`, fill it in from your secret store, then:
```bash
flutter run --flavor qa -t lib/main_qa.dart --dart-define-from-file=env/qa.json
```
Flavors: `production`, `hotfix`, `qa`, `regression`, `staging`, `dev`, `local`. On iOS each flavor is a scheme of the same name (configurations `Debug|Release|Profile-<env>`).

## Checks
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

## Builds (Fastlane)
```bash
bundle exec fastlane lanes
bundle exec fastlane android build env:qa
```
See `fastlane/.env.example` for the variable names the lanes read.
