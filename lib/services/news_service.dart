// Copyright Luka Löhr 2025

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:timezone/timezone.dart' as tz;
import '../utils/app_logger.dart';
import '../utils/app_info.dart';

/// Represents a news event from the Lessing Gymnasium website
class NewsEvent {
  final String title;
  final String author;
  final String description;
  final String createdDate;
  final DateTime? parsedDate;
  final int views;
  final String url;

  NewsEvent({
    required this.title,
    required this.author,
    required this.description,
    required this.createdDate,
    this.parsedDate,
    required this.views,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'description': description,
        'created_date': createdDate,
        'views': views,
        'url': url,
      };
}

/// Service for fetching news from the Lessing Gymnasium website
class NewsService {
  static const String newsUrl = 'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/neues';

  /// Extracts all news events from the Lessing Gymnasium news page
  Future<List<NewsEvent>> fetchNewsEvents() async {
    AppLogger.network('Fetching news events');
    
    try {
      final response = await http.get(
        Uri.parse(newsUrl),
        headers: {'User-Agent': AppInfo.userAgent},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load news: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      final List<NewsEvent> events = [];

      // Find all blog-item divs (news articles)
      final blogItems = document.querySelectorAll('.blog-item');

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

          final event = NewsEvent(
            title: title,
            author: author,
            description: description,
            createdDate: createdDate,
            parsedDate: parsedDate,
            views: views,
            url: fullUrl,
          );

          events.add(event);
        } catch (e) {
          AppLogger.warning('Error parsing news article: $e', module: 'NewsService');
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

      AppLogger.success('Fetched ${events.length} news events', module: 'NewsService');
      return events;
    } catch (e) {
      AppLogger.error('Failed to fetch news events', module: 'NewsService', error: e);
      rethrow;
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

