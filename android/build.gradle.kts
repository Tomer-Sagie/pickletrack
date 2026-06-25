allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Pin every downstream-facing Kotlin runtime artifact (stdlib,
    // reflect, test, scripting, daemon) to the project compiler
    // version (2.2.0, see android/settings.gradle.kts). Without this
    // rule, a fresh transitive plugin can ship a newer stdlib and
    // re-introduce the metadata-mismatch build failure we hit with
    // share_plus.
    //
    // ── Upgrade procedure ──
    // When a Gradle build log says:
    //   "Module was compiled with an incompatible version of Kotlin"
    //   or  "Build Tools API Version Mismatch Detected"
    // you do two coordinated edits in the same PR:
    //   1. android/settings.gradle.kts  — bump
    //        id("org.jetbrains.kotlin.android") version "<X.Y.Z>"
    //   2. android/build.gradle.kts (this file) — set the
    //      useVersion(...) string below to that exact same "<X.Y.Z>".
    //
    // Pin is *exact, no range*, because KGP's Build Tools API requires
    // `kotlin-build-tools-impl` (and friends) to be strictly aligned
    // with the kotlin-android plugin version. A range like [2.2.0, 2.3.0)
    // would let Gradle resolve up to 2.2.21 (or higher), tripping KGP's
    // strict-alignment check. We also keep `kotlin-build-tools-*` and
    // `kotlin-compiler-*` *out* of this predicate — KGP manages those
    // internally; if we touched them, we'd override KGP's own version-
    // selection logic and crash the build.
    //
    // Note: we cannot chain `.because(...)` on the resolver's return
    // value in Kotlin DSL (Groovy-only extension); the rationale lives
    // here instead.
    val kotlinRuntimeArtifacts = setOf(
        "kotlin-stdlib",
        "kotlin-reflect",
        "kotlin-test",
        "kotlin-test-junit",
        "kotlin-script-runtime",
        "kotlin-daemon",
    )
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin"
                && requested.name in kotlinRuntimeArtifacts) {
                useVersion("2.2.0")
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
