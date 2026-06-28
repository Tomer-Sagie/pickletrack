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
   ```### 6. iOS Distribution (Deferred)

iOS builds require **macOS + Xcode** (not available on Windows) and an **Apple Developer Program** membership ($99/year) for code signing.

The iOS app is already registered in Firebase (`GoogleService-Info.plist` is in place) and ready to go whenever you get access to a Mac. At that point, you can:
- Build: `flutter build ipa --release`
- Distribute: `firebase appdistribution:distribute build/ios/ipa/*.ipa --app 1:420306123685:ios:ab4c7ffcf129741ceb064c --groups "qa-team"`

### 7. CI/CD with GitHub Actions

The CI pipeline at `.github/workflows/firebase-distribution.yml` has two parallel jobs that run on every push to `main`:
- **`android`** — builds APK, uploads to Firebase App Distribution (`qa-team` group)
- **`web`** — builds `flutter build web`, deploys to Firebase Hosting

**Secrets needed** (GitHub → Settings → Secrets and variables → Actions):
- `FIREBASE_SERVICE_ACCOUNT_JSON` — full service account JSON (already set)

**Service account permissions needed** (in Google Cloud Console → IAM):
- `Firebase App Distribution Admin`
- `Firebase Hosting Admin`

**APIs to enable** (in Google Cloud Console → APIs & Services):
- Firebase App Distribution API
- Firebase Hosting API### 8. Web Hosting (GitHub Pages)

The app is also deployed as a **web app** on GitHub Pages — completely free, no billing account needed. Testers open a URL from any device.

**Your web app URL:** `https://tomer-sagie.github.io/pickletrack`

**One-time setup**:
1. Go to your repo → **Settings** → **Pages**
2. Source: **GitHub Actions** → **Save**

After the first CI push, the site will be live at the URL above.

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
