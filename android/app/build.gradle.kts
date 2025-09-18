plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.insurevis"
    compileSdk = 35  // Android 14 support
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring required by some libraries (e.g. flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.insurevis"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Minimum Android 5.0
        targetSdk = 35  // Target Android 14
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add camera buffer configuration to prevent ImageReader buffer overflow
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Fix for missing CallbackToFutureAdapter
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    // Required for core library desugaring (backport newer java APIs to older Android)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
