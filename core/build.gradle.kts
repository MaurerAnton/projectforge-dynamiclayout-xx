plugins {
    id("org.jetbrains.kotlin.multiplatform") version "2.0.21"
}

group = "org.dynamiclayout"
version = "0.1.0"

repositories {
    mavenCentral()
}

kotlin {
    jvm {
        compilations.all {
            kotlinOptions.jvmTarget = "17"
        }
    }

    linuxX64()
    macosX64()
    macosArm64()
    mingwX64()
    linuxArm64()
    js(IR) {
        browser()
        nodejs()
    }

    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation(kotlin("stdlib-common"))
            }
        }

        val jvmMain by getting {
            dependencies {
                implementation(kotlin("stdlib-jdk8"))
            }
        }

        val nativeMain by creating {
            dependsOn(commonMain)
        }

        val jvmTest by getting

        val jsMain by getting {
            dependencies {
                implementation(kotlin("stdlib-js"))
            }
        }

        linuxX64().compilations["main"].defaultSourceSet.dependsOn(nativeMain)
        macosX64().compilations["main"].defaultSourceSet.dependsOn(nativeMain)
        macosArm64().compilations["main"].defaultSourceSet.dependsOn(nativeMain)
        mingwX64().compilations["main"].defaultSourceSet.dependsOn(nativeMain)
        linuxArm64().compilations["main"].defaultSourceSet.dependsOn(nativeMain)
    }
}
