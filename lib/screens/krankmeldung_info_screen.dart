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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning icon and title
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wichtiger Hinweis',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main disclaimer text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Die Krankmeldung hat nichts mit der LGKA+ App zu tun.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Die Krankmeldung wird vom Lessing-Gymnasium Karlsruhe selbst entwickelt und betrieben. Sie steht in keinem rechtlichen Zusammenhang mit der LGKA+ App oder dem App-Entwickler Luka Löhr.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Bei Fehlern, Bugs oder Problemen mit der Krankmeldung wende dich bitte direkt an das Lessing-Gymnasium Karlsruhe.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy policy section
            Text(
              'Datenschutz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bevor du die Krankmeldung nutzt, lies bitte die Datenschutzerklärung des Lessing-Gymnasiums Karlsruhe:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  InkWell(
                    onTap: () {
                      HapticService.subtle();
                      _openPrivacyPolicy();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            color: AppColors.appBlueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Datenschutzerklärung des Lessing-Gymnasiums Karlsruhe',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.appBlueAccent,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: AppColors.appBlueAccent.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.subtle();
                  _openKrankmeldung(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBlueAccent,
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
