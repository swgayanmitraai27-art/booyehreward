# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Google Play Core Rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google AdMob Rules
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.gms.**

# Unity Ads Mediation Rules
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-keep interface com.unity3d.ads.** { *; }
-keep interface com.unity3d.services.** { *; }
-keep class com.google.ads.mediation.unity.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**
-dontwarn com.google.ads.mediation.unity.**
-dontwarn com.unity3d.**

# Firebase Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
