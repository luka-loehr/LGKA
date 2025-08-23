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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccentColorSetting(context, preferencesManager),
              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildVibrationSetting(context, preferencesManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorSetting(BuildContext context, PreferencesManager preferencesManager) {
    final currentTheme = Theme.of(context);
    final presetColors = [
      {'name': 'Blau', 'value': 'blue', 'color': AppColors.appBlueAccent},
      {'name': 'Grün', 'value': 'green', 'color': Colors.green},
      {'name': 'Lila', 'value': 'purple', 'color': Colors.purple},
      {'name': 'Orange', 'value': 'orange', 'color': Colors.orange},
      {'name': 'Rosa', 'value': 'pink', 'color': Colors.pink},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akzentfarbe',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wähle deine bevorzugte Akzentfarbe',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: presetColors.map((colorData) {
            final isSelected = preferencesManager.accentColor == colorData['value'];
            return GestureDetector(
              onTap: () {
                preferencesManager.setAccentColor(colorData['value'] as String);
                HapticService.subtle();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorData['color'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? currentTheme.colorScheme.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: currentTheme.colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVibrationSetting(BuildContext context, PreferencesManager preferencesManager) {
    final currentTheme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vibration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Haptisches Feedback aktivieren',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: preferencesManager.vibrationEnabled,
          onChanged: (value) async {
            await preferencesManager.setVibrationEnabled(value);
            HapticService.subtle();
          },
          activeColor: currentTheme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.secondaryText.withValues(alpha: 0.2),
    );
  }
} 