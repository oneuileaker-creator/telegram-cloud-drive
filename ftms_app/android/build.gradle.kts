allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                namespace = project.group.toString()
            }
        }
    }
    plugins.withId("com.android.application") {
        configure<com.android.build.gradle.AppExtension> {
            if (namespace == null) {
                namespace = project.group.toString()
            }
        }
    }
}

subprojects {
    val configureCompile = Action<Project> {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val javaTask = project.tasks.withType<JavaCompile>().firstOrNull()
            if (javaTask != null) {
                val target = javaTask.targetCompatibility.toString()
                if (target == "1.8" || target == "8") {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
                } else if (target == "11") {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                } else if (target == "17") {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                } else if (target == "21") {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
                }
            }
        }
    }
    if (state.executed) {
        configureCompile.execute(this)
    } else {
        afterEvaluate(configureCompile)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
