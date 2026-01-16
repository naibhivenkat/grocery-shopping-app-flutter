plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.grocery_app_new_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // ✅ MUST MATCH the package name in your google-services.json
        applicationId = "com.example.groceryshoppingapp.customer"
        
        // 🔴 CRITICAL FIX: Change this from flutter.minSdkVersion to 21
        minSdk = flutter.minSdkVersion 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

buildTypes {
    release {
        // ✅ For testing (release build but debug keystore)
        signingConfig = signingConfigs.getByName("debug")

        // ✅ IMPORTANT: prevent removing notification icon resource
        isMinifyEnabled = false
        isShrinkResources = false
    }

    debug {
        // optional
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
