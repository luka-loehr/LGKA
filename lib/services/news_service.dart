// Copyright Luka Löhr 2025

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:timezone/timezone.dart' as tz;
import '../utils/app_logger.dart';
import '../utils/app_info.dart';
import '../utils/retry_util.dart';
import 'cache_service.dart';

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

/// Represents a downloadable file found in news content
class NewsDownload {
  final String title;
  final String url;
  final String fileType; // e.g., "audio", "video", "document", "image"
  final String? size; // e.g., "3.64 MB"

  NewsDownload({
    required this.title,
    required this.url,
    required this.fileType,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'file_type': fileType,
        if (size != null) 'size': size,
      };
}

/// Represents a news event from the Lessing Gymnasium website
class NewsEvent {
  final String title;
  final String author;
  final String description;
  final String? content;
  final String? htmlContent; // HTML content with formatting preserved
  final String createdDate;
  final DateTime? parsedDate;
  final int views;
  final String url;
  final List<NewsLink> links; // Embedded links in text
  final List<NewsLink>? standaloneLinks; // Standalone links (full URLs) for buttons (nullable for backward compatibility)
  final List<NewsImage> images;
  final List<NewsDownload> downloads;
  final List<String> tags; // Tags/categories for the news item

  NewsEvent({
    required this.title,
    required this.author,
    required this.description,
    this.content,
    this.htmlContent,
    required this.createdDate,
    this.parsedDate,
    required this.views,
    required this.url,
    this.links = const [],
    this.standaloneLinks,
    this.images = const [],
    this.downloads = const [],
    this.tags = const [],
  });
  
  /// Get standalone links, returning empty list if null (for backward compatibility)
  List<NewsLink> get standaloneLinksOrEmpty => standaloneLinks ?? const [];

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'description': description,
        if (content != null) 'content': content,
        if (htmlContent != null) 'html_content': htmlContent,
        'created_date': createdDate,
        'views': views,
        'url': url,
        'links': links.map((l) => l.toJson()).toList(),
        'standalone_links': (standaloneLinks ?? []).map((l) => l.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
        'downloads': downloads.map((d) => d.toJson()).toList(),
        'tags': tags,
      };
}

/// Service for fetching news from the Lessing Gymnasium website
class NewsService {
  static const String newsUrl = 'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/neues';
  
  final _cacheService = CacheService();

  List<NewsEvent>? _cachedEvents;
  DateTime? _lastFetchTime;

  /// Get cached events if available and valid
  List<NewsEvent>? get cachedEvents => _cachedEvents;
  DateTime? get lastFetchTime => _lastFetchTime;
  
  bool get hasValidCache {
    if (_cachedEvents == null || _lastFetchTime == null) {
      return false;
    }
    return _cacheService.isCacheValid(CacheKey.news, lastFetchTime: _lastFetchTime);
  }

  /// Extracts all news events from the Lessing Gymnasium news page
  Future<List<NewsEvent>> fetchNewsEvents({bool forceRefresh = false}) async {
    // Return cached events if valid and not forcing refresh
    if (!forceRefresh && hasValidCache && _cachedEvents != null) {
      AppLogger.debug('Returning cached news events', module: 'NewsService');
      return _cachedEvents!;
    }
    
    // If cache exists but is stale, refresh in background and return stale cache
    if (!forceRefresh && _cachedEvents != null) {
      unawaited(_refreshCacheInBackground());
      return _cachedEvents!;
    }
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

          // Extract tags
          final List<String> tags = [];
          final tagsContainer = item.querySelector('ul.tags.list-inline');
          if (tagsContainer != null) {
            final tagLinks = tagsContainer.querySelectorAll('a');
            for (var tagLink in tagLinks) {
              final tagText = tagLink.text.trim();
              if (tagText.isNotEmpty) {
                tags.add(tagText);
              }
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
            'tags': tags,
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
            'htmlContent': contentData['htmlContent'],
            'links': contentData['links'],
            'standaloneLinks': contentData['standaloneLinks'],
            'images': contentData['images'],
            'downloads': contentData['downloads'],
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
              htmlContent: result['htmlContent'] as String?,
              createdDate: result['createdDate'] as String,
              parsedDate: result['parsedDate'] as DateTime?,
              views: result['views'] as int,
              url: result['url'] as String,
              links: (result['links'] as List<NewsLink>?) ?? [],
              standaloneLinks: (result['standaloneLinks'] as List<NewsLink>?),
              images: (result['images'] as List<NewsImage>?) ?? [],
              downloads: (result['downloads'] as List<NewsDownload>?) ?? [],
              tags: (result['tags'] as List<String>?) ?? [],
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
        
        // Cache the results
        _cachedEvents = events;
        _lastFetchTime = DateTime.now();
        _cacheService.updateCacheTimestamp(CacheKey.news, _lastFetchTime);
        
        return events;
      },
      maxRetries: 2,
      operationName: 'NewsService',
      shouldRetry: RetryUtil.isRetryableError,
    ).catchError((e) {
      AppLogger.error('Failed to fetch news events', module: 'NewsService', error: e);
      // Return cached events if available, even if stale
      if (_cachedEvents != null) {
        AppLogger.debug('Returning stale cached news events due to error', module: 'NewsService');
        return _cachedEvents!;
      }
      throw e;
    });
  }

