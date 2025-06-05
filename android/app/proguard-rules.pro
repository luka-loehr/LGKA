# Add project specific ProGuard rules here.
# Standard ProGuard configuration for Flutter apps with size optimization

# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.** { *; }

# Keep native method names for crash reporting
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,LineNumberTable

# Keep plugin classes - only what's actually used
-keep class com.baseflow.permissionhandler.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class com.syncfusion.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Standard optimizations
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

# Prevent obfuscation of native code interfaces
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep crash reporting information
-keep public class * extends java.lang.Exception

# Keep all classes referenced by Flutter engine
-keepclassmembers class * {
    @io.flutter.embedding.engine.dart.DartEntrypoint *;
}

# Remove unused classes aggressively
-dontwarn java.lang.instrument.**
-dontwarn sun.misc.**
-dontwarn java.lang.management.**

# Additional safety for deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; } 