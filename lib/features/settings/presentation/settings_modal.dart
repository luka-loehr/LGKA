// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/color_provider.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';

/// Settings bottom sheet
class SettingsModal extends ConsumerWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16, 
            16, 
            16, 
            _getBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildAccentColorSetting(context, ref),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildLegalLinks(context),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildLastDownloadedNotice(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccentColorSetting(BuildContext context, WidgetRef ref) {
    final choosableColors = ref.watch(choosableColorsProvider);
    final currentColorName = ref.watch(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.accentColor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.chooseAccentColor,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: choosableColors.map((colorPalette) {
            final isSelected = currentColorName == colorPalette.name;
            return GestureDetector(
              onTap: () {
                HapticService.light();
                ref.read(colorProvider.notifier).setColor(colorPalette.name);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeInOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorPalette.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorPalette.color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 60),
                  curve: Curves.easeInOut,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Column(
      children: [
        _buildBugReportLink(context),
        const SizedBox(height: 12),
        _buildSupportLink(context),
        const SizedBox(height: 12),
        _buildLegalLink(
          context,
          Icons.privacy_tip_outlined, 
          AppLocalizations.of(context)!.privacyLabel, 
          'https://luka-loehr.github.io/LGKA/privacy.html'
        ),
        const SizedBox(height: 12),
        _buildLegalLink(
          context,
          Icons.info_outline, 
          AppLocalizations.of(context)!.legalLabel, 
          'https://luka-loehr.github.io/LGKA/impressum.html'
        ),
      ],
    );
  }

  Widget _buildBugReportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push(AppRouter.bugReport);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.bug_report_outlined,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.bugReport,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.intense();
        _launchURL('https://buymeacoffee.com/lukaloehr');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.favorite_outline,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.supportProject,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(BuildContext context, IconData icon, String text, String url) {
    return InkWell(
      onTap: () {
        HapticService.light();
        _launchURL(url);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastDownloadedNotice(BuildContext context, WidgetRef ref) {
    final substitutionState = ref.watch(substitutionProvider);
    
    // Get the most recent download timestamp from both today and tomorrow
    final todayTimestamp = substitutionState.todayState.downloadTimestamp;
    final tomorrowTimestamp = substitutionState.tomorrowState.downloadTimestamp;
    
    DateTime? mostRecentTimestamp;
    if (todayTimestamp != null && tomorrowTimestamp != null) {
      mostRecentTimestamp = todayTimestamp.isAfter(tomorrowTimestamp) 
          ? todayTimestamp 
          : tomorrowTimestamp;
    } else if (todayTimestamp != null) {
      mostRecentTimestamp = todayTimestamp;
    } else if (tomorrowTimestamp != null) {
      mostRecentTimestamp = tomorrowTimestamp;
    }
    
    // Only show notice if we have a timestamp
    if (mostRecentTimestamp == null) {
      return const SizedBox.shrink();
    }
    
    // Format timestamp to show only time with seconds (HH:mm:ss)
    final dateFormat = DateFormat('HH:mm:ss', 'de_DE');
    final formattedTime = dateFormat.format(mostRecentTimestamp);
    
    return Text(
      AppLocalizations.of(context)!.lastDownloaded(formattedTime),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.secondaryText,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  double _getBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;

    if (gestureInsets >= 45) {
      return 54.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      return mediaQuery.viewPadding.bottom > 50 ? 54.0 : 8.0;
    }
  }
}
