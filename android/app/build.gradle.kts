plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.juju.schedule"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.juju.schedule"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two installable builds sharing one Flutter codebase.
    //  - prod   : public app "JUJU Schedule" (unchanged applicationId/data dir, no AI).
    //  - private: private AI app "JUJU aiSchedule" (Gemini Smart Add).
    flavorDimensions += "version"
    productFlavors {
        create("prod") {
            dimension = "version"
            applicationId = "com.juju.schedule"
        }
        create("private") {
            dimension = "version"
            // Deliberately keep the historical ".dev" applicationId so an
            // existing com.juju.schedule.dev install upgrades in place.
            // Distinct applicationId => separate install, data dir, prefs and
            // SQLite database. Never shares user data with prod.
            applicationId = "com.juju.schedule.dev"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}

// Flutter copies release output as app-<flavor>-release.apk; also emit a
// branded copy for each flavor.
tasks.register("copyBrandedReleaseApk") {
    doLast {
        val flutterApkDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
        val branded = mapOf(
            "prod" to "JUJUSchedule-v${flutter.versionName}.apk",
            "private" to "JUJUaiSchedule-v${flutter.versionName}.apk",
        )
        branded.forEach { (flavor, targetName) ->
            val from = flutterApkDir.resolve("app-$flavor-release.apk")
            if (from.exists()) {
                from.copyTo(flutterApkDir.resolve(targetName), overwrite = true)
            }
        }
    }
}

afterEvaluate {
    tasks.matching {
        it.name == "assembleRelease" ||
            it.name == "assembleProdRelease" ||
            it.name == "assemblePrivateRelease"
    }.configureEach {
        finalizedBy("copyBrandedReleaseApk")
    }
}
