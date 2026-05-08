#!/bin/bash
# build.sh — собрать DynamicLayout core без Gradle
# Поддерживает: x86_64, ARM64 (aarch64)
# Использование:
#   ./build.sh           — Native .klib
#   ./build.sh native    — то же
#   ./build.sh jvm       — JVM .jar
#   ./build.sh app       — исполняемый .kexe + запуск
#   ./build.sh clean     — очистка

set -euo pipefail

# Ограничение памяти для kotlinc-native (ARM, 4GB RAM)
export JAVA_OPTS="${JAVA_OPTS:--Xmx1g -Xms512m}"

KOTLIN_VERSION="2.0.21"
SRC="src/commonMain/kotlin"
JVM_SRC="src/jvmMain/kotlin"
NATIVE_SRC="src/nativeMain/kotlin"
OUT="build"

# === Автоопределение архитектуры ===
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        KOTLIN_ARCH="linux-x86_64"
        NATIVE_TARGET="linux_x64"
        ;;
    aarch64|arm64)
        KOTLIN_ARCH="linux-aarch64"
        NATIVE_TARGET="linux_arm64"
        ;;
    *)
        echo ">>> Unsupported architecture: $ARCH"
        echo "    Supported: x86_64, aarch64"
        exit 1
        ;;
esac

NATIVE_DIR="$HOME/.kotlin-native/kotlin-native-$KOTLIN_ARCH-$KOTLIN_VERSION"
BIN="$NATIVE_DIR/bin"
KOTLIN_NATIVE="$BIN/kotlinc-native"
TARBALL="kotlin-native-$KOTLIN_ARCH-$KOTLIN_VERSION.tar.gz"

echo ">>> Architecture: $ARCH"
echo ">>> Target:       $NATIVE_TARGET"
echo ">>> Install dir:  $NATIVE_DIR"

# === Установка Kotlin/Native ===
setup() {
    if [ ! -f "$KOTLIN_NATIVE" ]; then
        echo ">>> Downloading Kotlin/Native $KOTLIN_VERSION for $KOTLIN_ARCH..."
        mkdir -p "$HOME/.kotlin-native"
        curl -sL "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/$TARBALL" |
            tar xz -C /tmp
        mv "/tmp/kotlin-native-$KOTLIN_ARCH-$KOTLIN_VERSION" "$NATIVE_DIR"
        echo ">>> Installed to $NATIVE_DIR"
    fi
}

# === Поиск plugin-а для kotlinx.serialization ===
find_plugin() {
    local plugin_jar
    plugin_jar=$(find "$NATIVE_DIR" -name "kotlinx-serialization*plugin*.jar" 2>/dev/null | head -1)
    echo "${plugin_jar:-}"
}

# === Сборка .klib ===
build_native() {
    setup
    local plugin_jar
    plugin_jar=$(find_plugin)
    if [ -z "$plugin_jar" ]; then
        echo "ERROR: kotlinx-serialization plugin not found in $NATIVE_DIR"
        exit 1
    fi
    mkdir -p "$OUT"
    echo ">>> Plugin: $plugin_jar"
    $KOTLIN_NATIVE \
        -J-Xmx1g -J-Xms512m -J-XX:+UseParallelGC -J-XX:ParallelGCThreads=2 \
        -Xplugin="$plugin_jar" \
        -produce library \
        -target "$NATIVE_TARGET" \
        -o "$OUT/dynamiclayout" \
        $(find "$SRC" -name "*.kt") \
        $(find "$NATIVE_SRC" -name "*.kt") 2>/dev/null || true
    echo ">>> Done: $OUT/dynamiclayout.klib (target: $NATIVE_TARGET)"
}

# === Сборка JVM ===
build_jvm() {
    setup
    local plugin_jar
    plugin_jar=$(find_plugin)
    mkdir -p "$OUT"
    $BIN/kotlinc \
        -J-Xmx1g -J-Xms512m \
        -Xplugin="$plugin_jar" \
        -d "$OUT/dynamiclayout-jvm.jar" \
        $(find "$SRC" -name "*.kt") \
        $(find "$JVM_SRC" -name "*.kt") 2>/dev/null || true
    echo ">>> Done: $OUT/dynamiclayout-jvm.jar"
}

# === Запуск ===
run() {
    build_native
    mkdir -p "$OUT"
    echo 'fun main() { println("DynamicLayout core: OK"); println(org.dynamiclayout.core.ui.UIElementType.entries.joinToString()) }' > "$OUT/_main.kt"
    local plugin_jar
    plugin_jar=$(find_plugin)
    $KOTLIN_NATIVE \
        -J-Xmx1g -J-Xms512m -J-XX:+UseParallelGC -J-XX:ParallelGCThreads=2 \
        -Xplugin="$plugin_jar" \
        -library "$OUT/dynamiclayout" \
        -produce program \
        -target "$NATIVE_TARGET" \
        -o "$OUT/app" \
        "$OUT/_main.kt"
    echo ">>> Running $OUT/app.kexe:"
    "$OUT/app.kexe"
    rm -f "$OUT/_main.kt"
}

clean() {
    rm -rf "$OUT"
    echo ">>> Cleaned"
}

# === CLI ===
case "${1:-native}" in
    native) build_native ;;
    jvm)    build_jvm ;;
    app)    run ;;
    clean)  clean ;;
    *)
        echo "Usage: $0 {native|jvm|app|clean}"
        exit 1
        ;;
esac
