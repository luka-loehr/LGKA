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

  factory NewsLink.fromJson(Map<String, dynamic> json) => NewsLink(
        text: json['text'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
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

  factory NewsImage.fromJson(Map<String, dynamic> json) => NewsImage(
        url: json['url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        alt: json['alt'] as String?,
      );
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

  factory NewsDownload.fromJson(Map<String, dynamic> json) => NewsDownload(
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        fileType: json['file_type'] as String? ?? 'document',
        size: json['size'] as String?,
      );
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
        if (parsedDate != null) 'parsed_date': parsedDate!.toIso8601String(),
        'views': views,
        'url': url,
        'links': links.map((l) => l.toJson()).toList(),
        'standalone_links': (standaloneLinks ?? []).map((l) => l.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
        'downloads': downloads.map((d) => d.toJson()).toList(),
        'tags': tags,
      };

  factory NewsEvent.fromJson(Map<String, dynamic> json) => NewsEvent(
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        description: json['description'] as String? ?? '',
        content: json['content'] as String?,
        htmlContent: json['html_content'] as String?,
        createdDate: json['created_date'] as String? ?? '',
        parsedDate: json['parsed_date'] != null
            ? DateTime.tryParse(json['parsed_date'] as String)
            : null,
        views: json['views'] as int? ?? 0,
        url: json['url'] as String? ?? '',
        links: (json['links'] as List?)
                ?.map((e) => NewsLink.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        standaloneLinks: (json['standalone_links'] as List?)
            ?.map((e) => NewsLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        images: (json['images'] as List?)
                ?.map((e) => NewsImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        downloads: (json['downloads'] as List?)
                ?.map((e) => NewsDownload.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      );
}
