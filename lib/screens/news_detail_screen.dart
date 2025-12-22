// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/haptic_service.dart';
import '../services/news_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/color_provider.dart';

class NewsDetailScreen extends ConsumerWidget {
  final NewsEvent event;

  const NewsDetailScreen({
    super.key,
    required this.event,
  });

  Future<void> _openInBrowser() async {
    await HapticService.light();
    final uri = Uri.parse(event.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = AppColors.appBackground;
    final surfaceColor = AppColors.appSurface;
    final primaryTextColor = AppColors.primaryText;
    final secondaryTextColor = AppColors.secondaryText;
    final accentColor = ref.watch(currentColorProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: primaryTextColor,
          ),
          onPressed: () async {
            await HapticService.light();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // News Title (main title)
                  Text(
                    event.title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Metadata section with accent colors
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event.author == 'Unknown'
                                    ? AppLocalizations.of(context)!.unknown
                                    : event.author,
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date and Views
                        Row(
                          children: [
                            // Date
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              event.createdDate == 'Unknown'
                                  ? AppLocalizations.of(context)!.unknown
                                  : event.createdDate,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 24),
                            
                            // Views
                            Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${event.views}',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Full content
                  if (event.content != null && event.content!.isNotEmpty)
                    Text(
                      event.content!,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        height: 1.7,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.noNewsFound,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Open in Browser button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser, size: 20),
                      label: Text(AppLocalizations.of(context)!.openInBrowser),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

