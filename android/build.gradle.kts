import com.android.build.gradle.LibraryExtension
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Inject proguard keep rules into flutter_inappwebview_android and optionally relax its minify
subprojects {
    if (name == "flutter_inappwebview_android") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                defaultConfig {
                    // Use the app's proguard rules to keep inappwebview classes referenced via reflection
                    consumerProguardFiles(file("${rootProject.projectDir}/app/proguard-rules.pro"))
                }
                buildTypes {
                    // If the plugin still fails minify in its own module, disable shrinking here
                    maybeCreate("release").apply {
                        isMinifyEnabled = false
                        isJniDebuggable = false
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
