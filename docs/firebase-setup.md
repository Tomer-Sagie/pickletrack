# Firebase Setup Guide for PickleTrack

This app uses **Firebase Core** for analytics/crash reporting foundation and **Firebase App Distribution** for sharing APKs with testers.

## What’s Already Configured

- `firebase_core` dependency in `pubspec.yaml`
- `Firebase.initializeApp()` in `lib/main.dart` (with graceful fallback)
- Android `google-services` and `appdistribution` Gradle plugins
- iOS Podfile will pick up Firebase automatically on first build

## What You Need to Do

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** and name it (e.g. `pickletrack`)
3. Enable Google Analytics if you want crash insights later

### 2. Register Android App

1. In Firebase Console → Project Overview → Add app → **Android**
2. Package name: `com.example.pickletrack` (matches `android/app/build.gradle.kts`)
3. Download **`google-services.json`**
4. Replace the placeholder at: `android/app/google-services.json`
5. Run `flutter clean` so Gradle picks up the new config file

### 3. Register iOS App

1. In Firebase Console → Project Overview → Add app → **iOS**
2. Bundle ID: `com.example.pickletrack` (matches `ios/Runner.xcodeproj`)
3. Download **`GoogleService-Info.plist`**
4. Place it at: `ios/Runner/GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode and verify the plist is included in the target

### 4. Verify Build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

If the build succeeds without Firebase errors, your config files are in the right place.

### 5. Firebase App Distribution (Optional)

To distribute APKs to testers via Firebase:

**Option A — Firebase CLI (recommended)**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Log in
firebase login

# Distribute a release APK
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <YOUR_FIREBASE_APP_ID> \
  --groups "qa-team" \
  --release-notes-file release-notes.txt
```

**Option B — Gradle Plugin**

The Firebase App Distribution Gradle plugin is already configured in `android/app/build.gradle.kts`. To use it:

1. Create a service account in Firebase Console → Project Settings → Service Accounts
2. Download the JSON key and set the environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   ```
3. Run:
   ```bash
   ./gradlew appDistributionUploadRelease
   ```

### 6. iOS Distribution

Firebase App Distribution for iOS uses the **Firebase CLI** (the Gradle plugin is Android-only):

```bash
# Build the iOS archive on macOS
flutter build ipa --release

# Distribute via Firebase CLI
firebase appdistribution:distribute build/ios/ipa/*.ipa \
  --app <YOUR_IOS_FIREBASE_APP_ID> \
  --groups "qa-team" \
  --release-notes-file release-notes.txt
```

> **Note:** If you cloned this repo on Windows, iOS platform files may not exist. Run `flutter create .` on macOS to generate them before building.

### 7. CI/CD with GitHub Actions (Optional)

A workflow template is provided at `.github/workflows/firebase-distribution.yml`. To enable it:

1. Add these secrets in **GitHub → Settings → Secrets and variables → Actions**:
   - `FIREBASE_APP_ID` — your Android Firebase app ID
   - `FIREBASE_SERVICE_ACCOUNT_JSON` — the full JSON content of a Firebase service account key (with **Firebase App Distribution Admin** role)
2. Uncomment the `push` trigger in the workflow file
3. Push to `main` — the APK will build and distribute automatically

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `google-services.json` not found | Double-check the file is at `android/app/google-services.json` and the package name matches exactly |
| `DefaultFirebaseApp is not initialized` | Make sure `Firebase.initializeApp()` succeeded; check logs for the exact error |
| iOS build fails with CocoaPods error | Run `cd ios && pod install --repo-update` |
| App Distribution upload fails | Verify `GOOGLE_APPLICATION_CREDENTIALS` points to a valid service account key with Firebase App Distribution Admin role |
| Added `google-services.json` but build still fails | Run `flutter clean` and rebuild — Gradle caches the plugin state |
| iOS files missing | Run `flutter create .` on macOS to regenerate platform files |
| Crashlytics not showing crashes | Make sure the app is built in release mode (`flutter run --release`); debug crashes are not sent by default |
| ProGuard strips Firebase classes | Add `-keep class com.google.firebase.** { *; }` to `android/app/proguard-rules.pro` |
