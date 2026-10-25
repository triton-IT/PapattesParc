import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


val signingProperties = Properties().apply {
    val signingFile = rootProject.file("key.properties")
    if (signingFile.exists()) signingFile.inputStream().use { load(it) }
}
fun signingValue(key: String, environment: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: signingProperties.getProperty(key)?.takeIf { it.isNotBlank() }
val releaseStore = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val signingValues = listOf(releaseStore, releaseAlias, releaseStorePassword, releaseKeyPassword)
if (signingValues.any { it != null } && signingValues.any { it == null }) {
    throw GradleException("Incomplete Android release signing configuration")
}
val hasReleaseSigning = listOf(releaseStore, releaseAlias, releaseStorePassword, releaseKeyPassword).all { it != null }


android {
    namespace = "de.papattesparc.papatte_parc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.papattesparc.papatte_parc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("production") {
                storeFile = rootProject.file(releaseStore!!)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }
    buildTypes {
        release {
            // Without production secrets, release artifacts are unsigned, never debug-signed.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("production") else null
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
