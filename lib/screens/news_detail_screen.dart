// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: Text(
          AppLocalizations.of(context)!.news,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title
                  Text(
                    event.title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Metadata section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: secondaryTextColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.author == 'Unknown'
                                  ? AppLocalizations.of(context)!.unknown
                                  : event.author,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Date and Views
                        Row(
                          children: [
                            // Date
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: secondaryTextColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.createdDate == 'Unknown'
                                  ? AppLocalizations.of(context)!.unknown
                                  : event.createdDate,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 20),
                            
                            // Views
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: secondaryTextColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${event.views}',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                        height: 1.6,
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

