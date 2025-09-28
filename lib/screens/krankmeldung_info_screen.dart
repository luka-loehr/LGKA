// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';

class KrankmeldungInfoScreen extends ConsumerWidget {
  const KrankmeldungInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticService.subtle();
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.secondaryText,
          ),
        ),
        title: Text(
          'Krankmeldung',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.appOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main disclaimer card
                      _buildInfoCard(
                        context,
                        Icons.warning_amber_rounded,
                        'Wichtiger Hinweis',
                        'Die Krankmeldung wird vom Lessing-Gymnasium entwickelt und hat nichts mit der LGKA+ App zu tun.',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Problem contact card
                      _buildInfoCard(
                        context,
                        Icons.support_agent,
                        'Bei Problemen',
                        'Wende dich direkt an das Lessing-Gymnasium Karlsruhe.',
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.subtle();
                    _openKrankmeldung(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Zur Krankmeldung',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _openKrankmeldung(BuildContext context) {
    // Navigate to the webview with the illness report
    context.push(AppRouter.webview, extra: {
      'url': 'https://apps.lgka-online.de/apps/krankmeldung/',
      'title': 'Krankmeldung',
      'headers': {
        'User-Agent': 'LGKA-App-Luka-Loehr',
      },
      'fromKrankmeldungInfo': true, // Flag to indicate we came from info screen
    });
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, String description) {
    return Card(
      color: AppColors.appSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                      fontSize: 14,
                    ),
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
