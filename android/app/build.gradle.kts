plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.wma_mg_6_sigap_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.wma_mg_6_sigap_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Menyetel target Kotlin ke Java 17 menggunakan Toolchain (paling aman untuk AGP 9.0+)
kotlin {
    jvmToolchain(17)
}


org.gradle.java.installations.paths=C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot