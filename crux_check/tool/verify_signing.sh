#!/usr/bin/env bash
# Confirms the release bundle is signed with your upload key and not the debug
# key. Worth running before every upload: a debug-signed bundle builds without
# complaint and is only rejected once Play has it, and the fallback in
# build.gradle.kts makes that failure mode silent by design.
set -uo pipefail

AAB="build/app/outputs/bundle/release/app-release.aab"
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ ! -f "$AAB" ]; then
  echo "No bundle at $AAB — run: flutter build appbundle --release"
  exit 1
fi

fingerprint_of_aab() {
  keytool -printcert -jarfile "$AAB" 2>/dev/null \
    | grep -m1 "SHA256:" | sed 's/.*SHA256: *//' | tr -d ' '
}

fingerprint_of_debug() {
  [ -f "$DEBUG_KEYSTORE" ] || return 0
  keytool -list -v -keystore "$DEBUG_KEYSTORE" \
    -alias androiddebugkey -storepass android 2>/dev/null \
    | grep -m1 "SHA256:" | sed 's/.*SHA256: *//' | tr -d ' '
}

aab_fp="$(fingerprint_of_aab)"
debug_fp="$(fingerprint_of_debug)"

if [ -z "$aab_fp" ]; then
  echo "FAIL: the bundle carries no signature at all."
  exit 1
fi

echo "bundle SHA-256: $aab_fp"

if [ -n "$debug_fp" ] && [ "$aab_fp" = "$debug_fp" ]; then
  echo
  echo "FAIL: this is the DEBUG key. Play will reject it."
  echo "      android/key.properties is missing or not being read."
  exit 1
fi

echo
echo "OK: signed with a key that is not the debug key."
echo "    Check the fingerprint above matches your upload key:"
echo "      keytool -list -v -keystore <your.jks> -alias upload"
