

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/haptic_service.dart';
import '../../../../utils/app_info.dart';
import '../../../../utils/app_logger.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String? title;
  final Map<String, String>? headers;
  final bool fromKrankmeldungInfo;

  const InAppWebViewScreen({super.key, required this.url, this.title, this.headers, this.fromKrankmeldungInfo = false});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {

  InAppWebViewController? _controller;
  double _progress = 0;
  bool _hasError = false;

  
  // Check if this is the absence reporting (krankmeldung) webview
  bool get _isKrankmeldungWebView => widget.url.contains('krankmeldung');

  Future<void> _retryLoad() async {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    if (_controller != null) {
      try {
        await _controller!.reload();
      } catch (e) {
        // Fallback: load initial URL again
        AppLogger.debug('Error reloading URL: $e', module: 'WebView');
        try {
          await _controller!.loadUrl(
            urlRequest: URLRequest(
              url: WebUri(widget.url),
              headers: {
                'User-Agent': AppInfo.userAgent,
                ...?widget.headers,
              },
            ),
          );
        } catch (e2) {
          AppLogger.error('Failed to load URL after retry', module: 'WebView', error: e2);
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
            if (widget.fromKrankmeldungInfo) {
              // If we came from Krankmeldung info screen, go back to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              // Normal back navigation
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          widget.title ?? AppLocalizations.of(context)!.browserTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryText),
        ),
        centerTitle: true,
        actions: [],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(

          initialUrlRequest: URLRequest(
            url: WebUri(widget.url),
            headers: {
              'User-Agent': AppInfo.userAgent,
              ...?widget.headers,
            },
          ),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            mediaPlaybackRequiresUserGesture: true,
            allowsInlineMediaPlayback: true,
            useHybridComposition: true,
            verticalScrollBarEnabled: true,
            horizontalScrollBarEnabled: false,
            // Enable cookies and cache for absence reporting to keep user logged in
            // For privacy pages (legal/privacy), cookies are disabled by default
            cacheEnabled: _isKrankmeldungWebView,
            thirdPartyCookiesEnabled: _isKrankmeldungWebView,
            incognito: !_isKrankmeldungWebView, // Only use incognito for non-krankmeldung pages
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url;

            
            // Only open external browser if leaving the apps.lgka-online.de domain
            if (url != null) {
              // Check if the URL is leaving the apps.lgka-online.de domain
              if (url.host != 'apps.lgka-online.de') {
                // Open in external browser
                final uri = Uri.parse(url.toString());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                return NavigationActionPolicy.CANCEL;
              }
            }
            
            // Allow navigation within apps.lgka-online.de domain
            return NavigationActionPolicy.ALLOW;
          },
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              _progress = progress / 100;
            });
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
          onReceivedHttpAuthRequest: (controller, challenge) async {
            // Provide basic auth when challenged
            final String username = 'vertretungsplan';
            final String password = 'ephraim';
            return HttpAuthResponse(
              username: username,
              password: password,
              action: HttpAuthResponseAction.PROCEED,
              permanentPersistence: true,
            );
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
                        AppLocalizations.of(context)!.loadingSickNote,
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
                        Icons.medical_services_outlined,
                        size: 64,
                        color: AppColors.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.serverConnectionFailed,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.serverConnectionHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Intentionally hide raw error details in all builds (debug/release)
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


