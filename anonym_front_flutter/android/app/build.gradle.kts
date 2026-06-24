import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val isDebugBuildTask = gradle.startParameter.taskNames.any {
    it.contains("Debug", ignoreCase = true)
}
val isReleaseBuildTask = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
val keystorePropertiesFile = if (rootProject.file("key.properties").exists()) {
    rootProject.file("key.properties")
} else {
    rootProject.file("../key.properties")
}
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.anonym.front_flutter"
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
        applicationId = "com.anonym.front_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            val storePasswordValue = keystoreProperties.getProperty("storePassword")
            val keyAliasValue = keystoreProperties.getProperty("keyAlias")
            val keyPasswordValue = keystoreProperties.getProperty("keyPassword")

            if (!storeFilePath.isNullOrBlank() &&
                !storePasswordValue.isNullOrBlank() &&
                !keyAliasValue.isNullOrBlank() &&
                !keyPasswordValue.isNullOrBlank()
            ) {
                storeFile = file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            val hasValidReleaseKeystore =
                !keystoreProperties.getProperty("storeFile").isNullOrBlank() &&
                !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
                !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
                !keystoreProperties.getProperty("keyPassword").isNullOrBlank()

            if (hasValidReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else if (isReleaseBuildTask) {
                // Only error if explicitly building release APK/bundle
                throw GradleException(
                    "Release signing is not configured. " +
                        "Create android/key.properties and set storeFile, " +
                        "storePassword, keyAlias and keyPassword.",
                )
            }
        }
    }

    packaging {
        jniLibs {
            if (isDebugBuildTask) {
                excludes += setOf(
                    "lib/armeabi-v7a/**",
                    "lib/x86/**",
                    "lib/x86_64/**",
                )
            }
        }
    }
}

if (isReleaseBuildTask &&
    (!keystoreProperties.getProperty("storeFile").isNullOrBlank() &&
        !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyPassword").isNullOrBlank()).not()
) {
    throw GradleException(
        "Release task requested without configured release keystore. " +
            "See android/key.properties.",
    )
}

flutter {
    source = "../.."
}
