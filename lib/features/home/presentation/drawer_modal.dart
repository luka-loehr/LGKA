// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/app_providers.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../utils/app_info.dart';
import '../../../../l10n/app_localizations.dart';

/// Drawer bottom sheet (Weiteres/More section)
class DrawerModal extends ConsumerWidget {
  const DrawerModal({super.key});

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
                AppLocalizations.of(context)!.more,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildKrankmeldungOption(context, ref),
                    const SizedBox(height: 4),
                    _buildDivider(),
                    const SizedBox(height: 4),
                    _buildNeuigkeitenOption(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKrankmeldungOption(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          Navigator.of(context).pop();
          
          final preferencesManager = ref.read(preferencesManagerProvider);
          
          // Check if krankmeldung info has been shown before
          if (preferencesManager.krankmeldungInfoShown) {
            // Navigate directly to webview
            context.push(AppRouter.webview, extra: {
              'url': 'https://apps.lgka-online.de/apps/krankmeldung/',
              'title': AppLocalizations.of(context)!.krankmeldung,
              'headers': {
                'User-Agent': AppInfo.userAgent,
              },
              'fromKrankmeldungInfo': false,
            });
          } else {
            // Navigate to the info screen first
            context.push(AppRouter.krankmeldungInfo);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.krankmeldung,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuigkeitenOption(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          Navigator.of(context).pop();
          context.push(AppRouter.news);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.newspaper_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.news,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
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
