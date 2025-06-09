// Copyright Luka Löhr 2025

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

class _AiUpgradeScreenState extends ConsumerState<AiUpgradeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Simple fade-in animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation immediately
    _animationController.forward();
    
    // Mark the prompt as shown
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final preferencesManager = ref.read(preferencesManagerProvider);
      await preferencesManager.setAiUpgradePromptShown(true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.appBackground,
              AppColors.appBackground.withOpacity(0.8),
              AppColors.appBlueAccent.withOpacity(0.05),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Hero section
                            _buildHeroSection(context),

                            const SizedBox(height: 24),

                            // Features section
                            _buildFeaturesSection(),

                            const Spacer(),

                            // Action buttons
                            _buildActionButtons(context),
                            
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
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

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.appSurface,
            AppColors.appSurface.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.appBlueAccent.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated AI icon with glow effect
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.appBlueAccent,
                  AppColors.appBlueAccent.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.appBlueAccent.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title with better typography
          Text(
            'KI-Version verfügbar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle with improved styling
          Text(
            'Intelligente Aufbereitung der Vertretungspläne\nspeziell für deine Klasse',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _buildFeature(
          icon: Icons.auto_awesome_rounded,
          title: 'Intelligente Filterung',
          description: 'Nur Vertretungen für deine Klasse werden angezeigt',
        ),
        const SizedBox(height: 16),
        _buildFeature(
          icon: Icons.dashboard_customize_rounded,
          title: 'Übersichtliche Darstellung',
          description: 'Strukturierte Karten statt unübersichtlicher PDF-Listen',
        ),
        const SizedBox(height: 16),
        _buildFeature(
          icon: Icons.refresh_rounded,
          title: 'Automatische Updates',
          description: 'Alle 5 Minuten wird nach neuen Vertretungen gesucht',
        ),
      ],
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.appBlueAccent.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.appBlueAccent.withOpacity(0.2),
                  AppColors.appBlueAccent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.appBlueAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary button with gradient
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.appBlueAccent,
                AppColors.appBlueAccent.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.appBlueAccent.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'KI-Version aktivieren',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              HapticService.subtle();
              if (context.canPop()) {
                context.pop();
              } else {
                context.pushReplacement(AppRouter.home);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
              side: BorderSide(
                color: AppColors.iconTint.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Vielleicht später',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
