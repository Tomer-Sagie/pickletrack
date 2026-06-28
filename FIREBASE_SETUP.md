# Firebase Setup Guide — PickleTrack

This document explains how to connect the app to your Firebase project so
that `firebase_core` initializes successfully on Android and iOS.

> **Note:** The app already contains the Firebase initialization boilerplate.
> It will start even when the config files below are missing (development
> builds simply log a debug message). This guide tells you how to supply
> those files.

---

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and follow the wizard.
3. Give your project a name (e.g. `pickletrack-prod`).

---

## 2. Register the Android App

1. In the Firebase project overview, click the **Android** icon
   (or **Add app** → **Android**).
2. Enter the Android package name exactly as it appears in
   `android/app/build.gradle.kts`:

   ```kotlin
   applicationId = "com.example.pickletrack"
   ```

3. Enter an app nickname (optional) and click **Register app**.
4. Download `google-services.json`.
5. Move the file to:

   ```
   android/app/google-services.json
   ```

---

## 3. Register the iOS App

1. In the Firebase project overview, click the **iOS** icon
   (or **Add app** → **iOS**).
2. Enter the iOS bundle ID exactly as it appears in Xcode or in
   `ios/Runner.xcodeproj/project.pbxproj` (search for `PRODUCT_BUNDLE_IDENTIFIER`).
   The default in this project is:

   ```
   com.example.pickletrack
   ```

3. Enter an app nickname (optional) and click **Register app**.
4. Download `GoogleService-Info.plist`.
5. Move the file to:

   ```
   ios/Runner/GoogleService-Info.plist
   ```

6. In Xcode, make sure the file is included in the **Runner** target
   (select the file → right panel → Target Membership → check **Runner**).

---

## 4. Re-build

After placing the config files, clean and rebuild:

```bash
# Android
flutter clean
flutter build apk

# iOS (macOS + Xcode required)
flutter clean
cd ios && pod install && cd ..
flutter build ios
```

Firebase will now initialize automatically on app launch.

---

## 5. (Optional) Generate `firebase_options.dart` with FlutterFire CLI

If you prefer Dart-native configuration instead of the JSON/Plist files,
install the FlutterFire CLI and run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates `lib/firebase_options.dart`. You would then change
`main.dart` to use:

```dart
import 'firebase_options.dart';
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

The current setup uses the auto-discovery from the platform config files,
so this step is optional.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `FirebaseApp.initializeApp` throws on Android | Verify `google-services.json` is in `android/app/` and the package name matches exactly. |
| `FirebaseApp.initializeApp` throws on iOS | Verify `GoogleService-Info.plist` is in `ios/Runner/` and is a member of the **Runner** target. |
| Gradle build fails with "Plugin with id 'com.google.gms.google-services' not found" | Run `flutter clean` and rebuild; the plugin is declared in `android/settings.gradle.kts`. |
| `pod install` fails on iOS | Run `cd ios && pod repo update && pod install` |
