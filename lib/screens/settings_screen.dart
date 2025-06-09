import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:lgka_flutter/providers/haptic_service.dart';
import 'package:lgka_flutter/navigation/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final preferencesManager = ref.watch(preferencesManagerProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'Einstellungen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // App-Version Upgrade (nur anzeigen wenn einfache Version aktiv)
            if (!preferencesManager.useAiVersion) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () async {
                    await HapticService.subtle();
                    await preferencesManager.setUseAiVersion(true);
                    
                    // Aktualisiere auch den State Provider
                    ref.read(useAiVersionProvider.notifier).state = true;
                    
                    // Zur Klassenauswahl navigieren
                    context.push(AppRouter.classSelector);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Zur KI-Version wechseln',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.appOnSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.appBlueAccent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NEU',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Intelligente Vertretungsanzeige für deine Klasse',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.upgrade,
                        color: AppColors.appBlueAccent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Klassen-Einstellung (nur anzeigen wenn KI-Version aktiv)
            if (preferencesManager.useAiVersion) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () async {
                    await HapticService.subtle();
                    context.push(AppRouter.classSelector);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deine Klasse',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.appOnSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preferencesManager.userClass?.toUpperCase() ?? 'Nicht festgelegt',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: preferencesManager.userClass != null 
                                        ? AppColors.appBlueAccent 
                                        : AppColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.secondaryText,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Zur einfachen Version wechseln
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () async {
                    await HapticService.subtle();
                    await preferencesManager.setUseAiVersion(false);
                    
                    // Aktualisiere auch den State Provider
                    ref.read(useAiVersionProvider.notifier).state = false;
                    
                    setState(() {}); // Rebuild um die Änderung sofort zu zeigen
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Zur einfachen Version wechseln',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.appOnSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF-Ansicht verwenden',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.swap_horiz,
                        color: AppColors.secondaryText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Datum-Einstellung (immer anzeigen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Datum anzeigen',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.appOnSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zeigt das Datum nach dem Wochentag an',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: preferencesManager.showDatesWithWeekdays,
                    onChanged: (value) async {
                      await preferencesManager.setShowDatesWithWeekdays(value);
                      HapticService.subtle();
                      setState(() {});
                    },
                    activeColor: AppColors.appBlueAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 