import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../providers/app_providers.dart';

class AppChoiceScreen extends ConsumerWidget {
  const AppChoiceScreen({super.key});

  void _selectSimpleVersion(BuildContext context, WidgetRef ref) async {
    await HapticService.subtle();
    
    // Speichere die Wahl
    final preferencesManager = ref.read(preferencesManagerProvider);
    await preferencesManager.setUseAiVersion(false);
    
    // Aktualisiere auch den State Provider
    ref.read(useAiVersionProvider.notifier).state = false;
    
    // Direkt zur Auth
    context.go(AppRouter.auth);
  }

  void _selectAiVersion(BuildContext context, WidgetRef ref) async {
    await HapticService.subtle();
    
    // Speichere die Wahl
    final preferencesManager = ref.read(preferencesManagerProvider);
    await preferencesManager.setUseAiVersion(true);
    
    // Aktualisiere auch den State Provider
    ref.read(useAiVersionProvider.notifier).state = true;
    
    // Zur Klassenauswahl
    context.go(AppRouter.classSelector);
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
              const SizedBox(height: 40),
              
              // Titel
              Text(
                'Wähle deine Version',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Du kannst zwischen zwei Versionen der App wählen:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Einfache Version
              _VersionCard(
                title: 'Einfache Version',
                subtitle: 'Wie bisher - zeigt PDF-Vertretungspläne an',
                features: [
                  'PDF-Ansicht für heute und morgen',
                  'Bewährte, zuverlässige Darstellung',
                  'Keine Anmeldung erforderlich',
                ],
                color: AppColors.appSurface,
                onTap: () => _selectSimpleVersion(context, ref),
              ),
              
              const SizedBox(height: 20),
              
              // KI Version
              _VersionCard(
                title: 'KI-Version',
                subtitle: 'Neue intelligente Vertretungsanzeige',
                features: [
                  'Automatisch gefiltert für deine Klasse',
                  'Übersichtliche Darstellung',
                  'Immer aktuell dank KI-Analyse',
                ],
                color: AppColors.appBlueAccent.withOpacity(0.1),
                borderColor: AppColors.appBlueAccent.withOpacity(0.3),
                isRecommended: true,
                onTap: () => _selectAiVersion(context, ref),
              ),
              
              const Spacer(),
              
              // Info
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
                        'Du kannst jederzeit in den Einstellungen zwischen den Versionen wechseln.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> features;
  final Color color;
  final Color? borderColor;
  final bool isRecommended;
  final VoidCallback onTap;

  const _VersionCard({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.color,
    this.borderColor,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRecommended) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.appBlueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEU',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Features
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: isRecommended 
                            ? AppColors.appBlueAccent 
                            : AppColors.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 12),
                
                // Button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Auswählen',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isRecommended 
                              ? AppColors.appBlueAccent 
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: isRecommended 
                          ? AppColors.appBlueAccent 
                          : AppColors.secondaryText,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 