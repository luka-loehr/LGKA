import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/preferences_manager.dart';
import '../navigation/app_router.dart';
import '../providers/app_providers.dart';
import '../providers/haptic_service.dart';
import '../theme/app_theme.dart';

class AiUpgradeScreen extends ConsumerStatefulWidget {
  const AiUpgradeScreen({super.key});

  @override
  ConsumerState<AiUpgradeScreen> createState() => _AiUpgradeScreenState();
}

class _AiUpgradeScreenState extends ConsumerState<AiUpgradeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Mark the prompt as shown
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final preferencesManager = ref.read(preferencesManagerProvider);
      await preferencesManager.setAiUpgradePromptShown(true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AppColors.appBlueAccent.withOpacity(0.15),
              AppColors.appBackground,
              AppColors.appBackground,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // Premium Header
                        _buildHeader(),
                        
                        const SizedBox(height: 60),
                        
                        // Benefits
                        Expanded(
                          child: _buildBenefits(),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Action Buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Floating AI Icon with multiple glass layers
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.appBlueAccent.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.appBlueAccent.withOpacity(0.3),
                        AppColors.appBlueAccent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 56,
                    color: AppColors.appBlueAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Premium Title with gradient and glow
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.appBlueAccent,
              AppColors.appBlueAccent.withOpacity(0.7),
              Colors.purple.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: Text(
            '🌟 KI-Upgrade verfügbar',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Elegant subtitle with glass effect
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Vertretungen perfekt für dich gefiltert\nund wunderschön dargestellt',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryText.withOpacity(0.9),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBenefit(
          '✨ Intelligent gefiltert',
          'Nur deine Klasse, automatisch sortiert',
          [Colors.purple.withOpacity(0.15), Colors.blue.withOpacity(0.1)],
        ),
        _buildBenefit(
          '🎨 Wunderschön gestaltet', 
          'Moderne Karten statt Textwüste',
          [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.1)],
        ),
        _buildBenefit(
          '⚡ Blitzschnell aktuell',
          'Automatische Updates alle 5 Minuten',
          [Colors.orange.withOpacity(0.15), Colors.pink.withOpacity(0.1)],
        ),
      ],
    );
  }

  Widget _buildBenefit(String title, String subtitle, List<Color> gradientColors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Premium upgrade button with glow
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.appBlueAccent.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.appBlueAccent,
                      AppColors.appBlueAccent.withOpacity(0.8),
                      Colors.purple.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await HapticService.medium();
                    
                    final preferencesManager = ref.read(preferencesManagerProvider);
                    await preferencesManager.setUseAiVersion(true);
                    ref.read(useAiVersionProvider.notifier).state = true;
                    
                    if (!mounted) return;
                    
                    if (preferencesManager.userClass == null) {
                      context.pushReplacement(AppRouter.classSelector);
                    } else {
                      context.pushReplacement(AppRouter.home);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🚀',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Jetzt ausprobieren!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Subtle later button
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  HapticService.subtle();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.pushReplacement(AppRouter.home);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Vielleicht später',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryText.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 