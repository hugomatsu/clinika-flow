# Firebase Setup — Flutter Project

Reusable guide for integrating Firebase into a Flutter project using **FlutterFire CLI**. Covers initial setup, platform config files, Google Sign-In, App Distribution, and the decision of what to commit vs. keep out of git.

---

## Prerequisites

```bash
# Firebase CLI (used for login, deploy, app distribution)
npm install -g firebase-tools

# FlutterFire CLI (used to generate firebase_options.dart)
dart pub global activate flutterfire_cli

# Log in once — subsequent commands reuse this session
firebase login
```

---

## 1. Create the Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/) → **Add project**
2. Enable Google Analytics if desired
3. Add an **Android app** (package name e.g. `com.company.appname`)
4. Add an **iOS app** (bundle ID e.g. `com.company.appName`)
5. Add a **Web app** if needed

---

## 2. Link the Local Repo to the Firebase Project

From the repo root:

```bash
firebase use --add
# Select your Firebase project → alias it as "default"
```

This creates `.firebaserc`:
```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

---

## 3. Generate `firebase_options.dart` with FlutterFire CLI

From inside the Flutter project directory (`magic_echoes/`):

```bash
flutterfire configure
```

This command:
- Downloads `google-services.json` → `android/app/google-services.json`
- Downloads `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
- Generates `lib/firebase_options.dart` with platform-specific `FirebaseOptions`

**Run this again any time** you add a new platform or change Firebase project settings.

---

## 4. Apply the Gradle Plugin (Android)

In `android/app/build.gradle.kts`, add the Google Services plugin:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // ← add this
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

In `android/build.gradle.kts` (project-level), ensure the classpath is present:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

---

## 5. Initialize Firebase in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

---

## 6. What to Commit vs. Keep Out of Git

### What this project does (and why it's acceptable)

Firebase client-side config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) **contain API keys that are safe to commit** for most projects. Here's why:

- These keys only identify your Firebase project — they do **not** grant admin access
- Access is protected by **Firebase Security Rules** and **Firebase Authentication**, not by keeping the keys secret
- Google explicitly states these files may be committed for client apps
- Committing them simplifies CI/CD (no secret injection needed)

All three files are committed in this project:

| File | Committed | Reason |
|---|---|---|
| `lib/firebase_options.dart` | ✅ Yes | FlutterFire-generated, client-safe |
| `android/app/google-services.json` | ✅ Yes | Client-safe, required for build |
| `ios/Runner/GoogleService-Info.plist` | ✅ Yes | Client-safe, required for build |
| `.firebaserc` | ✅ Yes | Project alias, not sensitive |
| `firebase.json` | ✅ Yes | Deployment config, not sensitive |
| `functions/.env` | ❌ No | Contains real secret keys (e.g. GEMINI_API_KEY) |
| Service account JSON | ❌ Never | Full admin access — never commit |

### What must NEVER be committed

- **Service account keys** (`serviceAccountKey.json`) — grant full admin access to your project
- **Cloud Functions secrets** (`.env` files with API keys like `GEMINI_API_KEY`)
- **Admin SDK credentials** of any kind

