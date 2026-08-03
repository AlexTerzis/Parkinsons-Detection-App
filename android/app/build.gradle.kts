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
    namespace = "com.example.hand_landmarker_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.parkinson.detector"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // ✅ Correct Kotlin DSL syntax
            isMinifyEnabled = false
            isShrinkResources = false

            // Use debug signing for now (you can later replace this with a real keystore)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // AndroidX & Material
    implementation("androidx.core:core-ktx:1.8.0")
    implementation("androidx.fragment:fragment-ktx:1.5.4")
    implementation("com.google.android.material:material:1.7.0")

    // CameraX Core and Camera2 implementation
    val cameraxVersion = "1.3.1"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("androidx.camera:camera-view:$cameraxVersion")

    // MediaPipe Tasks Vision
    implementation("com.google.mediapipe:tasks-vision:latest.release")

    // Kotlin coroutines (optional)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
}

flutter {
    source = "../.."
}
