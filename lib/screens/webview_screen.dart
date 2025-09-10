import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../theme/app_theme.dart';
import '../providers/haptic_service.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String? title;
  final Map<String, String>? headers;

  const InAppWebViewScreen({super.key, required this.url, this.title, this.headers});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _hasTriggeredLoadedHaptic = false;

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
            HapticService.subtle();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          widget.title ?? 'Browser',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryText),
        ),
        centerTitle: true,
        actions: [
          if (_progress < 1.0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _progress,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(
            url: WebUri(widget.url),
            headers: {
              'User-Agent': 'LGKA-App-Luka-Loehr',
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
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onProgressChanged: (controller, progress) {
            setState(() => _progress = progress / 100);
            
            // Trigger haptic feedback when page is fully loaded
            if (progress == 100 && !_hasTriggeredLoadedHaptic) {
              _hasTriggeredLoadedHaptic = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    HapticService.pdfLoading();
                  }
                });
              });
            }
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
      ),
    );
  }
}


