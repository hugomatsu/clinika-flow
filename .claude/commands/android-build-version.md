---
description: Increment build number, generate release notes, build Android APK, and upload to Firebase App Distribution
---

# Build Version and Upload

This workflow handles incrementing the application build number, generating release notes based on recent changes, building the Android APK, and distributing it via Firebase.

1. **Generate Release Notes**
   - Review the tasks that were just completed.
   - Use `git log --oneline -n 5` or similar commands to understand the recent changes in the branch.
   - Formulate concise and descriptive release notes summarizing the updates, new features, or bug fixes.

2. **Update Changelog**
   - Update `magic_echoes/lib/core/config/changelog.dart` by adding a new `ChangelogRelease` object at the top of the `appChangelog` list. Ensure it includes the current version string (read from `version.json` and increment the `build_number` by 1 to get the next value, e.g., `1.0.0+<build_number+1>`), today's date (`YYYY-MM-DD`), and the list of changes you summarized.

3. **Run the build script**
   - From the repo root, run the `build-share-android.sh` script, passing the release notes via `--notes`:
   ```bash
   ./build-share-android.sh --notes "<Your generated release notes>"
   ```
   - The script will automatically:
     - Increment `build_number` in `version.json` and `version` in `pubspec.yaml`
     - Build the release APK (`flutter build apk`)
     - Upload the APK to Firebase App Distribution (group: `devs`, App ID: `1:630109216508:android:ef518e73282351cfaf8179`)
   - Note the Firebase App Distribution download link and console link from the script output once the upload is complete.