  /// Refresh cache in background
  Future<void> _refreshCacheInBackground() async {
    final wasCacheValid = hasValidCache;
    try {
      final events = await fetchNewsEvents(forceRefresh: true);
      _cachedEvents = events;
      _lastFetchTime = DateTime.now();
      _cacheService.updateCacheTimestamp(CacheKey.news, _lastFetchTime);
    } catch (e) {
      AppLogger.debug('Background news refresh failed', module: 'NewsService');
      
      // If cache was invalid (app was backgrounded), clear cached data
      if (!wasCacheValid) {
        AppLogger.info('Refresh failed with invalid cache - clearing cached news', module: 'NewsService');
        _cachedEvents = null;
        _lastFetchTime = null;
      }
      // If cache was valid, keep existing data (silent failure)
    }
  }

  /// Clear the cache
  void clearCache() {
    _cachedEvents = null;
    _lastFetchTime = null;
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
            return {'content': null, 'links': <NewsLink>[], 'standaloneLinks': <NewsLink>[], 'images': <NewsImage>[], 'downloads': <NewsDownload>[]};
          }

          final document = html_parser.parse(response.body);
          
          // Look for the article body content in .com-content-article__body
          final articleBody = document.querySelector('.com-content-article__body');
          if (articleBody == null) {
            AppLogger.warning('Could not find .com-content-article__body element', module: 'NewsService');
            return {'content': null, 'links': <NewsLink>[], 'standaloneLinks': <NewsLink>[], 'images': <NewsImage>[], 'downloads': <NewsDownload>[]};
          }

          // Extract download links first (doclink-insert class)
          final List<NewsDownload> downloads = [];
          final downloadElements = articleBody.querySelectorAll('a.doclink-insert');
          for (var downloadElement in downloadElements) {
            try {
              final href = downloadElement.attributes['href'];
              if (href == null || href.isEmpty) continue;

              // Convert relative URLs to absolute URLs
              final fullUrl = href.startsWith('http')
                  ? href
                  : href.startsWith('/')
                      ? 'https://lessing-gymnasium-karlsruhe.de$href'
                      : 'https://lessing-gymnasium-karlsruhe.de/cm3/$href';

              // Extract title from data-title attribute or text content
              String title = downloadElement.attributes['data-title'] ?? '';
              if (title.isEmpty) {
                // Get text content, but remove size information
                title = downloadElement.text.trim();
                // Remove size pattern like "(3.64 MB)"
                title = title.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
              }

              // Extract file type from icon class or visually-hidden span
              String fileType = 'document'; // default
              
              // Check for k-icon-document-{type} class
              final iconSpan = downloadElement.querySelector('span[class*="k-icon-document"]');
              if (iconSpan != null) {
                final classes = iconSpan.classes;
                for (var className in classes) {
                  if (className.startsWith('k-icon-document-')) {
                    fileType = className.replaceFirst('k-icon-document-', '');
                    break;
                  }
                }
              }
              
              // Fallback: check visually-hidden span for file type
              if (fileType == 'document') {
                final hiddenSpan = downloadElement.querySelector('span.k-visually-hidden');
                if (hiddenSpan != null) {
                  final typeText = hiddenSpan.text.trim().toLowerCase();
                  if (typeText.isNotEmpty) {
                    fileType = typeText;
                  }
                }
              }

              // Extract size from text content (pattern: "(3.64 MB)")
              String? size;
              final fullText = downloadElement.text;
              final sizeMatch = RegExp(r'\(([^)]+)\)').firstMatch(fullText);
              if (sizeMatch != null) {
                size = sizeMatch.group(1)?.trim();
                // Check if it looks like a size (contains MB, KB, GB, etc.)
                if (size != null && !RegExp(r'\d+\s*(MB|KB|GB|B|bytes?)', caseSensitive: false).hasMatch(size)) {
                  size = null; // Not a size, probably something else in parentheses
                }
              }

              downloads.add(NewsDownload(
                title: title,
                url: fullUrl,
                fileType: fileType,
                size: size,
              ));
            } catch (e) {
              AppLogger.warning('Error parsing download link: $e', module: 'NewsService');
              continue;
            }
          }

          // Extract regular links from <a> tags (excluding download links)
          // Separate embedded links (in text) from standalone links (full URLs in own paragraph)
          final List<NewsLink> embeddedLinks = [];
          final List<NewsLink> standaloneLinks = [];
          
