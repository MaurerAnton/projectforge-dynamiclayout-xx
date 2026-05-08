# ProjectForge DynamicLayout — Native Build
# Делегирует build.sh. Автоопределение архитектуры (x86_64 / ARM64).
# Использование: make [native|jvm|app|test|clean]

.PHONY: all native jvm app test clean

all: native

native:
	./build.sh native

jvm:
	./build.sh jvm

app:
	./build.sh app

# Тесты: определяется путь к kotlinc-native и target динамически
test: native
	@mkdir -p build
	@ARCH=$$(uname -m); \
	case "$$ARCH" in \
		x86_64|amd64) TARGET=linux_x64; DIR=linux-x86_64;; \
		aarch64|arm64) TARGET=linux_arm64; DIR=linux-aarch64;; \
	esac; \
	KOTLIN_DIR=$$HOME/.kotlin-native/kotlin-native-$$DIR-2.0.21; \
	PLUGIN=$$(find $$KOTLIN_DIR -name "*serial*plugin*.jar" | head -1); \
	echo ">>> Target: $$TARGET"; \
	$$KOTLIN_DIR/bin/kotlinc-native \
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
