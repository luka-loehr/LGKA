# Keep rules to prevent R8 from stripping flutter_inappwebview classes used via reflection
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.**

# Generated missing rules suggestions (safe to include)
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.ISettings
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.InAppWebViewFlutterPlugin
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.chrome_custom_tabs.ChromeSafariBrowserManager
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.chrome_custom_tabs.NoHistoryCustomTabsActivityCallbacks
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.credential_database.CredentialDatabase
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.headless_in_app_webview.HeadlessInAppWebViewManager
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.in_app_browser.InAppBrowserManager
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.print_job.PrintJobController
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.print_job.PrintJobManager
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.print_job.PrintJobSettings
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.BaseCallbackResultImpl
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.ChannelDelegateImpl
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.Disposable
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.PreferredContentModeOptionType
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.URLCredential
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.URLProtectionSpace
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.WebResourceRequestExt
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.types.WebResourceResponseExt
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.webview.InAppWebViewManager
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.FlutterWebView
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.InAppWebView
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