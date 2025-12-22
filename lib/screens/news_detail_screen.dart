// Copyright Luka Löhr 2025

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/haptic_service.dart';
import '../services/news_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/color_provider.dart';
import '../providers/news_provider.dart';
import '../navigation/app_router.dart';

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

  List<NewsEvent> _getRecommendedArticles(List<NewsEvent> allEvents) {
    // Filter out current event
    final otherEvents = allEvents.where((e) => e.url != event.url).toList();
    
    if (otherEvents.isEmpty) return [];
    
    // Shuffle and take up to 3
    final shuffled = List<NewsEvent>.from(otherEvents)..shuffle(Random());
    return shuffled.take(3).toList();
  }

  void _navigateToArticle(BuildContext context, NewsEvent article) async {
    await HapticService.light();
    context.push(AppRouter.newsDetail, extra: article);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = AppColors.appBackground;
    final surfaceColor = AppColors.appSurface;
    final primaryTextColor = AppColors.primaryText;
    final secondaryTextColor = AppColors.secondaryText;
    final accentColor = ref.watch(currentColorProvider);
    final newsState = ref.watch(newsProvider);
    final recommendedArticles = _getRecommendedArticles(newsState.events);
    final theme = Theme.of(context);

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
              context.go(AppRouter.news);
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: primaryTextColor,
            ),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Article block - title, metadata, and content in one container
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          event.title,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Metadata
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            // Author
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    event.author == 'Unknown'
                                        ? AppLocalizations.of(context)!.unknown
                                        : event.author,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Date
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    event.createdDate == 'Unknown'
                                        ? AppLocalizations.of(context)!.unknown
                                        : event.createdDate,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Full content
                        if (event.content != null && event.content!.isNotEmpty)
                          Text(
                            event.content!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.8,
                              letterSpacing: 0.2,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
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
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Recommended articles section - separated
                  if (recommendedArticles.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: accentColor.withValues(alpha: 0.2),
                            thickness: 1,
                            height: 32,
                          ),
                          Text(
                            AppLocalizations.of(context)!.continueReading,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    ...recommendedArticles.map((article) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.0),
                          onTap: () => _navigateToArticle(context, article),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (article.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    article.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    // Author
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 14,
                                          color: accentColor.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            article.author == 'Unknown'
                                                ? AppLocalizations.of(context)!.unknown
                                                : article.author,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: secondaryTextColor.withValues(alpha: 0.8),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Date
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 14,
                                          color: accentColor.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            article.createdDate == 'Unknown'
                                                ? AppLocalizations.of(context)!.unknown
                                                : article.createdDate,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: secondaryTextColor.withValues(alpha: 0.8),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 32),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

