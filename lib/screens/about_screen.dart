import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    final todayPdfTimestamp = pdfRepo.todayLastUpdated;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'About',
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
            const SizedBox(height: 4),
            Text(
              'Die neue Vertretungsplan-App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
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
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: AppColors.appOnSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lessing Gymnasium Karlsruhe',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.appOnSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '✨ Kein langes Suchen mehr\n📱 Vertretungsplan direkt aufs Handy\n⚡ Immer up-to-date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.6,
                        ),
                  ),
                  if (todayPdfTimestamp.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.calendarIconBackground
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.update,
                            color: AppColors.calendarIconBackground,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Update: $todayPdfTimestamp',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.calendarIconBackground,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Made by Luka 👋',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version =
                        snapshot.hasData ? snapshot.data!.version : '1.1';
                    return Text(
                      'v$version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText.withOpacity(0.7),
                          ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 