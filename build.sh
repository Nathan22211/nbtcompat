#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
INST="${INST:-/home/nathan/.local/share/atlauncher/instances/kizaotastic}"
LIB="/home/nathan/.local/share/atlauncher/libraries"
OUT="$ROOT/build"
CLASSES="$OUT/classes"
JAR_OUT="$OUT/libs/nbtcompat-1.0.0.jar"

rm -rf "$CLASSES"
mkdir -p "$CLASSES" "$OUT/libs" "$ROOT/libs"

CP=""
add_jar() {
  local f="$1"
  if [[ -f "$f" ]]; then
    CP="${CP:+$CP:}$f"
  else
    echo "WARN: missing $f" >&2
  fi
}

ANN_JAR="$ROOT/libs/annotations-24.1.0.jar"
if [[ ! -f "$ANN_JAR" ]]; then
  curl -fsSL -o "$ANN_JAR" "https://repo1.maven.org/maven2/org/jetbrains/annotations/24.1.0/annotations-24.1.0.jar" || true
fi
add_jar "$ANN_JAR"
add_jar "$ROOT/libs/moonlight-neoforge-1.21.1-3.0.19.jar"
# Prefer instance moonlight if present
ML=$(echo "$INST"/mods/moonlight-*.jar 2>/dev/null | awk '{print $1}')
[[ -n "${ML:-}" && -f "$ML" ]] && add_jar "$ML"

add_jar "$INST/mods/kubejs-neoforge-2101.7.2-build.368.jar"
RHINO=$(echo "$INST"/mods/rhino-*.jar | awk '{print $1}')
add_jar "$RHINO"

JEI=$(echo "$INST"/mods/jei-*-neoforge-*.jar | awk '{print $1}')
add_jar "$JEI"

AWT=$(echo "$INST"/mods/artisanworktables-*.jar | awk '{print $1}')
add_jar "$AWT"
# Prefer freshly built AWT from sibling project when present
[[ -f /home/nathan/artisan-worktables/build/libs/artisanworktables-1.0.0.jar ]] \
  && add_jar /home/nathan/artisan-worktables/build/libs/artisanworktables-1.0.0.jar

add_jar "$INST/mods/create-1.21.1-6.0.10.jar"
CHIPPED=$(echo "$INST"/mods/chipped-*.jar | awk '{print $1}')
add_jar "$CHIPPED"
RLIB=$(echo "$INST"/mods/resourcefullib-*.jar | awk '{print $1}')
add_jar "$RLIB"
MEK=$(echo "$INST"/mods/Mekanism-[0-9]*.jar | awk '{print $1}')
add_jar "$MEK"
# Create embeds Ponder / Registrate — extract for compile classpath
JJ="$OUT/create-jarjar"
mkdir -p "$JJ"
if [[ ! -f "$JJ/ponder-neoforge.jar" || ! -f "$JJ/Registrate-MC1.21-1.3.0+67.jar" ]]; then
  (
    cd "$JJ"
    jar xf "$INST/mods/create-1.21.1-6.0.10.jar" META-INF/jarjar/
    cp META-INF/jarjar/ponder-neoforge-1.0.82+mc1.21.1.jar ponder-neoforge.jar
    cp META-INF/jarjar/Registrate-MC1.21-1.3.0+67.jar .
    rm -rf META-INF
  )
fi
add_jar "$JJ/ponder-neoforge.jar"
add_jar "$JJ/Registrate-MC1.21-1.3.0+67.jar"
# Create jars its API deps; also need mixin annotations for casing mixins
MIXIN=$(echo "$LIB"/net/fabricmc/sponge-mixin/*/sponge-mixin-*.jar | awk '{print $1}')
add_jar "$MIXIN"
ASM=$(echo "$LIB"/org/ow2/asm/asm/*/asm-*.jar | awk '{print $1}')
add_jar "$ASM"

add_jar "$LIB/net/neoforged/neoforge/21.1.235/neoforge-21.1.235-universal.jar"
add_jar "$LIB/net/neoforged/fancymodloader/loader/4.0.43/loader-4.0.43.jar"
add_jar "$LIB/net/neoforged/bus/8.0.5/bus-8.0.5.jar"
add_jar "$LIB/net/neoforged/neoforge/21.1.235/neoforge-21.1.235-client.jar"
add_jar "$LIB/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar"
add_jar "$LIB/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar"
add_jar "$LIB/com/mojang/brigadier/1.3.10/brigadier-1.3.10.jar"
add_jar "$LIB/com/mojang/datafixerupper/8.0.16/datafixerupper-8.0.16.jar"
LOG4J=$(echo "$LIB"/org/apache/logging/log4j/log4j-api/*/log4j-api-*.jar | awk '{print $1}')
add_jar "$LOG4J"
add_jar "$LIB/net/neoforged/mergetool/2.0.0/mergetool-2.0.0-api.jar"
FASTUTIL=$(echo "$LIB"/it/unimi/dsi/fastutil/*/fastutil-*.jar | awk '{print $NF}')
add_jar "$FASTUTIL"
COMMONS=$(echo "$LIB"/org/apache/commons/commons-lang3/*/commons-lang3-*.jar | awk '{print $NF}')
add_jar "$COMMONS"
GUAVA=$(echo "$LIB"/com/google/guava/guava/*/guava-*.jar | awk '{print $NF}')
add_jar "$GUAVA"
add_jar "$LIB/io/netty/netty-buffer/4.1.97.Final/netty-buffer-4.1.97.Final.jar"
NETTY_COMMON=$(echo "$LIB"/io/netty/netty-common/*/netty-common-*.jar | awk '{print $NF}')
add_jar "$NETTY_COMMON"

mapfile -t SOURCES < <(find "$ROOT/src/main/java" -name '*.java' | sort)

echo "Compiling ${#SOURCES[@]} sources..."
javac --release 21 -cp "$CP" -d "$CLASSES" "${SOURCES[@]}"

echo "Packaging $JAR_OUT ..."
jar cf "$JAR_OUT" -C "$CLASSES" .
(
  cd "$ROOT/src/main/resources"
  jar uf "$JAR_OUT" META-INF assets data kubejs.plugins.txt nbtcompat.mixins.json nbtcompat_create.mixins.json nbtcompat_mekanism.mixins.json
)

echo "Jar contents (top):"
jar tf "$JAR_OUT" | head -50
ls -lh "$JAR_OUT"

cp "$JAR_OUT" "$INST/mods/"
echo "Installed to $INST/mods/$(basename "$JAR_OUT")"
