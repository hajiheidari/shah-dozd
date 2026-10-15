import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (never committed), see docs/RELEASE.md.
//   storeFile=/path/to/upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.espadna.shah_dozd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.espadna.shahdozd"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    // One game, three distribution channels. They differ only in the store
    // integration chosen at build time (--dart-define=CHANNEL=...), see
    // lib/premium/entitlements.dart and docs/RELEASE.md.
    flavorDimensions += "store"
    productFlavors {
        create("play") { dimension = "store" }
        create("bazaar") { dimension = "store" }
        create("direct") { dimension = "store" }
    }
    // Adivery (Iranian ad network) only in the Iranian builds: AdsBridge.kt
    // is in src/bazaar and src/direct; src/play has an empty stand-in.

    buildTypes {
        release {
            // Without android/key.properties the release build is signed with
            // the debug key: fine for testing, never for a store upload.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    "bazaarImplementation"("com.adivery:sdk:4.8.3")
    "directImplementation"("com.adivery:sdk:4.8.3")
}
