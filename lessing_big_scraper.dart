import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// Represents a full news article with both overview and complete content
class FullNewsArticle {
  final String title;
  final String author;
  final String descriptionTruncated; // Overview/excerpt from main page
  final String fullContent;          // Full article content from subpage
  final String createdDate;
  final int views;
  final String url;

  FullNewsArticle({
    required this.title,
    required this.author,
    required this.descriptionTruncated,
    required this.fullContent,
    required this.createdDate,
    required this.views,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'description_truncated': descriptionTruncated,
        'full_content': fullContent,
        'created_date': createdDate,
        'views': views,
        'url': url,
      };

  @override
  String toString() {
    return '''
================================================================================
Title: $title
Views: $views
Author: $author
Created: $createdDate
URL: $url
--------------------------------------------------------------------------------
Description:
$descriptionTruncated
--------------------------------------------------------------------------------
Full Article:
$fullContent
================================================================================
''';
  }
}

/// Fetches the full content from an individual news article page
Future<String> extractFullArticleContent(String articleUrl) async {
  try {
    final response = await http.get(
      Uri.parse(articleUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      },
    );

    if (response.statusCode != 200) {
      print('  ⚠ Failed to load article: ${response.statusCode}');
      return '';
    }

    final document = html_parser.parse(response.body);
    
    // Look for the article body content in .com-content-article__body
    final articleBody = document.querySelector('.com-content-article__body');
    if (articleBody == null) {
      print('  ⚠ Could not find .com-content-article__body element');
      return '';
    }

    // Extract all paragraphs from the article body
    final paragraphs = articleBody.querySelectorAll('p');
    
    if (paragraphs.isEmpty) {
      // Fallback: get all text from the article body
      return articleBody.text.trim();
    }

    // Combine all paragraph text, filtering out empty ones
    final fullText = paragraphs
        .map((p) => p.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');

    return fullText;
  } catch (e) {
    print('  ⚠ Error extracting full article content from $articleUrl: $e');
    return '';
  }
}

/// Extracts metadata from a blog item without fetching the full content
Map<String, dynamic> extractArticleMetadata(Element item, int index) {
  // Extract title
  final titleElement = item.querySelector('h2 a');
  if (titleElement == null) return {};
  
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
  final createElement = item.querySelector('.create');
  if (createElement != null) {
    final dateText = createElement.text;
    if (dateText.contains('Erstellt:')) {
      createdDate = dateText
          .replaceAll('Erstellt:', '')
          .trim()
          .split('\n')
          .first
          .trim();
    }
  }

  // Extract view count
  int views = 0;
  final hitsElement = item.querySelector('.hits');
  if (hitsElement != null) {
    final hitsText = hitsElement.text;
    if (hitsText.contains('Zugriffe:')) {
      final viewsStr = hitsText
          .replaceAll('Zugriffe:', '')
          .trim()
          .replaceAll(RegExp(r'[^0-9]'), '');
      views = int.tryParse(viewsStr) ?? 0;
    }
  }

  // Extract truncated description (from overview page)
  String descriptionTruncated = '';
  final itemContent = item.querySelector('.item-content');
  if (itemContent != null) {
    final paragraphs = itemContent.querySelectorAll('p');
    if (paragraphs.isNotEmpty) {
      descriptionTruncated = paragraphs
          .map((p) => p.text.trim())
          .where((text) => text.isNotEmpty && text != 'Mehr lesen')
          .take(2)
          .join(' ');
    }
  }

  return {
    'title': title,
    'author': author,
    'createdDate': createdDate,
    'views': views,
    'descriptionTruncated': descriptionTruncated,
    'url': fullUrl,
    'index': index,
  };
}

/// Extracts all news events with full content from the Lessing Gymnasium news page
/// Fetches all article subpages concurrently for better performance
/// 
/// Returns a list of [FullNewsArticle] objects containing both the truncated 
/// overview and the full article content from each subpage
Future<List<FullNewsArticle>> extractFullNewsArticles(String url) async {
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load page: ${response.statusCode}');
  }

  final document = html_parser.parse(response.body);

  // Find all blog-item divs (news articles)
  final blogItems = document.querySelectorAll('.blog-item');

  print('Found ${blogItems.length} articles to scrape...\n');

  // Extract metadata from all articles first
  final metadataList = <Map<String, dynamic>>[];
  for (var i = 0; i < blogItems.length; i++) {
    try {
      final metadata = extractArticleMetadata(blogItems[i], i);
      if (metadata.isNotEmpty) {
        metadataList.add(metadata);
        print('${i + 1}. ${metadata['title']}');
      }
    } catch (e) {
      print('Error extracting metadata for article ${i + 1}: $e');
    }
  }

  print('\nFetching full content from ${metadataList.length} articles concurrently...\n');

  // Fetch all article contents concurrently
  final contentFutures = metadataList.map((metadata) async {
    final fullContent = await extractFullArticleContent(metadata['url'] as String);
    return {
      ...metadata,
      'fullContent': fullContent,
    };
  }).toList();

  // Wait for all requests to complete
  final results = await Future.wait(contentFutures);

  // Build final article list
  final articles = <FullNewsArticle>[];
  for (var result in results) {
    try {
      final article = FullNewsArticle(
        title: result['title'] as String,
        author: result['author'] as String,
        descriptionTruncated: result['descriptionTruncated'] as String,
        fullContent: result['fullContent'] as String,
        createdDate: result['createdDate'] as String,
        views: result['views'] as int,
        url: result['url'] as String,
      );
      articles.add(article);
      print('✓ Article ${result['index'] + 1}: "${result['title']}" - ${(result['fullContent'] as String).length} characters');
    } catch (e) {
      print('Error creating article object: $e');
    }
  }

  return articles;
}

/// Pretty print the extracted articles
void printArticles(List<FullNewsArticle> articles) {
  for (var i = 0; i < articles.length; i++) {
    print('\nArticle #${i + 1}');
    print(articles[i]);
  }
}

void main() async {
  const url = 'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/neues';

  print('=== Lessing Gymnasium Big Scraper ===');
  print('Scraping news articles with full content from: $url\n');

  try {
    final articles = await extractFullNewsArticles(url);
    print('\n=== Scraping Complete ===');
    print('Successfully scraped ${articles.length} articles with full content\n');
    
    printArticles(articles);

    // Output as JSON
    print('\n\n=== JSON Output ===');
    final jsonOutput = jsonEncode(articles.map((a) => a.toJson()).toList());
    print(jsonOutput);
  } catch (e) {
    print('Error: $e');
  }
}
