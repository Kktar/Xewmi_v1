#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROP="$ROOT/android/gradle.properties"
APP_GRADLE="$ROOT/android/app/build.gradle.kts"

cat > "$PROP" << 'PROPS'
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.newDsl=false
android.builtInKotlin=false
PROPS

if [ -f "$APP_GRADLE" ]; then
  sed -i 's/compileSdk = flutter.compileSdkVersion/compileSdk = 36/' "$APP_GRADLE" || true
  sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/' "$APP_GRADLE" || true
  sed -i 's/targetSdk = flutter.targetSdkVersion/targetSdk = 36/' "$APP_GRADLE" || true
  echo "Patched app/build.gradle.kts"
fi
echo "OK — android.newDsl=false + SDK 36"
