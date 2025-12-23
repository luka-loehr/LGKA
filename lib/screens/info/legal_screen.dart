// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/haptic_service.dart';

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'Rechtliches',
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LGKA+',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLinkRow(
                    context,
                    Icons.shield_outlined, 
                    'Datenschutzerklärung', 
                    'https://luka-loehr.github.io/LGKA/privacy.html'
                  ),
                  const SizedBox(height: 16),
                  _buildLinkRow(
                    context,
                    Icons.info_outline, 
                    'Impressum', 
                    'https://luka-loehr.github.io/LGKA/impressum.html'
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }
  
  Widget _buildLinkRow(BuildContext context, IconData icon, String text, String url) {
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
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 