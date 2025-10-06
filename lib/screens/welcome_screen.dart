// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../l10n/app_localizations.dart';

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

    // Button press animation
    await _buttonController.forward();
    
    // Premium haptic feedback
    await HapticService.light();
    
    // Do not mark first launch here; onboarding completes on InfoScreen
    
    // Release button animation
    _buttonController.reverse();
    
    // Small delay for the animation to feel natural
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Navigate to info screen
    if (mounted) {
      context.go(AppRouter.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo - direct image display
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Image.asset(
                    'assets/images/welcome/welcome-logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  AppLocalizations.of(context)!.welcomeHeadline,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  AppLocalizations.of(context)!.welcomeSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                AnimatedBuilder(
                  animation: _buttonScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScale.value,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.continue_,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 