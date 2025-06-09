import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';

class AiUpgradeScreen extends ConsumerStatefulWidget {
  const AiUpgradeScreen({super.key});

  @override
  ConsumerState<AiUpgradeScreen> createState() => _AiUpgradeScreenState();
}

class _AiUpgradeScreenState extends ConsumerState<AiUpgradeScreen> {
  @override
  void initState() {
    super.initState();
    // Mark the AI upgrade prompt as shown when this screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preferencesManager = ref.read(preferencesManagerProvider);
      preferencesManager.setAiUpgradePromptShown(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header with Brain Icon and Title
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.appBlueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 60,
                      color: AppColors.appBlueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '🤖 Neue KI-Version verfügbar!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deine Vertretungen automatisch\nnur für deine Klasse gefiltert',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Simple visual benefits
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Quick benefit icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SimpleBenefit(
                          icon: Icons.filter_alt_outlined,
                          text: 'Nur deine\nKlasse',
                        ),
                        _SimpleBenefit(
                          icon: Icons.schedule_outlined,
                          text: 'Übersichtlich\nstrukturiert',
                        ),
                        _SimpleBenefit(
                          icon: Icons.refresh_outlined,
                          text: 'Immer\naktuell',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Simple comparison
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.appSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.appBlueAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Du kannst jederzeit zur normalen Version zurück',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Column(
                children: [
                  // Primary Button - Switch to AI
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await HapticService.medium();
                        
                        // Switch to AI version
                        final preferencesManager = ref.read(preferencesManagerProvider);
                        await preferencesManager.setUseAiVersion(true);
                        ref.read(useAiVersionProvider.notifier).state = true;
                        
                        // Navigate to class selector if no class is set
                        if (preferencesManager.userClass == null) {
                          context.pushReplacement(AppRouter.classSelector);
                        } else {
                          context.pushReplacement(AppRouter.home);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appBlueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🚀',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ausprobieren!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary Button - Maybe Later
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticService.subtle();
                        // Check if we can pop (showing from within app) or need to replace (initial route)
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // If this is the initial route, navigate to home
                          context.pushReplacement(AppRouter.home);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Später',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SimpleBenefit({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.appBlueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppColors.appBlueAccent,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 