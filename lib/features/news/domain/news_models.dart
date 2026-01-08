// Copyright Luka Löhr 2026

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
