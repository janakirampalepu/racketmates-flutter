fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### quality

```sh
[bundle exec] fastlane quality
```

Format check, static analysis and tests with coverage

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build a release App Bundle for env:<name> (set build_number:<n> to skip the Play lookup)

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Build and upload env:<name> to the Play internal track

### android qa_automation

```sh
[bundle exec] fastlane android qa_automation
```

Installable build for Appium / QA automation (APK)

----


## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Signed IPA for env:<name> (match: appstore for production, adhoc otherwise)

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Build and upload env:<name> to TestFlight

### ios qa_simulator

```sh
[bundle exec] fastlane ios qa_simulator
```

Unsigned simulator .app zipped for Appium / QA automation

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
