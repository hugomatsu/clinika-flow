---
description: Increment build number, generate release notes, build Android APK, and upload to Firebase App Distribution
---

# Build Version and Upload

This workflow handles incrementing the application build number, generating release notes based on recent changes, building the Android APK, and distributing it via Firebase.

1. **Generate Release Notes**
   - Review the tasks that were just completed.
   - Use `git log --oneline -n 5` or similar commands to understand the recent changes in the branch.
   - Formulate concise and descriptive release notes summarizing the updates, new features, or bug fixes.

2. **Run the build script**
   - From the repo root, run the `build-share-android.sh` script, passing the release notes via `--notes`:
   ```bash
   ./build-share-android.sh --notes "<Your generated release notes>"
   ```
   - The script will automatically:
     - Increment `build_number` in `version.json` and `version` in `pubspec.yaml`
     - Build the release APK (`flutter build apk`)
     - Upload the APK to Firebase App Distribution (group: `devs`, App ID: `1:861507979595:android:c797fa6f23b57da655c0ce`)
   - Note the Firebase App Distribution download link and console link from the script output once the upload is complete.
