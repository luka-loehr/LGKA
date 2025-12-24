// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/haptic_service.dart';
import '../../utils/app_info.dart';
import '../../utils/app_logger.dart';
import '../../config/app_credentials.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _hasError = false;

  @override
  void dispose() {
    // Clear all cookies and cache data when leaving the screen
    _clearWebViewData();
    super.dispose();
  }

  Future<void> _clearWebViewData() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      // Cache is already disabled via incognito mode and cacheEnabled: false
      AppLogger.debug('Cleared WebView cookies for privacy', module: 'BugReport');
    } catch (e) {
      AppLogger.error('Failed to clear WebView data', module: 'BugReport', error: e);
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    if (_controller != null) {
      try {
        await _controller!.reload();
      } catch (e) {
        AppLogger.debug('Error reloading URL: $e', module: 'BugReport');
        try {
          await _controller!.loadUrl(
            urlRequest: URLRequest(
              url: WebUri(AppCredentials.bugReportFormUrl),
              headers: {
                'User-Agent': AppInfo.userAgent,
              },
            ),
          );
        } catch (e2) {
          AppLogger.error('Failed to load URL after retry', module: 'BugReport', error: e2);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.secondaryText),
          onPressed: () {
            HapticService.light();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.bugReportTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryText),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(
                url: WebUri(AppCredentials.bugReportFormUrl),
                headers: {
                  'User-Agent': AppInfo.userAgent,
                },
              ),
              initialSettings: InAppWebViewSettings(
                transparentBackground: true,
                mediaPlaybackRequiresUserGesture: true,
                allowsInlineMediaPlayback: true,
                useHybridComposition: true,
                verticalScrollBarEnabled: true,
                horizontalScrollBarEnabled: false,
                // Privacy-focused settings
                thirdPartyCookiesEnabled: false,
                cacheEnabled: false,
                clearCache: true,
                incognito: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onLoadStop: (controller, url) async {
                // Cache is already disabled via incognito mode and cacheEnabled: false
                // No need to manually clear cache
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _hasError = true;
                });
              },
              onReceivedHttpError: (controller, request, error) {
                setState(() {
                  _hasError = true;
                });
              },
            ),
            if (_progress < 1.0 && !_hasError)
              Container(
                color: AppColors.appBackground,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.loading,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasError)
              Container(
                color: AppColors.appBackground,
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report_outlined,
                        size: 64,
                        color: AppColors.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.formLoadError,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.formLoadErrorHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          HapticService.light();
                          _retryLoad();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.tryAgain),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

