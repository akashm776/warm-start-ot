plugins {
    `java-library`
}

group = "optimaltransport"
version = "0.1.0"

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

sourceSets {
    main {
        java {
            srcDir("java/src/main/java")
        }
    }
}

tasks.jar {
    archiveBaseName.set("warmstart-ot")
    destinationDirectory.set(layout.projectDirectory.dir("java/build/libs"))
}

repositories {
    mavenCentral()
}
