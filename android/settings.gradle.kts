pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // Firebase(Google Services) 버전을 최신 라이브러리와 호환되도록 업데이트
    id("com.google.gms.google-services") version "4.4.1" apply false
    // Kotlin 버전을 에러 메시지에 맞춰 2.1.0으로 업데이트
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")