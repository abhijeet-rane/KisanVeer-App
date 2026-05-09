plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kisanveer.app"
    compileSdk = 36  // Required by flutter_secure_storage
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }

    defaultConfig {
        applicationId = "com.kisanveer.app"
        minSdk = 24  // Required by flutter_secure_storage (was 23)
        targetSdk = 35
        versionCode = flutter.versionCode ?: 1
        versionName = flutter.versionName ?: "1.0.0"
        
        // Enable multidex for better compatibility
        multiDexEnabled = true
    }

    // Per-ABI APKs are produced by `flutter build apk --release --split-per-abi`.
    // Do not duplicate ABI splits here: combining Gradle `splits { abi { ... } }`
    // (especially `isUniversalApk = true`) with Flutter's split flow creates a
    // universal output whose ABI filter is null; AGP 8.7+ then throws
    // "output.getFilter(...ABI) must not be null" during packaging.

    buildTypes {
        getByName("release") {
            // Enable code obfuscation to prevent reverse engineering
            isMinifyEnabled = true
            isShrinkResources = true
            
            // TODO: Replace with release signing config before production
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug")
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
