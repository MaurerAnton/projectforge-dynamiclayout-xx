#!/bin/bash
# build.sh — Build DynamicLayout core without Gradle
# Supports: x86_64, ARM64 (aarch64)
# Usage:
#   ./build.sh           — Native .klib (requires kotlinc-native)
#   ./build.sh native    — same
#   ./build.sh jvm       — JVM .jar (requires kotlinc)
#   ./build.sh app       — Native executable + run
#   ./build.sh clean     — cleanup

set -euo pipefail

export JAVA_OPTS="${JAVA_OPTS:--Xmx1g -Xms512m}"

KOTLIN_VERSION="2.0.21"
SRC="src/commonMain/kotlin"
JVM_SRC="src/jvmMain/kotlin"
NATIVE_SRC="src/nativeMain/kotlin"
OUT="build"

# === Architecture auto-detection ===
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        KOTLIN_ARCH="linux-x86_64"
        NATIVE_TARGET="linux_x64"
        ;;
    aarch64|arm64)
        KOTLIN_ARCH="linux-aarch64"
        NATIVE_TARGET="linux_arm64"
        echo ">>> Note: kotlin-native not available for linux-aarch64."
        echo "    Native build will fail. Use Gradle or cross-compile from x86_64."
        echo "    JVM build will work if kotlinc is available."
        ;;
    *)
        echo ">>> Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

NATIVE_DIR="$HOME/.kotlin-native/kotlin-native-prebuilt-$KOTLIN_ARCH-$KOTLIN_VERSION"
BIN="$NATIVE_DIR/bin"
KOTLIN_NATIVE="$BIN/kotlinc-native"
TARBALL="kotlin-native-prebuilt-$KOTLIN_ARCH-$KOTLIN_VERSION.tar.gz"

echo ">>> Architecture: $ARCH"
echo ">>> Target:       $NATIVE_TARGET"

# === Download Kotlin/Native ===
setup() {
    if [ ! -f "$KOTLIN_NATIVE" ]; then
        echo ">>> Downloading Kotlin/Native $KOTLIN_VERSION for $KOTLIN_ARCH..."
        mkdir -p "$HOME/.kotlin-native"
        if curl -sLf "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/$TARBALL" -o /tmp/$TARBALL; then
            tar xzf /tmp/$TARBALL -C /tmp
            mv "/tmp/kotlin-native-prebuilt-$KOTLIN_ARCH-$KOTLIN_VERSION" "$NATIVE_DIR"
            rm /tmp/$TARBALL
            echo ">>> Installed to $NATIVE_DIR"
        else
            echo ">>> Failed to download kotlin-native (expected on ARM64 Linux)."
            echo "    Use Gradle instead: ./gradlew build"
            return 1
        fi
    fi
}

# === Find kotlinx-serialization plugin ===
find_plugin() {
    local plugin_jar
    plugin_jar=$(find "$NATIVE_DIR" -name "kotlinx-serialization*plugin*.jar" 2>/dev/null | head -1)
    echo "${plugin_jar:-}"
}

# === Build .klib (Native) ===
build_native() {
    setup || return 1
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
        $(find "$NATIVE_SRC" -name "*.kt")
    echo ">>> Done: $OUT/dynamiclayout.klib (target: $NATIVE_TARGET)"
}

# === Build JVM .jar ===
build_jvm() {
    which kotlinc 2>/dev/null || which kotlinc-jvm 2>/dev/null || {
        echo ">>> kotlinc not found. Try:"
        echo "    ./gradlew jvmJar"
        return 1
    }
    local KOTLINC
    KOTLINC=$(which kotlinc 2>/dev/null || which kotlinc-jvm 2>/dev/null)
    mkdir -p "$OUT"
    echo ">>> Compiling JVM with: $KOTLINC"
    $KOTLINC \
        -J-Xmx1g -J-Xms512m \
        -d "$OUT/dynamiclayout-jvm.jar" \
        $(find "$SRC" -name "*.kt") \
        $(find "$JVM_SRC" -name "*.kt")
    echo ">>> Done: $OUT/dynamiclayout-jvm.jar"
}

# === Build and run native executable ===
run() {
    build_native || return 1
    local plugin_jar
    plugin_jar=$(find_plugin)
    cat > "$OUT/_main.kt" << 'EOF'
fun main() {
    println("DynamicLayout core: OK")
    println(org.dynamiclayout.core.ui.UIElementType.entries.joinToString())
}
EOF
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
        echo "  On x86_64: native, app — use kotlinc-native"
        echo "  Any arch:  jvm — use kotlinc (system JDK)"
        exit 1
        ;;
esac
