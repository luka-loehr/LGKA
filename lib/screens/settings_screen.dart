import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:lgka_flutter/providers/haptic_service.dart';

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
        child: Container(
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
                      'Datum nach Wochentag anzeigen',
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
      ),
    );
  }
} 