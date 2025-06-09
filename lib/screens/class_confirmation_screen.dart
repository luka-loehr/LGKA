import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../providers/app_providers.dart';

class ClassConfirmationScreen extends ConsumerWidget {
  final String className;

  const ClassConfirmationScreen({super.key, required this.className});

  void _confirm(BuildContext context, WidgetRef ref) async {
    await HapticService.subtle();
    
    // Speichere die Klasse in den Einstellungen
    final preferencesManager = ref.read(preferencesManagerProvider);
    await preferencesManager.setUserClass(className);
    
    // Aktualisiere auch den State Provider
    ref.read(userClassProvider.notifier).state = className;
    
    // Kurzer Delay um sicherzustellen dass die Preferences gespeichert sind
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Prüfe ob User schon authentifiziert ist
    if (preferencesManager.isAuthenticated) {
      // Direkt zur Home (KI-Version wird automatisch gezeigt)
      context.go(AppRouter.home);
    } else {
      // Zur Authentifizierung
      context.go(AppRouter.auth);
    }
  }

  void _goBack(BuildContext context) async {
    await HapticService.subtle();
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Titel
              Text(
                'Bestätigung',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Ist das deine richtige Klasse?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Klasse anzeigen
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.appBlueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.appBlueAccent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    className.toUpperCase(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.appBlueAccent,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.appSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.appBlueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Du kannst deine Klasse jederzeit in den Einstellungen ändern.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Buttons
              Column(
                children: [
                  // Bestätigen Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirm(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appBlueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ja, das ist richtig',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Zurück Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _goBack(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Nein, bearbeiten',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 