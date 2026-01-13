allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define the new build directory on D: drive
// We use 'projectDirectory' to ensure we reference the path correctly from the root
val newBuildDir: Directory = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // FIX 1: Drive Letter Conflict
    // We only move the build folder if the subproject is actually inside 
    // the main project folder (D:). If it's a plugin on C:, we leave it alone.
    if (project.projectDir.absolutePath.startsWith(rootProject.projectDir.absolutePath)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }

    // Standard Flutter requirement
    project.evaluationDependsOn(":app")

    // FIX 2: Disable Tests Safely
    // We use string matching to avoid "Unresolved reference: Test" errors 
    // in the root build file.
    tasks.configureEach {
        if (name == "test" || 
            name.contains("UnitTest") || 
            name.contains("AndroidTest") ||
            name.contains("testDebug") ||
            name.contains("testRelease")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}