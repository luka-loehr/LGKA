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
            // Warning icon and title
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wichtiger Hinweis',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
              
              const SizedBox(height: 20),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main disclaimer text
                      Card(
                        color: AppColors.appSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Die Krankmeldung wird vom Lessing-Gymnasium entwickelt und hat nichts mit der LGKA+ App zu tun.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Bei Problemen wende dich direkt an das Lessing-Gymnasium.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondaryText,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Privacy policy section
                      Text(
                        'Datenschutz',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Lies vor der Nutzung die Datenschutzerklärung:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Card(
                        color: AppColors.appSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticService.subtle();
                            _openPrivacyPolicy();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Datenschutzerklärung des Lessing-Gymnasiums',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  void _openPrivacyPolicy() async {
    try {
      final url = Uri.parse('https://lessing-gymnasium-karlsruhe.de/cm3/index.php/impressum/datenschutzerklaerung');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch privacy policy URL: $e');
    }
  }

  void _openKrankmeldung(BuildContext context) {
    // Navigate to the webview with the illness report
    context.push(AppRouter.webview, extra: {
      'url': 'https://apps.lgka-online.de/apps/krankmeldung/',
      'title': 'Krankmeldung',
      'headers': {
        'User-Agent': 'LGKA-App-Luka-Loehr',
      }
    });
  }
}
