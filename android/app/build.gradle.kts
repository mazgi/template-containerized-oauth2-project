plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "dev.mazgi.app"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }

    defaultConfig {
        applicationId = "dev.mazgi.app"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField(
            "String",
            "GIT_SHA",
            "\"${
                providers.exec { commandLine("git", "rev-parse", "--short", "HEAD") }
                    .standardOutput.asText.get().trim()
            }\""
        )
    }

    buildTypes {
        debug {
            // Backend API base URL (emulator uses 10.0.2.2 to reach host machine)
            // Override with: ./gradlew ... -PAPI_BASE_URL=http://host:4000
            buildConfigField("String", "API_BASE_URL",
                "\"${project.findProperty("API_BASE_URL") ?: "http://10.0.2.2:4000"}\"")
            // Twitter OAuth requires localhost for PKCE session cookie domain consistency
            // (requires `adb reverse tcp:4000 tcp:4000`)
            // Override with: ./gradlew ... -PTWITTER_AUTH_BASE_URL=http://host:4000
            buildConfigField("String", "TWITTER_AUTH_BASE_URL",
                "\"${project.findProperty("TWITTER_AUTH_BASE_URL") ?: "http://localhost:4000"}\"")
        }
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            buildConfigField("String", "API_BASE_URL",
                "\"${project.findProperty("API_BASE_URL") ?: "http://10.0.2.2:4000"}\"")
            buildConfigField("String", "TWITTER_AUTH_BASE_URL",
                "\"${project.findProperty("TWITTER_AUTH_BASE_URL") ?: "http://localhost:4000"}\"")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.browser)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}