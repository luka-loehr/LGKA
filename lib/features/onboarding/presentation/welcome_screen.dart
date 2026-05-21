// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../navigation/app_router.dart';
import '../../../../widgets/scale_button.dart';
import '../../../../l10n/app_localizations.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isNavigating = false;

  void _navigateToNext() {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });
    
    context.go(AppRouter.whatYouCanDo);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final horizontalPadding = screenSize.width * 0.08; // 8% of screen width
    final logoSize = isSmallScreen ? 120.0 : 160.0;
    
    return Scaffold(
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
                        'assets/images/app-icons/app-icon-transparent.png',
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
                        color: context.appSecondaryText,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 32 : 40),
                    
                    // Button with responsive sizing
                    ScaleButton(
                      onTap: _isNavigating ? null : _navigateToNext,
                      isLoading: _isNavigating,
                      height: isSmallScreen ? 44 : 50,
                      child: Text(
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
} 