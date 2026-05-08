# DynamicLayout Core — Native Build without Gradle
# Requires: kotlinc-native on x86_64
# On ARM64: use 'make gradle' instead
# Usage: make [native|jvm|app|test|gradle|clean]

.PHONY: all native jvm app test clean

all: native

native:
	./build.sh native

jvm:
	./build.sh jvm

app:
	./build.sh app

test: native
	@mkdir -p build
	@ARCH=$$(uname -m); \
	case "$$ARCH" in \
		x86_64|amd64) TARGET=linux_x64; DIR=linux-x86_64;; \
		aarch64|arm64) TARGET=linux_arm64; DIR=linux-aarch64;; \
	esac; \
	KOTLIN_DIR=$$HOME/.kotlin-native/kotlin-native-prebuilt-$$DIR-2.0.21; \
	PLUGIN=$$(find $$KOTLIN_DIR -name "*serial*plugin*.jar" | head -1); \
	if [ -z "$$PLUGIN" ]; then \
		echo "kotlinx-serialization plugin not found."; \
		echo "Try: ./gradlew test"; \
		exit 1; \
	fi; \
	echo ">>> Target: $$TARGET"; \
	$$KOTLIN_DIR/bin/kotlinc-native \
		-J-Xmx1g -J-Xms512m \
		-Xplugin="$$PLUGIN" \
		-library build/dynamiclayout \
		-produce program \
		-target "$$TARGET" \
		-o build/test \
		tests/src/Tests.kt && \
	echo ">>> Running tests..." && \
	./build/test.kexe

clean:
	./build.sh clean
