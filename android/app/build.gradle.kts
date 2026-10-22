import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (git-ignored) or CI-provided
// environment variables. Never commit keystores or passwords.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signingValue(propName: String, envName: String): String? =
    keyProps.getProperty(propName) ?: System.getenv(envName)

android {
    namespace = "io.appsmaker.racketmates"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Same base application ID as the production native app (upgrade compatibility).
        applicationId = "io.appsmaker.racketmates"
        // Matches the native Android app (minSdk 33). Lowering it needs product approval.
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildFeatures {
        resValues = true
    }

    // One flavor per existing native environment (build types in the native app).
    // Application IDs and suffixes mirror app/build.gradle of racketmates-android.
    flavorDimensions += "env"
    productFlavors {
        create("production") {
            dimension = "env"
            resValue("string", "app_name", "Racketmates")
        }
        create("hotfix") {
            dimension = "env"
            applicationIdSuffix = ".hotfix"
            resValue("string", "app_name", "RM (Hotfix)")
        }
        create("qa") {
            dimension = "env"
            applicationIdSuffix = ".qa"
            resValue("string", "app_name", "RM (QA)")
        }
        create("regression") {
            dimension = "env"
            applicationIdSuffix = ".regression"
            resValue("string", "app_name", "RM (Regression)")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "RM (Staging)")
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "RM (Dev)")
        }
        create("local") {
            dimension = "env"
            applicationIdSuffix = ".local"
            resValue("string", "app_name", "RM (Local)")
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing only when no release keystore is provided
            // (local experiments). CI release lanes must supply the real keystore.
            val rel = signingConfigs.getByName("release")
            signingConfig = if (rel.storeFile != null) rel else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Reads the session the native app left in EncryptedSharedPreferences
    // (same version as the native app).
    implementation("androidx.security:security-crypto:1.1.0")

    // Push notifications. Firebase only starts when google-services.json is
    // present (CI / developer machines; never committed), see the end of this file.
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    implementation("com.google.firebase:firebase-messaging")

    // Google Play Billing for the subscription (same version as the native app).
    implementation("com.android.billingclient:billing:9.1.0")
}

// Applies the Google services plugin (which turns google-services.json into the
// Firebase configuration) only when a configuration file exists, so builds
// without one still work and simply have no push.
val hasFirebaseConfig =
    file("google-services.json").exists() ||
        fileTree("src") { include("*/google-services.json") }.files.isNotEmpty()
if (hasFirebaseConfig) {
    apply(plugin = "com.google.gms.google-services")
}
