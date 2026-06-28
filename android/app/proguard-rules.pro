# Flutter ProGuard rules for PickleTrack release builds.
# These rules keep classes that are accessed via reflection or
# generated code and would otherwise be stripped by R8/ProGuard.

# Keep JSON serialization (used by drift model JSON fields)
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Dart FFI classes used by drift/sqlite3
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep AndroidX lifecycle classes (used by Riverpod + go_router)
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.** { *; }

# Keep share_plus, path_provider, and other plugins
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep audioplayers native bridge
-keep class xyz.luan.audioplayers.** { *; }

# Keep wakelock_plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Keep Google Play Core and billing if added later
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.** { *; }

# Suppress R8 warnings for Play Core classes referenced by plugins
# but not used by the app (e.g. dynamic delivery / split install).
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
