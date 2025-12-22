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
          event.title,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.open_in_browser,
              color: accentColor,
            ),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed metadata section at the top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
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
                  const SizedBox(height: 12),
                  
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
            
            // Scrollable content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                  
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
                        
                        const SizedBox(height: 32),
                        
                        // Recommended articles section
                        if (recommendedArticles.isNotEmpty) ...[
                          Text(
                            AppLocalizations.of(context)!.continueReading,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...recommendedArticles.map((article) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12.0),
                                onTap: () => _navigateToArticle(context, article),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (article.description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          article.description,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14,
                                            color: accentColor.withValues(alpha: 0.8),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            article.createdDate == 'Unknown'
                                                ? AppLocalizations.of(context)!.unknown
                                                : article.createdDate,
                                            style: TextStyle(
                                              color: secondaryTextColor.withValues(alpha: 0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.visibility_outlined,
                                            size: 14,
                                            color: accentColor.withValues(alpha: 0.8),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${article.views}',
                                            style: TextStyle(
                                              color: secondaryTextColor.withValues(alpha: 0.8),
                                              fontSize: 12,
                                            ),
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
          ],
        ),
      ),
    );
  }
}

