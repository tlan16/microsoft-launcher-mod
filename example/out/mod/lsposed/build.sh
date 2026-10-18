#!/bin/bash
# Build the LSPosed module APK (modern libxposed API 102). Needs JDK + sdk/ (platforms;android-34, build-tools;34.0.0),
# lib/api102/classes.jar (from io.github.libxposed:api:102.0.0 aar) and lib/r8.jar (R8 8.9.35).
set -e
cd "$(dirname "$0")"
: "${APK_SIGNING_STORE_PASSWORD:?Set keystore password in environment}"
: "${APK_SIGNING_KEY_PASSWORD:?Set key password in environment}"
: "${APK_SIGNING_KEY_ALIAS:?Set signing key alias in environment}"
export APK_SIGNING_STORE_PASSWORD APK_SIGNING_KEY_PASSWORD
SIGNING_KEYSTORE=/app/signing/module.keystore
[ -f "$SIGNING_KEYSTORE" ] || { printf '%s\n' "Provision $SIGNING_KEYSTORE before building" >&2; exit 1; }
BT=$PWD/sdk/build-tools/34.0.0; AJ=$PWD/sdk/platforms/android-34/android.jar; API=lib/api102/classes.jar
rm -rf build out; mkdir -p build/classes out
javac --release 17 -Xlint:-options -cp "$AJ:$API" -d build/classes src/com/local/noaadprompt/ModuleMain.java
java -cp lib/r8.jar com.android.tools.r8.D8 --lib "$AJ" --min-api 26 --output build $(find build/classes -name '*.class')
$BT/aapt2 compile --dir res -o build/res.zip
$BT/aapt2 link -o build/unsigned.apk -I "$AJ" --manifest AndroidManifest.xml --min-sdk-version 26 --target-sdk-version 34 build/res.zip
(cd build && zip -q unsigned.apk classes.dex)
(cd meta && zip -q -r ../build/unsigned.apk META-INF)
$BT/zipalign -f 4 build/unsigned.apk build/aligned.apk
$BT/apksigner sign --ks "$SIGNING_KEYSTORE" --ks-key-alias "$APK_SIGNING_KEY_ALIAS" --ks-pass env:APK_SIGNING_STORE_PASSWORD --key-pass env:APK_SIGNING_KEY_PASSWORD --out out/NoAadPrompt-lsposed-api102.apk build/aligned.apk
$BT/apksigner verify --print-certs out/NoAadPrompt-lsposed-api102.apk 2>/dev/null | head -2
