import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Container(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/images/welcome/welcome-logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Willkommen!',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Bei der neuen Vertretungsplan App des Lessing-Gymnasiums Karlsruhe.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Premium haptic feedback
                      await HapticService.light();
                      
                      // Update preferences
                      final prefsManager = ref.read(preferencesManagerProvider);
                      await prefsManager.setFirstLaunch(false);
                      ref.read(isFirstLaunchProvider.notifier).state = false;
                      
                      // Navigate to auth screen
                      if (context.mounted) {
                        context.go(AppRouter.auth);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.appBlueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Weiter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 