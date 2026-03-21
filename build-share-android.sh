#!/usr/bin/env bash
set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
FIREBASE_APP_ID="1:861507979595:android:c797fa6f23b57da655c0ce"
TESTERS_GROUP="devs"
VERSION_FILE="version.json"
PUBSPEC_FILE="pubspec.yaml"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# ─── Parse args ──────────────────────────────────────────────────────────────
NOTES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$NOTES" ]]; then
  echo "Usage: ./build-share-android.sh --notes \"Release notes here\""
  exit 1
fi

# ─── Increment build number ─────────────────────────────────────────────────
VERSION_NAME=$(python3 -c "import json; d=json.load(open('$VERSION_FILE')); print(d['version_name'])")
OLD_BUILD=$(python3 -c "import json; d=json.load(open('$VERSION_FILE')); print(d['build_number'])")
NEW_BUILD=$((OLD_BUILD + 1))

echo "Incrementing build number: $OLD_BUILD -> $NEW_BUILD"

# Update version.json
python3 -c "
import json
with open('$VERSION_FILE', 'r+') as f:
    d = json.load(f)
    d['build_number'] = $NEW_BUILD
    f.seek(0)
    json.dump(d, f, indent=2)
    f.write('\n')
    f.truncate()
"

# Update pubspec.yaml
sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD}/" "$PUBSPEC_FILE"

echo "Version: ${VERSION_NAME}+${NEW_BUILD}"

# ─── Build APK ───────────────────────────────────────────────────────────────
echo "Building release APK..."

# Resolve dependencies first to ensure correct Flutter SDK is used
flutter pub get

flutter build apk --release

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: APK not found at $APK_PATH"
  exit 1
fi

echo "APK built successfully: $APK_PATH"

# ─── Upload to Firebase App Distribution ─────────────────────────────────────
echo "Uploading to Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --groups "$TESTERS_GROUP" \
  --release-notes "$NOTES"

echo ""
echo "Done! Version ${VERSION_NAME}+${NEW_BUILD} uploaded."
echo "Console: https://console.firebase.google.com/project/_/appdistribution/app/android:$FIREBASE_APP_ID/releases"
