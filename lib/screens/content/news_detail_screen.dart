// Copyright Luka Löhr 2025

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/news_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/color_provider.dart';
import '../../services/haptic_service.dart';
import '../../providers/news_provider.dart';
import '../../navigation/app_router.dart';

/// Helper class to track link matches in content
class _LinkMatch {
  final int start;
  final int end;
  final NewsLink link;

  _LinkMatch({
    required this.start,
    required this.end,
    required this.link,
  });
}

class NewsDetailScreen extends ConsumerWidget {
  final NewsEvent event;

  const NewsDetailScreen({
    super.key,
    required this.event,
  });

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(event.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  /// Builds a RichText widget with clickable links from the content
  Widget _buildContentWithLinks(String content, List<NewsLink> links, BuildContext context, ThemeData theme, Color accentColor) {
    if (links.isEmpty) {
      // No links, return simple text
      return Text(
        content,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          letterSpacing: 0.2,
        ),
      );
    }

    // Create a map of link text to URL for quick lookup
    final linkMap = <String, String>{};
    for (var link in links) {
      linkMap[link.text] = link.url;
    }

    // Split content by link texts and build TextSpans
    final List<TextSpan> spans = [];
    
    // Sort links by text length (longest first) to avoid partial matches
    final sortedLinks = List<NewsLink>.from(links)..sort((a, b) => b.text.length.compareTo(a.text.length));
    
    final List<_LinkMatch> matches = [];
    
    // Find all link occurrences in the content
    for (var link in sortedLinks) {
      int index = content.indexOf(link.text);
      while (index != -1) {
        matches.add(_LinkMatch(
          start: index,
          end: index + link.text.length,
          link: link,
        ));
        index = content.indexOf(link.text, index + 1);
      }
    }
    
    // Sort matches by start position
    matches.sort((a, b) => a.start.compareTo(b.start));
    
    // Remove overlapping matches (keep first occurrence)
    final List<_LinkMatch> nonOverlappingMatches = [];
    for (var match in matches) {
      bool overlaps = false;
      for (var existing in nonOverlappingMatches) {
        if (match.start < existing.end && match.end > existing.start) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) {
        nonOverlappingMatches.add(match);
      }
    }
    
    // Build TextSpans
    int currentIndex = 0;
    for (var match in nonOverlappingMatches) {
      // Add text before the link
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: content.substring(currentIndex, match.start),
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            letterSpacing: 0.2,
          ),
        ));
      }
      
      // Add the clickable link
      spans.add(TextSpan(
        text: match.link.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          letterSpacing: 0.2,
          color: accentColor,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            HapticService.light();
            _openLink(match.link.url);
          },
      ));
      
      currentIndex = match.end;
    }
    
    // Add remaining text after the last link
    if (currentIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentIndex),
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          letterSpacing: 0.2,
        ),
      ));
    }
    
    // If no matches were found, return simple text
    if (spans.isEmpty) {
      return Text(
        content,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          letterSpacing: 0.2,
        ),
      );
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<NewsEvent> _getRecommendedArticles(List<NewsEvent> allEvents) {
    // Filter out current event
    final otherEvents = allEvents.where((e) => e.url != event.url).toList();
    
    if (otherEvents.isEmpty) return [];
    
    // Shuffle and take up to 3
    final shuffled = List<NewsEvent>.from(otherEvents)..shuffle(Random());
    return shuffled.take(3).toList();
  }

  void _navigateToArticle(BuildContext context, NewsEvent article) {
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
      extendBody: true,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: primaryTextColor,
          ),
          onPressed: () {
            HapticService.light();
            if (context.mounted) {
              context.pop();
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
            onPressed: () {
              HapticService.light();
              _openInBrowser();
            },
          ),
        ],
      ),
      body: CustomScrollView(
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
                        
                        // Full content with clickable links
                        if (event.content != null && event.content!.isNotEmpty) ...[
                          _buildContentWithLinks(
                            event.content!,
                            event.links,
                            context,
                            theme,
                            accentColor,
                          ),
                          
                          // Display images if available
                          if (event.images.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ...event.images.map((image) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.light();
                                  _openLink(image.url);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        image.url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: accentColor,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: secondaryTextColor.withValues(alpha: 0.5),
                                                size: 48,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Overlay icon to indicate image is clickable
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(6.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Icon(
                                            Icons.open_in_new,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ]
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
                  
                  const SizedBox(height: 24),
                  
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
                            height: 16,
                          ),
                          Text(
                            AppLocalizations.of(context)!.weitereNeuigkeiten,
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
                          onTap: () {
                            HapticService.medium();
                            _navigateToArticle(context, article);
                          },
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
          SliverToBoxAdapter(
            child: SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
          ),
        ],
      ),
    );
  }
}

