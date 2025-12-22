// Copyright Luka Löhr 2025

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:timezone/timezone.dart' as tz;
import '../utils/app_logger.dart';
import '../utils/app_info.dart';
import '../utils/retry_util.dart';

/// Represents a link found in news content
class NewsLink {
  final String text;
  final String url;

  NewsLink({
    required this.text,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'url': url,
      };
}

/// Represents an image found in news content
class NewsImage {
  final String url;
  final String? thumbnailUrl;
  final String? alt;

  NewsImage({
    required this.url,
    this.thumbnailUrl,
    this.alt,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (alt != null) 'alt': alt,
      };
}

/// Represents a news event from the Lessing Gymnasium website
class NewsEvent {
  final String title;
  final String author;
  final String description;
  final String? content;
  final String createdDate;
  final DateTime? parsedDate;
  final int views;
  final String url;
  final List<NewsLink> links;
  final List<NewsImage> images;

  NewsEvent({
    required this.title,
    required this.author,
    required this.description,
    this.content,
    required this.createdDate,
    this.parsedDate,
    required this.views,
    required this.url,
    this.links = const [],
    this.images = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'description': description,
        if (content != null) 'content': content,
        'created_date': createdDate,
        'views': views,
        'url': url,
        'links': links.map((l) => l.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
      };
}

/// Service for fetching news from the Lessing Gymnasium website
class NewsService {
  static const String newsUrl = 'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/neues';

  /// Extracts all news events from the Lessing Gymnasium news page
  Future<List<NewsEvent>> fetchNewsEvents() async {
    AppLogger.network('Fetching news events');
    
    return RetryUtil.retry<List<NewsEvent>>(
      operation: () async {
        final response = await http.get(
          Uri.parse(newsUrl),
          headers: {'User-Agent': AppInfo.userAgent},
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('Failed to load news: ${response.statusCode}');
        }

        final document = html_parser.parse(response.body);

        // Find all blog-item divs (news articles)
        final blogItems = document.querySelectorAll('.blog-item');

        // First, extract metadata from all articles
        final List<Map<String, dynamic>> metadataList = [];
        for (var item in blogItems) {
        try {
          // Extract title
          final titleElement = item.querySelector('h2 a');
          if (titleElement == null) continue;
          
          final title = titleElement.text.trim();
          final articleUrl = titleElement.attributes['href'] ?? '';
          final fullUrl = articleUrl.startsWith('http') 
              ? articleUrl 
              : 'https://lessing-gymnasium-karlsruhe.de$articleUrl';

          // Extract author
          String author = 'Unknown';
          final createdbyElement = item.querySelector('.createdby');
          if (createdbyElement != null) {
            final authorText = createdbyElement.text;
            // Extract text after "Geschrieben von"
            if (authorText.contains('Geschrieben von')) {
              author = authorText
                  .replaceAll('Geschrieben von', '')
                  .trim()
                  .split('\n')
                  .first
                  .trim();
            }
          }

          // Extract creation date
          String createdDate = 'Unknown';
          DateTime? parsedDate;
          final createElement = item.querySelector('.create');
          if (createElement != null) {
            final dateText = createElement.text;
            // Extract text after "Erstellt:"
            if (dateText.contains('Erstellt:')) {
              createdDate = dateText
                  .replaceAll('Erstellt:', '')
                  .trim()
                  .split('\n')
                  .first
                  .trim();
              
              // Parse the date string (format: DD.MM.YYYY)
              parsedDate = _parseGermanDate(createdDate);
            }
          }

          // Extract view count
          int views = 0;
          final hitsElement = item.querySelector('.hits');
          if (hitsElement != null) {
            final hitsText = hitsElement.text;
            // Extract number after "Zugriffe:"
            if (hitsText.contains('Zugriffe:')) {
              final viewsStr = hitsText
                  .replaceAll('Zugriffe:', '')
                  .trim()
                  .replaceAll(RegExp(r'[^0-9]'), '');
              views = int.tryParse(viewsStr) ?? 0;
            }
          }

          // Extract description
          String description = '';
          final itemContent = item.querySelector('.item-content');
          if (itemContent != null) {
            // Get all paragraph text
            final paragraphs = itemContent.querySelectorAll('p');
            if (paragraphs.isNotEmpty) {
              description = paragraphs
                  .map((p) => p.text.trim())
                  .where((text) => text.isNotEmpty)
                  .take(2)
                  .join(' ');
            }
          }

          metadataList.add({
            'title': title,
            'author': author,
            'description': description,
            'createdDate': createdDate,
            'parsedDate': parsedDate,
            'views': views,
            'url': fullUrl,
          });
        } catch (e) {
          AppLogger.warning('Error parsing news article metadata: $e', module: 'NewsService');
          continue;
        }
      }

        // Fetch full content for all articles concurrently
        AppLogger.network('Fetching full content for ${metadataList.length} articles', module: 'NewsService');
        final contentFutures = metadataList.map((metadata) async {
          final contentData = await _fetchFullArticleContent(metadata['url'] as String);
          return {
            ...metadata,
            'content': contentData['content'],
            'links': contentData['links'],
            'images': contentData['images'],
          };
        }).toList();

        // Wait for all requests to complete
        final results = await Future.wait(contentFutures);

        // Build final event list
        final List<NewsEvent> events = [];
        for (var result in results) {
          try {
            final event = NewsEvent(
              title: result['title'] as String,
              author: result['author'] as String,
              description: result['description'] as String,
              content: result['content'] as String?,
              createdDate: result['createdDate'] as String,
              parsedDate: result['parsedDate'] as DateTime?,
              views: result['views'] as int,
              url: result['url'] as String,
              links: (result['links'] as List<NewsLink>?) ?? [],
              images: (result['images'] as List<NewsImage>?) ?? [],
            );
            events.add(event);
          } catch (e) {
            AppLogger.warning('Error creating news event: $e', module: 'NewsService');
            continue;
          }
        }

        // Sort events by date (newest first)
        events.sort((a, b) {
          // If both have parsed dates, compare them
          if (a.parsedDate != null && b.parsedDate != null) {
            return b.parsedDate!.compareTo(a.parsedDate!);
          }
          // If only one has a parsed date, prioritize it
          if (a.parsedDate != null) return -1;
          if (b.parsedDate != null) return 1;
          // If neither has a parsed date, maintain original order
          return 0;
        });

        AppLogger.success('Fetched ${events.length} news events with full content', module: 'NewsService');
        return events;
      },
      maxRetries: 2,
      operationName: 'NewsService',
      shouldRetry: RetryUtil.isRetryableError,
    ).catchError((e) {
      AppLogger.error('Failed to fetch news events', module: 'NewsService', error: e);
      throw e;
    });
  }

  /// Fetches the full content, links, and images from an individual news article page
  Future<Map<String, dynamic>> _fetchFullArticleContent(String articleUrl) async {
    try {
      return await RetryUtil.retry<Map<String, dynamic>>(
        operation: () async {
          final response = await http.get(
            Uri.parse(articleUrl),
            headers: {'User-Agent': AppInfo.userAgent},
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode != 200) {
            AppLogger.warning('Failed to load article: ${response.statusCode}', module: 'NewsService');
            return {'content': null, 'links': <NewsLink>[], 'images': <NewsImage>[]};
          }

          final document = html_parser.parse(response.body);
          
          // Look for the article body content in .com-content-article__body
          final articleBody = document.querySelector('.com-content-article__body');
          if (articleBody == null) {
            AppLogger.warning('Could not find .com-content-article__body element', module: 'NewsService');
            return {'content': null, 'links': <NewsLink>[], 'images': <NewsImage>[]};
          }

          // Extract links from <a> tags within paragraphs
          final List<NewsLink> links = [];
          final linkElements = articleBody.querySelectorAll('a');
          for (var linkElement in linkElements) {
            final href = linkElement.attributes['href'];
            final text = linkElement.text.trim();
            if (href != null && href.isNotEmpty && text.isNotEmpty) {
              // Convert relative URLs to absolute URLs
              final fullUrl = href.startsWith('http')
                  ? href
                  : href.startsWith('/')
                      ? 'https://lessing-gymnasium-karlsruhe.de$href'
                      : 'https://lessing-gymnasium-karlsruhe.de/cm3/$href';
              links.add(NewsLink(text: text, url: fullUrl));
            }
          }

          // Extract images from gallery plugin (sigFreeContainer) and regular img tags
          final List<NewsImage> images = [];
          
          // Check for gallery plugin images (Simple Image Gallery)
          final galleryContainers = articleBody.querySelectorAll('.sigFreeContainer');
          for (var gallery in galleryContainers) {
            final galleryLinks = gallery.querySelectorAll('a.sigFreeLink');
            for (var link in galleryLinks) {
              final imageUrl = link.attributes['href'];
              final thumbnailUrl = link.attributes['data-thumb'];
              final imgElement = link.querySelector('img');
              final alt = imgElement?.attributes['alt'] ?? imgElement?.attributes['title'];
              
              if (imageUrl != null && imageUrl.isNotEmpty) {
                final fullImageUrl = imageUrl.startsWith('http')
                    ? imageUrl
                    : imageUrl.startsWith('/')
                        ? 'https://lessing-gymnasium-karlsruhe.de$imageUrl'
                        : 'https://lessing-gymnasium-karlsruhe.de/cm3/$imageUrl';
                
                String? fullThumbnailUrl;
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
                  fullThumbnailUrl = thumbnailUrl.startsWith('http')
                      ? thumbnailUrl
                      : thumbnailUrl.startsWith('/')
                          ? 'https://lessing-gymnasium-karlsruhe.de$thumbnailUrl'
                          : 'https://lessing-gymnasium-karlsruhe.de/cm3/$thumbnailUrl';
                }
                
                images.add(NewsImage(
                  url: fullImageUrl,
                  thumbnailUrl: fullThumbnailUrl,
                  alt: alt,
                ));
              }
            }
          }
          
          // Also check for regular img tags that might not be in galleries
          final imgElements = articleBody.querySelectorAll('img');
          for (var img in imgElements) {
            // Skip images that are already in galleries (they have sigFreeImg class)
            if (img.classes.contains('sigFreeImg')) continue;
            
            final src = img.attributes['src'];
            if (src != null && src.isNotEmpty) {
              final fullImageUrl = src.startsWith('http')
                  ? src
                  : src.startsWith('/')
                      ? 'https://lessing-gymnasium-karlsruhe.de$src'
                      : 'https://lessing-gymnasium-karlsruhe.de/cm3/$src';
              
              // Check if this image is already in our list (avoid duplicates)
              if (!images.any((i) => i.url == fullImageUrl)) {
                images.add(NewsImage(
                  url: fullImageUrl,
                  alt: img.attributes['alt'],
                ));
              }
            }
          }

          // Extract text content from paragraphs (preserving structure for link replacement)
          final paragraphs = articleBody.querySelectorAll('p');
          
          String? fullText;
          if (paragraphs.isEmpty) {
            // Fallback: get all text from the article body
            fullText = articleBody.text.trim();
          } else {
            // Combine all paragraph text, filtering out empty ones
            fullText = paragraphs
                .map((p) => p.text.trim())
                .where((text) => text.isNotEmpty)
                .join('\n\n');
          }

          return {
            'content': fullText,
            'links': links,
            'images': images,
          };
        },
        maxRetries: 2,
        operationName: 'NewsService',
        shouldRetry: RetryUtil.isRetryableError,
      );
    } catch (e) {
      AppLogger.warning('Error extracting full article content from $articleUrl: $e', module: 'NewsService');
      return {'content': null, 'links': <NewsLink>[], 'images': <NewsImage>[]};
    }
  }

  /// Parse German date string (DD.MM.YYYY) to DateTime in Europe/Berlin timezone
  DateTime? _parseGermanDate(String dateString) {
    try {
      // Expected format: DD.MM.YYYY (e.g., "15.01.2025")
      final parts = dateString.split('.');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      // Get Berlin timezone location
      final berlin = tz.getLocation('Europe/Berlin');
      
      // Create DateTime in Berlin timezone at midnight
      final dateTime = tz.TZDateTime(berlin, year, month, day);
      
      return dateTime;
    } catch (e) {
      AppLogger.warning('Failed to parse date: $dateString', module: 'NewsService');
      return null;
    }
  }
}

