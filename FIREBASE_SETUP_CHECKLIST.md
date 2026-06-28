# PickleTrack Firebase Setup Checklist

Use this checklist while creating your Firebase project. All values are pre-filled from your codebase.

---

## Step 1: Create Firebase Project

- [x] Go to [https://console.firebase.google.com](https://console.firebase.google.com)
- [x] Click **"Add project"**
- [x] Project name: **`pickletrack`** (or your preferred name)
- [x] Accept terms and click **Create project**
- [x] Wait for provisioning, then click **Continue**

---

## Step 2: Register Android App

- [x] In Firebase Console → Project Overview, click the **Android icon** (or **Add app**)
- [x] Android package name: **`com.example.pickletrack`**
  - *This must match `applicationId` in `android/app/build.gradle.kts`*
- [x] App nickname: **`PickleTrack Android`**
- [x] Click **Register app**
- [x] Download **`google-services.json`**
- [x] Replace the placeholder file at: **`android/app/google-services.json`**
- [x] Run `flutter clean` so Gradle picks up the new config

---

## Step 3: Register iOS App

- [x] In Firebase Console → Project Overview, click **Add app** → **iOS**
- [x] Bundle ID: **`com.example.pickletrack`**
  - *This must match `PRODUCT_BUNDLE_IDENTIFIER` in your Xcode project*
- [x] App nickname: **`PickleTrack iOS`**
- [x] Click **Register app**
- [x] Download **`GoogleService-Info.plist`**
- [x] Place it at: **`ios/Runner/GoogleService-Info.plist`**
- [x] Open `ios/Runner.xcworkspace` in Xcode and verify the plist is included in the target

> ✅ iOS app registered in Firebase. App ID: `1:420306123685:ios:ab4c7ffcf129741ceb064c`

---

## Step 4: iOS Distribution (Deferred)

iOS builds require **macOS + Xcode** and **Apple Developer Program** ($99/year). Neither is available on your current Windows setup.

- [x] iOS app registered in Firebase (App ID: `1:420306123685:ios:ab4c7ffcf129741ceb064c`)
- [x] `GoogleService-Info.plist` in place
- [ ] Deferred until macOS + Apple Developer are available

---

## Step 4: Enable Crashlytics

- [ ] In Firebase Console → **Build** → **Crashlytics**
- [ ] Click **Set up Crashlytics**
- [ ] Select **"This is a new Firebase app"** and click **Next**
- [ ] Build and run your app — Crashlytics will auto-detect the first crash report

---

## Step 5: Enable GitHub Pages for Web App

The web app is deployed to GitHub Pages via GitHub Actions — no branch, no billing.

- [ ] Go to your repo → **Settings** → **Pages**
- [ ] Source: **GitHub Actions**
- [ ] **Save**

> The web app will be live at **https://tomer-sagie.github.io/pickletrack** after the first CI push.

---

## Step 6: Set Up App Distribution

### Create a tester group
- [ ] In Firebase Console → **Release & Monitor** → **App Distribution**
- [ ] Click **Testers & Groups** → **Create group**
- [ ] Group name: **`qa-team`**
- [ ] Add tester email addresses

### Get your Firebase App ID (for CI)
- [ ] In Firebase Console → Project Settings (gear icon)
- [ ] Scroll to **Your apps**
- [ ] Click your **Android** app
- [ ] Copy the **App ID** (looks like `1:1234567890:android:321abc456def7890`)
- [ ] Save this as `FIREBASE_APP_ID` in GitHub Secrets

### Create a service account for CI
- [x] In Firebase Console → Project Settings → **Service accounts**
- [x] Click **Generate new private key**
- [x] Save the JSON file contents as `FIREBASE_SERVICE_ACCOUNT_JSON` in GitHub Secrets
- [x] Grant this service account the **Firebase App Distribution Admin** role

---

## Step 7: Verify Everything Works

```bash
flutter clean
flutter pub get
flutter build apk --release
```

- [x] Build succeeds with no Firebase errors
- [x] APK size should be ~25 MB

To test Crashlytics, temporarily throw an error in a button handler and check the Firebase Console for the report within a few minutes.

---

## Next Steps (All Done!)

1. ~~Uncomment the `push` trigger in `.github/workflows/firebase-distribution.yml`~~ ✅
2. ~~Push to `main` — your APK will auto-build and distribute to the `qa-team` group~~ ✅

**You're all set!** The next push to `main` will automatically build and distribute to your `qa-team` testers.