For Cloud Functions secrets, use a `.env` file (ignored by git) or [Firebase Secret Manager](https://firebase.google.com/docs/functions/config-env#secret-manager):

```bash
# functions/.env  (add to .gitignore)
GEMINI_API_KEY=your_key_here
```

```bash
# functions/.env.example  (commit this as a template)
GEMINI_API_KEY=your_gemini_api_key_here
```

### If you want to keep config files out of git (open-source projects)

Add to `.gitignore`:
```gitignore
# Firebase client config
magic_echoes/lib/firebase_options.dart
magic_echoes/android/app/google-services.json
magic_echoes/ios/Runner/GoogleService-Info.plist
```

Then inject them in CI/CD using repository secrets and a setup step:
```yaml
# Example: GitHub Actions
- name: Write Firebase config
  run: |
    echo "$GOOGLE_SERVICES_JSON" > magic_echoes/android/app/google-services.json
    echo "$FIREBASE_OPTIONS"     > magic_echoes/lib/firebase_options.dart
  env:
    GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}
    FIREBASE_OPTIONS:     ${{ secrets.FIREBASE_OPTIONS }}
```

---

## 7. Google Sign-In Setup

Google Sign-In requires extra configuration beyond just adding the `google_sign_in` package.

### pubspec.yaml
```yaml
dependencies:
  google_sign_in: ^6.2.2
```

### Android — Register SHA-1 fingerprint

Google Sign-In on Android verifies the APK's signing certificate via SHA-1. Without registering it, you get error code **10 (DEVELOPER_ERROR)**.

**Get your debug keystore SHA-1:**
```bash
keytool -exportcert -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android | openssl sha1 -hex
```

**Get your release keystore SHA-1** (if using a custom keystore):
```bash
keytool -exportcert -alias YOUR_ALIAS \
  -keystore path/to/release.keystore \
  -storepass YOUR_PASSWORD | openssl sha1 -hex
```

**Register in Firebase Console:**
1. Firebase Console → Project Settings → Your Android app
2. Scroll to **SHA certificate fingerprints** → **Add fingerprint**
3. Add SHA-1 (and SHA-256 for Google Play App Signing)
4. Save → **Download updated `google-services.json`** and replace the local file

> You must re-download `google-services.json` after this step — it populates the `oauth_client` array, which the `google_sign_in` plugin needs to discover the correct OAuth client ID.

### Firebase Console — Enable Google Sign-In
1. Firebase Console → **Authentication → Sign-in method → Google** → Enable → Save

### iOS — URL Scheme

Add the `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

The `REVERSED_CLIENT_ID` value is found in `GoogleService-Info.plist` under the `REVERSED_CLIENT_ID` key (only present once an iOS OAuth client is registered in Firebase Console).

---

## 8. Firebase App Distribution Build Script

The project uses a local shell script (`build-share-android.sh`) for building and distributing the APK. Authentication relies on `firebase login` (no embedded credentials).

```bash
#!/usr/bin/env bash
set -euo pipefail

FIREBASE_APP_ID="1:YOUR_PROJECT_NUMBER:android:YOUR_APP_HASH"
FIREBASE_GROUP="devs"     # tester group in App Distribution

# Build
cd magic_echoes
flutter build apk --release

# Distribute
cd ..
firebase appdistribution:distribute \
  "magic_echoes/build/app/outputs/flutter-apk/app-release.apk" \
  --app "$FIREBASE_APP_ID" \
  --release-notes "$RELEASE_NOTES" \
  --groups "$FIREBASE_GROUP"
```

**Find your `FIREBASE_APP_ID`:** Firebase Console → Project Settings → Your Android app → App ID.

---

## 9. Adding Firebase Services

Each service requires its own package. All packages are listed in `pubspec.yaml` under `# Firebase`:

```yaml
firebase_core: ^3.x.x        # always required
firebase_auth: ^5.x.x        # authentication
cloud_firestore: ^5.x.x      # database
firebase_storage: ^12.x.x    # file storage
cloud_functions: ^5.x.x      # callable functions
firebase_analytics: ^11.x.x  # analytics
firebase_crashlytics: ^4.x.x # crash reporting
```

### Crashlytics — `main.dart` initialization

```dart
// Mobile only (not web)
if (!kIsWeb) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```

### Analytics — GoRouter screen tracking

```dart
GoRouter(
  observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
  // ...
)
```

---

## 10. Re-running FlutterFire Configure

Run `flutterfire configure` again whenever:
- You add a new platform (e.g. adding iOS after starting Android-only)
- You register new SHA-1 fingerprints (re-download `google-services.json`)
- You enable new Firebase services (sometimes requires updated config)
- You switch Firebase projects

```bash
cd magic_echoes
flutterfire configure --project=your-firebase-project-id
```

---

## Quick-Start Checklist for a New Project

```
[ ] npm install -g firebase-tools
[ ] dart pub global activate flutterfire_cli
[ ] firebase login
[ ] Create Firebase project in console
[ ] Add Android + iOS apps in console
[ ] firebase use --add  (from repo root)
[ ] cd <flutter_project> && flutterfire configure
[ ] Add google-services plugin to android/app/build.gradle.kts
[ ] Add firebase_core (+ other services) to pubspec.yaml
[ ] Call Firebase.initializeApp() in main()
[ ] For Google Sign-In: register SHA-1 → re-download google-services.json
[ ] For App Distribution: copy build-share-android.sh, update FIREBASE_APP_ID
[ ] For secrets (Cloud Functions etc.): create .env, add to .gitignore, commit .env.example
```
