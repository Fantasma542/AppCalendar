// Añade esto al inicio del archivo (si no existe)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.3.2") // Actualiza a la última versión estable
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // Versión compatible
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuración de directorios de build (puedes mantener lo que tienes)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    
    // Añade esta configuración para cada subproyecto
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(35)
                ndkVersion = "27.0.12077973"
                
                defaultConfig {
                    minSdk = 21
                    targetSdk = 35
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}