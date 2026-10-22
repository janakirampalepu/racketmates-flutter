# video_thumbnail 0.5.6 (patched)

Copy of `video_thumbnail` 0.5.6 (MIT, John Zhong; see LICENSE) used through a
`dependency_overrides` entry. Only `android/build.gradle` differs: the original
pins the Android Gradle plugin 4.1.0 in a `buildscript` block, uses `jcenter()`
and `lintOptions`, none of which build with Android Gradle plugin 9. The Dart
and native sources are unchanged. Drop this copy when a release of the package
builds with AGP 9 (it is only a transitive dependency of `sendbird_uikit`).
