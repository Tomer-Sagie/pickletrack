plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.appdistribution")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.pickletrack"
    compileSdk = flutter.compileSdkVersion
    // Pin NDK to a version that's backward-compatible with the 26.x
    // default but matches what audioplayers_android / path_provider_android
    // / share_plus were compiled against. The bundler warns
    // "Fix by using the highest Android NDK version"; we oblige.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pickletrack"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Replace with your own release signing config before
            // uploading to the Play Store. See:
            // https://docs.flutter.dev/deployment/android#configure-signing-in-gradle
            signingConfig = signingConfigs.getByName("debug")

            // Shrink and optimize the release build
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            firebaseAppDistribution {
                artifactType = "APK"
                releaseNotesFile = "release-notes.txt"
                // Uncomment and set groups or testers once configured:
                // groups = "qa-team"
                // testers = "user@example.com"
            }
        }
    }
}

flutter {
    source = "../.."
}
