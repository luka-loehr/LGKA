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

class _AiUpgradeScreenState extends ConsumerState<AiUpgradeScreen> {
  @override
  void initState() {
    super.initState();
    // Mark the prompt as shown
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final preferencesManager = ref.read(preferencesManagerProvider);
      await preferencesManager.setAiUpgradePromptShown(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Hero section with icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.appBlueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        size: 40,
                        color: AppColors.appBlueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'KI-Version verfügbar',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Intelligente Aufbereitung der Vertretungspläne speziell für deine Klasse',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Features
              Expanded(
                child: Column(
                  children: [
                    _buildFeature(
                      icon: Icons.filter_list_outlined,
                      title: 'Intelligente Filterung',
                      description: 'Nur Vertretungen für deine Klasse werden angezeigt',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.view_list_outlined,
                      title: 'Übersichtliche Darstellung',
                      description: 'Strukturierte Karten statt unübersichtlicher PDF-Listen',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.update_outlined,
                      title: 'Automatische Updates',
                      description: 'Alle 5 Minuten wird nach neuen Vertretungen gesucht',
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
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
                        backgroundColor: AppColors.appBlueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'KI-Version aktivieren',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
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
                        side: const BorderSide(color: AppColors.iconTint),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Vielleicht später',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.appBlueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
