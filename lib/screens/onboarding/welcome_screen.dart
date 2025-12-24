// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

import '../../navigation/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/haptic_service.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAuth() async {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    // Haptic feedback
    HapticService.medium();

    // Button press animation
    await _buttonController.forward();
    
    
    // Do not mark first launch here; onboarding completes on AccentColorScreen
    
    // Release button animation
    _buttonController.reverse();
    
    // Small delay for the animation to feel natural
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Navigate to what you can do screen
    if (mounted) {
      context.go(AppRouter.whatYouCanDo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final horizontalPadding = screenSize.width * 0.08; // 8% of screen width
    final logoSize = isSmallScreen ? 120.0 : 160.0;
    
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding.clamp(16.0, 48.0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmallScreen ? 40 : 80),
                    
                    // Logo - responsive sizing
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/welcome/welcome-logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Headline with overflow protection
                    Text(
                      AppLocalizations.of(context)!.welcomeHeadline,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isSmallScreen ? 28 : 32,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Subtitle with overflow protection
                    Text(
                      AppLocalizations.of(context)!.welcomeSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 32 : 40),
                    
                    // Button with responsive sizing
                    AnimatedBuilder(
                      animation: _buttonScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScale.value,
                          child: SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 44 : 50,
                            child: ElevatedButton(
                              onPressed: _isNavigating ? null : _navigateToAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appBlueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: _isNavigating ? 0 : 2,
                              ),
                              child: _isNavigating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.continueLabel,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 15 : 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    
                    // Privacy consent footer
                    _buildPrivacyConsent(context, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 40 : 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPrivacyConsent(BuildContext context, bool isSmallScreen) {
    final l10n = AppLocalizations.of(context)!;
    final privacyPolicyUrl = 'https://luka-loehr.github.io/LGKA/privacy.html';
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.secondaryText,
            fontSize: isSmallScreen ? 11 : 12,
          ),
          children: [
            TextSpan(
              text: l10n.privacyConsentPrefix,
            ),
            TextSpan(
              text: l10n.privacyPolicy,
              style: TextStyle(
                color: AppColors.appBlueAccent,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  try {
                    final uri = Uri.parse(privacyPolicyUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Could not launch privacy policy URL: $e');
                  }
                },
            ),
            TextSpan(
              text: l10n.privacyConsentSuffix,
            ),
          ],
        ),
      ),
    );
  }
} 