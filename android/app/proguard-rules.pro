# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Keep native method names for crash reporting
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep plugin classes
-keep class com.** { *; }

# Keep Google Play Core classes (required by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep path provider classes  
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep package info plus classes
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Keep Syncfusion PDF classes
-keep class com.syncfusion.** { *; }

# Keep file picker classes
-keep class com.file_picker.** { *; }

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep HTTP classes
-keep class io.flutter.plugins.connectivity.** { *; }

# Prevent obfuscation of native code interfaces
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep crash reporting information
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Flutter specific rules
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.app.** { *; }

# Prevent stripping of error handling code
-keep class * extends java.lang.Exception { *; }

# Keep all classes referenced by Flutter engine
-keepclassmembers class * {
    @io.flutter.embedding.engine.dart.DartEntrypoint *;
}

# Additional safety for deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; } 