          final linkElements = articleBody.querySelectorAll('a');
          for (var linkElement in linkElements) {
            // Skip download links
            if (linkElement.classes.contains('doclink-insert')) continue;
            
            final href = linkElement.attributes['href'];
            final text = linkElement.text.trim();
            if (href == null || href.isEmpty || text.isEmpty) continue;
            
            // Convert relative URLs to absolute URLs
            final fullUrl = href.startsWith('http')
                ? href
                : href.startsWith('/')
                    ? 'https://lessing-gymnasium-karlsruhe.de$href'
                    : 'https://lessing-gymnasium-karlsruhe.de/cm3/$href';
            
            // Check if this is a standalone link (link text equals URL, or link is the only content in paragraph)
            final parent = linkElement.parent;
            bool isStandalone = false;
            
            if (parent != null && (parent.localName == 'p' || parent.localName == 'div')) {
              final parentText = parent.text.trim();
              // Standalone if: link text equals URL, or parent text is mostly just the link
              isStandalone = text == fullUrl || 
                            text == href ||
                            (text.startsWith('http') && parentText == text) ||
                            (text.startsWith('http') && parentText.length <= text.length + 5);
            }
            
            final link = NewsLink(text: text, url: fullUrl);
            if (isStandalone) {
              standaloneLinks.add(link);
            } else {
              embeddedLinks.add(link);
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
          // First, clone the article body and remove download links and standalone links to avoid duplicates
          // Keep embedded links in the text for RichText display
          final articleBodyClone = articleBody.clone(true);
          
          // Remove download links
          final downloadLinksInClone = articleBodyClone.querySelectorAll('a.doclink-insert');
          for (var downloadLink in downloadLinksInClone) {
            // Remove the download link but keep surrounding text
            downloadLink.remove();
          }
          
          // Remove standalone links (they'll be displayed as separate buttons)
          // Keep embedded links in the text
          final allLinksInClone = articleBodyClone.querySelectorAll('a:not(.doclink-insert)');
          for (var link in allLinksInClone) {
            final href = link.attributes['href'];
            final text = link.text.trim();
            if (href == null || href.isEmpty || text.isEmpty) continue;
            
            final fullUrl = href.startsWith('http')
                ? href
                : href.startsWith('/')
                    ? 'https://lessing-gymnasium-karlsruhe.de$href'
                    : 'https://lessing-gymnasium-karlsruhe.de/cm3/$href';
            
            // Check if this is a standalone link
            final parent = link.parent;
            bool isStandalone = false;
            
            if (parent != null && (parent.localName == 'p' || parent.localName == 'div')) {
              final parentText = parent.text.trim();
              // Standalone if: link text equals URL, or parent text is mostly just the link
              isStandalone = text == fullUrl || 
                            text == href ||
                            (text.startsWith('http') && parentText == text) ||
                            (text.startsWith('http') && parentText.length <= text.length + 5);
            }
            
            // Only remove standalone links, keep embedded links
            if (isStandalone) {
              link.remove();
            }
          }
          
          // Remove HTML comments from innerHTML
          String cleanHtml(String html) {
            // Remove all HTML comments (<!-- ... -->)
            html = html.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
            return html.trim();
          }
          
          // Extract HTML content preserving formatting
          // Get the inner HTML of the cloned article body
          String? htmlContent;
          final paragraphs = articleBodyClone.querySelectorAll('p');
          
          if (paragraphs.isEmpty) {
            // Fallback: get all HTML from the article body
            htmlContent = cleanHtml(articleBodyClone.innerHtml);
          } else {
            // Combine all paragraph HTML, filtering out empty ones and cleaning comments
            final paragraphHtmls = paragraphs
                .map((p) => cleanHtml(p.innerHtml))
                .where((html) => html.isNotEmpty);
            
            // Join paragraphs with double line breaks
            htmlContent = paragraphHtmls.join('\n\n');
          }
          
          // Also extract plain text for backward compatibility
          String? fullText;
          if (paragraphs.isEmpty) {
            fullText = articleBodyClone.text.trim();
          } else {
            fullText = paragraphs
                .map((p) => p.text.trim())
                .where((text) => text.isNotEmpty)
                .join('\n\n');
          }

          return {
            'content': fullText, // Plain text for backward compatibility
            'htmlContent': htmlContent, // HTML content with formatting
            'links': embeddedLinks, // Only embedded links for RichText
            'standaloneLinks': standaloneLinks, // Standalone links for buttons
            'images': images,
            'downloads': downloads,
          };
        },
        maxRetries: 2,
        operationName: 'NewsService',
        shouldRetry: RetryUtil.isRetryableError,
      );
    } catch (e) {
      AppLogger.warning('Error extracting full article content from $articleUrl: $e', module: 'NewsService');
      return {'content': null, 'links': <NewsLink>[], 'standaloneLinks': <NewsLink>[], 'images': <NewsImage>[], 'downloads': <NewsDownload>[]};
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

