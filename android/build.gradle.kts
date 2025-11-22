import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// [여기서부터 복사] 최신 Gradle 대응 패치
subprojects {
    val action = {
        // (A) 옛날 라이브러리 이름표(Namespace) 붙여주기
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, project.group.toString())
                }
            } catch (e: Exception) {}
        }

        // (B) 코틀린 버전 맞추기 (최신 문법: compilerOptions 사용)
        tasks.withType(KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }

    // 실행 타이밍 체크
    if (state.executed) {
        action()
    } else {
        afterEvaluate { action() }
    }
}