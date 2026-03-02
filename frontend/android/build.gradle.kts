allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Fix for isar_flutter_libs namespace issue
    subprojects {
        afterEvaluate {
            if (project.name == "isar_flutter_libs" && project.hasProperty("android")) {
                project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                    namespace = "com.isar.flutter_libs"
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
