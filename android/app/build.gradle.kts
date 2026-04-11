plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vton_auth"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.vton_auth"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val cameraKitApiToken: String =
            project.findProperty("cameraKitApiToken") as? String ?: ""
        val lensId: String =
            project.findProperty("lensId") as? String ?: ""
        val lensGroupId: String =
            project.findProperty("lensGroupId") as? String ?: ""

        manifestPlaceholders["cameraKitApiToken"] = cameraKitApiToken
        buildConfigField("String", "LENS_ID", "\"$lensId\"")
        buildConfigField("String", "LENS_GROUP_ID", "\"$lensGroupId\"")
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val cameraKitVersion = "1.47.0"
    implementation("com.snap.camerakit:camerakit:$cameraKitVersion")
    implementation("com.snap.camerakit:camerakit-kotlin:$cameraKitVersion") // ← FIXES Session() lambda
    implementation("com.snap.camerakit:support-camerax:$cameraKitVersion")

    val cameraxVersion = "1.4.1"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("androidx.camera:camera-view:$cameraxVersion")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}