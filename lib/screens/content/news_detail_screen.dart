// Copyright Luka Löhr 2025

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
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

  /// Get icon for file type
  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'audio':
      case 'sound':
        return Icons.headphones;
      case 'video':
      case 'movie':
        return Icons.videocam;
      case 'image':
      case 'picture':
      case 'photo':
        return Icons.image;
      case 'pdf':
      case 'document':
        return Icons.picture_as_pdf;
      case 'archive':
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'text':
        return Icons.text_snippet;
      case 'spreadsheet':
      case 'excel':
        return Icons.table_chart;
      case 'presentation':
      case 'powerpoint':
        return Icons.slideshow;
      default:
        return Icons.download;
    }
  }

  /// Build download button widget
  Widget _buildDownloadButton(NewsDownload download, BuildContext context, ThemeData theme, Color accentColor, Color surfaceColor) {
    return Container(
      margin: EdgeInsets.zero,
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
          onTap: () {
            HapticService.medium();
            _openLink(download.url);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // File type icon
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    _getFileTypeIcon(download.fileType),
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (download.size != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          download.size!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Download icon
                Icon(
                  Icons.download_outlined,
                  color: accentColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Converts HTML content to TextSpans with formatting preserved
  List<TextSpan> _parseHtmlToTextSpans(String html, ThemeData theme, Color accentColor, List<NewsLink> links, {bool trimTrailingWhitespace = false}) {
    final List<TextSpan> spans = [];
    
    // Parse the HTML
    final document = html_parser.parse(html);
    
    // Base text style
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.8,
      letterSpacing: 0.2,
    );
    
    // Recursive function to convert HTML nodes to TextSpans
    List<TextSpan> processNode(dynamic node, TextStyle? parentStyle) {
      final List<TextSpan> nodeSpans = [];
      
      // Check if node is an element (has localName property)
      try {
        final localName = (node as dynamic).localName;
        if (localName != null) {
          // It's an element
          final tagName = (localName as String?)?.toLowerCase();
          TextStyle? currentStyle = parentStyle ?? baseStyle;
          
          // Apply formatting based on tag
          switch (tagName) {
            case 'strong':
            case 'b':
              currentStyle = currentStyle?.copyWith(fontWeight: FontWeight.bold);
              break;
            case 'em':
            case 'i':
              currentStyle = currentStyle?.copyWith(fontStyle: FontStyle.italic);
              break;
            case 'u':
              currentStyle = currentStyle?.copyWith(decoration: TextDecoration.underline);
              break;
            case 'a':
              // Skip link tags - just process their text content as regular text
              // Links will be handled later by the simple matching approach
              final nodes = (node as dynamic).nodes as List<dynamic>?;
              if (nodes != null) {
                for (var child in nodes) {
                  nodeSpans.addAll(processNode(child, currentStyle));
                }
              } else {
                // Fallback: extract text directly
                final linkText = ((node as dynamic).text as String?)?.trim() ?? '';
                if (linkText.isNotEmpty) {
                  nodeSpans.add(TextSpan(
                    text: linkText,
                    style: currentStyle,
                  ));
                }
              }
              return nodeSpans; // Return early, don't process children again
            case 'p':
              // Process paragraph content
              final List<TextSpan> paragraphSpans = [];
              final nodes = (node as dynamic).nodes as List<dynamic>?;
              if (nodes != null) {
                for (var child in nodes) {
                  paragraphSpans.addAll(processNode(child, currentStyle));
                }
              }
              if (paragraphSpans.isNotEmpty) {
                nodeSpans.addAll(paragraphSpans);
                // Add line break after paragraph if not last
                final nextSibling = (node as dynamic).nextElementSibling;
                if (nextSibling != null) {
                  nodeSpans.add(TextSpan(text: '\n\n', style: currentStyle));
                }
              }
              return nodeSpans;
            case 'br':
              nodeSpans.add(TextSpan(text: '\n', style: currentStyle));
              return nodeSpans;
          }
          
          // Process child nodes for other elements
          final nodes = (node as dynamic).nodes as List<dynamic>?;
          if (nodes != null) {
            for (var child in nodes) {
              nodeSpans.addAll(processNode(child, currentStyle));
            }
          }
        } else {
          // It's a text node - check for text property
          final text = (node as dynamic).text as String?;
          if (text != null && (text.trim().isNotEmpty || text.contains('\n'))) {
            // Filter out HTML comment text (shouldn't appear but safety check)
            final trimmedText = text.trim();
            if (!trimmedText.startsWith('<!--') && !trimmedText.endsWith('-->')) {
              nodeSpans.add(TextSpan(
                text: text,
                style: parentStyle ?? baseStyle,
              ));
            }
          }
        }
      } catch (e) {
        // Fallback: try to get text directly
        try {
          final text = (node as dynamic).text as String?;
          if (text != null && text.trim().isNotEmpty) {
            nodeSpans.add(TextSpan(
              text: text,
              style: parentStyle ?? baseStyle,
            ));
          }
        } catch (_) {
          // Ignore errors for unsupported node types
        }
      }
      
      return nodeSpans;
    }
    
    // Process all nodes in the document body
    if (document.body != null) {
      for (var node in document.body!.nodes) {
        spans.addAll(processNode(node, null));
      }
    }
    
    // Trim trailing whitespace/newlines from the last span to reduce spacing
    // If trimTrailingWhitespace is true (buttons follow), aggressively remove all trailing whitespace
    if (spans.isNotEmpty) {
      if (trimTrailingWhitespace) {
        // Aggressively remove all trailing whitespace/newlines when buttons follow
        while (spans.isNotEmpty) {
          final lastSpan = spans.last;
          if (lastSpan.text != null && lastSpan.text!.trim().isEmpty) {
            spans.removeLast();
          } else {
            break;
          }
        }
        
        // Trim trailing whitespace from the last non-empty span
        if (spans.isNotEmpty) {
          final lastSpan = spans.last;
          if (lastSpan.text != null && lastSpan.text!.isNotEmpty) {
            final trimmedText = lastSpan.text!.replaceAll(RegExp(r'\s+$'), '');
            if (trimmedText != lastSpan.text) {
              spans[spans.length - 1] = TextSpan(
                text: trimmedText,
                style: lastSpan.style,
                recognizer: lastSpan.recognizer,
                children: lastSpan.children,
              );
            }
          }
        }
      } else {
        // Normal trimming - preserve website spacing
        final lastSpan = spans.last;
        if (lastSpan.text != null && lastSpan.text!.trim().isEmpty) {
          // Remove trailing whitespace-only span
          spans.removeLast();
        } else if (lastSpan.text != null && lastSpan.text!.endsWith('\n\n')) {
          // Trim trailing double newlines
          spans[spans.length - 1] = TextSpan(
            text: lastSpan.text!.replaceAll(RegExp(r'\n+$'), ''),
            style: lastSpan.style,
            recognizer: lastSpan.recognizer,
            children: lastSpan.children,
          );
        } else if (lastSpan.text != null && lastSpan.text!.endsWith('\n')) {
          // Trim trailing single newline
          spans[spans.length - 1] = TextSpan(
            text: lastSpan.text!.replaceAll(RegExp(r'\n+$'), ''),
            style: lastSpan.style,
            recognizer: lastSpan.recognizer,
            children: lastSpan.children,
          );
        }
      }
    }
    
    return spans;
  }

  /// Applies link matching to formatted TextSpans, making link text clickable while preserving formatting
  List<TextSpan> _applyLinksToFormattedSpans(List<TextSpan> formattedSpans, List<NewsLink> links, Color accentColor) {
    if (links.isEmpty) return formattedSpans;
    
    // Helper to extract plain text from a span (recursive)
    String extractText(TextSpan span) {
      if (span.text != null) return span.text!;
      if (span.children != null) {
        return span.children!.map((child) {
          if (child is TextSpan) return extractText(child);
          return '';
        }).join('');
      }
      return '';
    }
    
    // Build a flat list of text segments with their spans and positions
    final List<({TextSpan span, String text, int start, int end})> segments = [];
    int currentPos = 0;
    
    void addSegment(TextSpan span) {
      String text = extractText(span);
      if (text.isNotEmpty) {
        segments.add((span: span, text: text, start: currentPos, end: currentPos + text.length));
        currentPos += text.length;
      }
    }
    
    for (var span in formattedSpans) {
      addSegment(span);
    }
    
    String fullText = segments.map((s) => s.text).join('');
    
    // Find link matches
    final sortedLinks = List<NewsLink>.from(links)..sort((a, b) => b.text.length.compareTo(a.text.length));
    final List<_LinkMatch> matches = [];
    
    for (var link in sortedLinks) {
      int index = fullText.indexOf(link.text);
      while (index != -1) {
        matches.add(_LinkMatch(start: index, end: index + link.text.length, link: link));
        index = fullText.indexOf(link.text, index + 1);
      }
    }
    
    matches.sort((a, b) => a.start.compareTo(b.start));
    
    // Remove overlapping matches
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
    
    if (nonOverlappingMatches.isEmpty) return formattedSpans;
    
    // Rebuild spans with links inserted
    final List<TextSpan> result = [];
    
    // Process all segments and matches together
    int segmentIndex = 0;
    int matchIndex = 0;
    
    while (segmentIndex < segments.length || matchIndex < nonOverlappingMatches.length) {
      // Find next event (either end of segment or start/end of match)
      bool hasNextSegment = segmentIndex < segments.length;
      bool hasNextMatch = matchIndex < nonOverlappingMatches.length;
      
      if (!hasNextSegment && !hasNextMatch) break;
      
      int nextSegmentEnd = hasNextSegment ? segments[segmentIndex].end : 999999999;
      int nextMatchStart = hasNextMatch ? nonOverlappingMatches[matchIndex].start : 999999999;
      
      // Add text before next match or segment end
      if (nextMatchStart < nextSegmentEnd) {
        // Match comes first - add text before match, then the link
        if (nextMatchStart > currentPos) {
          // Add text from current position to match start
          _addTextSpansBetween(result, segments, currentPos, nextMatchStart);
        }
        
        // Add the link span
        final match = nonOverlappingMatches[matchIndex];
        _addLinkSpanAtPosition(result, segments, match.start, match.end, match.link, accentColor);
        
        currentPos = match.end;
        matchIndex++;
      } else {
        // Segment ends first - add remaining text in segment
        if (nextSegmentEnd > currentPos) {
          _addTextSpansBetween(result, segments, currentPos, nextSegmentEnd);
          currentPos = nextSegmentEnd;
        }
        segmentIndex++;
      }
    }
    
    return result.isEmpty ? formattedSpans : result;
  }
  
  /// Adds text spans between two positions, preserving formatting
  void _addTextSpansBetween(List<TextSpan> result, List<({TextSpan span, String text, int start, int end})> segments, int startPos, int endPos) {
    for (var segment in segments) {
      if (segment.end <= startPos) continue;
      if (segment.start >= endPos) break;
      
      int segmentStart = segment.start > startPos ? segment.start : startPos;
      int segmentEnd = segment.end < endPos ? segment.end : endPos;
      
      if (segmentStart < segmentEnd) {
        int textStart = segmentStart - segment.start;
        int textEnd = segmentEnd - segment.start;
        
        if (textStart == 0 && textEnd == segment.text.length) {
          // Use entire segment
          result.add(segment.span);
        } else {
          // Use portion of segment
          result.add(_createTextSpanFromSegment(segment.span, segment.text, textStart, textEnd));
        }
      }
    }
  }
  
  /// Adds a link span at a specific position, preserving formatting from the underlying segment
  void _addLinkSpanAtPosition(List<TextSpan> result, List<({TextSpan span, String text, int start, int end})> segments, int startPos, int endPos, NewsLink link, Color accentColor) {
    // Find the segment(s) that contain this link
    for (var segment in segments) {
      if (segment.end <= startPos) continue;
      if (segment.start >= endPos) break;
      
      int linkStartInSegment = startPos - segment.start;
      int linkEndInSegment = endPos - segment.start;
      
      if (linkStartInSegment >= 0 && linkEndInSegment <= segment.text.length) {
        TextSpan linkSpan = _createLinkSpanFromSegment(
          segment.span,
          segment.text,
          linkStartInSegment,
          linkEndInSegment,
          link,
          accentColor,
        );
        result.add(linkSpan);
        break; // Link should be in one segment
      }
    }
  }
  
  /// Creates a TextSpan from a portion of a segment, preserving formatting
  TextSpan _createTextSpanFromSegment(TextSpan originalSpan, String segmentText, int start, int end) {
    if (start >= end || start < 0 || end > segmentText.length) {
      return TextSpan(text: '');
    }
    
    String text = segmentText.substring(start, end);
    
    // If original span has children, we need to preserve that structure
    // For simplicity, create a new span with the same style
    return TextSpan(
      text: text,
      style: originalSpan.style,
    );
  }
  
  /// Creates a clickable link span from a portion of a segment, preserving formatting
  TextSpan _createLinkSpanFromSegment(TextSpan originalSpan, String segmentText, int start, int end, NewsLink link, Color accentColor) {
    if (start >= end || start < 0 || end > segmentText.length) {
      return TextSpan(text: '');
    }
    
    String linkText = segmentText.substring(start, end);
    
    // Create recognizer for the link
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        HapticService.light();
        _openLink(link.url);
      };
    
    // Preserve original formatting but add accent color and recognizer
    final linkStyle = originalSpan.style?.copyWith(color: accentColor) ?? TextStyle(color: accentColor);
    
    return TextSpan(
      text: linkText,
      style: linkStyle,
      recognizer: recognizer,
    );
  }

  /// Builds a RichText widget with formatted HTML content and clickable links
  Widget _buildContentFromHtml(String? htmlContent, String? plainContent, List<NewsLink> links, BuildContext context, ThemeData theme, Color accentColor, {bool trimTrailingWhitespace = false}) {
    // Strategy: Parse HTML for formatting, then apply link matching to formatted spans
    // This preserves both HTML formatting (bold/italic) AND makes embedded links clickable
    
    if (htmlContent != null && htmlContent.isNotEmpty) {
      // Parse HTML for formatting (skips <a> tags, just extracts text)
      final formattedSpans = _parseHtmlToTextSpans(htmlContent, theme, accentColor, links, trimTrailingWhitespace: trimTrailingWhitespace);
      
      if (formattedSpans.isNotEmpty) {
        // Apply link matching to formatted spans (preserves formatting, adds clickability)
        final spansWithLinks = links.isNotEmpty 
            ? _applyLinksToFormattedSpans(formattedSpans, links, accentColor)
            : formattedSpans;
        
        // Base text style for RichText
        final baseStyle = theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          letterSpacing: 0.2,
        );
        return RichText(
          text: TextSpan(
            style: baseStyle,
            children: spansWithLinks,
          ),
        );
      }
    }
    
    // Fallback to plain text with links if HTML parsing fails
    return _buildContentWithLinks(plainContent ?? '', links, context, theme, accentColor, trimTrailingWhitespace: trimTrailingWhitespace);
  }

  /// Builds a RichText widget with clickable embedded links from the content
  Widget _buildContentWithLinks(String content, List<NewsLink> links, BuildContext context, ThemeData theme, Color accentColor, {bool trimTrailingWhitespace = false}) {
    // Trim trailing whitespace if buttons will follow
    if (trimTrailingWhitespace) {
      content = content.replaceAll(RegExp(r'\s+$'), '');
    }
    
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

    // Build TextSpans with clickable links
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
      var remainingText = content.substring(currentIndex);
      // Trim trailing whitespace if buttons will follow
      if (trimTrailingWhitespace) {
        remainingText = remainingText.replaceAll(RegExp(r'\s+$'), '');
      }
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            letterSpacing: 0.2,
          ),
        ));
      }
    }
    
    // Trim trailing whitespace from last span if buttons will follow
    if (trimTrailingWhitespace && spans.isNotEmpty) {
      final lastSpan = spans.last;
      if (lastSpan.text != null && lastSpan.text!.isNotEmpty) {
        final trimmedText = lastSpan.text!.replaceAll(RegExp(r'\s+$'), '');
        if (trimmedText != lastSpan.text && trimmedText.isNotEmpty) {
          spans[spans.length - 1] = TextSpan(
            text: trimmedText,
            style: lastSpan.style,
            recognizer: lastSpan.recognizer,
            children: lastSpan.children,
          );
        } else if (trimmedText.isEmpty) {
          spans.removeLast();
        }
      }
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
    
    // Base text style for RichText
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.8,
      letterSpacing: 0.2,
    );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  /// Build link button widget
  Widget _buildLinkButton(NewsLink link, BuildContext context, ThemeData theme, Color accentColor, Color surfaceColor) {
    // Extract domain from URL for display
    String displayText = link.text;
    try {
      final uri = Uri.parse(link.url);
      // If link text is just a URL, show a cleaner version
      if (link.text == link.url || link.text.startsWith('http')) {
        displayText = uri.host.replaceFirst('www.', '');
        if (uri.path.isNotEmpty && uri.path != '/') {
          displayText += uri.path.length > 30 
              ? '${uri.path.substring(0, 30)}...' 
              : uri.path;
        }
      }
    } catch (e) {
      // Keep original text if URL parsing fails
    }

    return Container(
      margin: EdgeInsets.zero,
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
          onTap: () {
            HapticService.medium();
            _openLink(link.url);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Favicon or link icon with accent color outline
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: Image.network(
                      _getFaviconUrl(link.url),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to link icon if favicon fails to load
                        return Icon(
                          Icons.link,
                          color: accentColor,
                          size: 40,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        // Show link icon while loading favicon
                        return Icon(
                          Icons.link,
                          color: accentColor,
                          size: 40,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Link info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDomainFromUrl(link.url),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // External link icon
                Icon(
                  Icons.open_in_new,
                  color: accentColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Extract domain from URL for display
  String _getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url.length > 50 ? '${url.substring(0, 50)}...' : url;
    }
  }

  /// Get favicon URL for a domain using Google's favicon service
  String _getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.replaceFirst('www.', '');
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } catch (e) {
      return '';
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
                        
                        // Full content with embedded links and formatting
                        if ((event.htmlContent != null && event.htmlContent!.isNotEmpty) || 
                            (event.content != null && event.content!.isNotEmpty)) ...[
                          _buildContentFromHtml(
                            event.htmlContent,
                            event.content,
                            event.links,
                            context,
                            theme,
                            accentColor,
                            trimTrailingWhitespace: event.standaloneLinksOrEmpty.isNotEmpty || event.downloads.isNotEmpty,
                          ),
                          
                          // Display standalone link buttons if available
                          if (event.standaloneLinksOrEmpty.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ...event.standaloneLinksOrEmpty.asMap().entries.map((entry) {
                              final index = entry.key;
                              final link = entry.value;
                              return Column(
                                children: [
                                  _buildLinkButton(
                                    link,
                                    context,
                                    theme,
                                    accentColor,
                                    surfaceColor,
                                  ),
                                  if (index < event.standaloneLinksOrEmpty.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ],
                          
                          // Display download buttons if available
                          if (event.downloads.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ...event.downloads.asMap().entries.map((entry) {
                              final index = entry.key;
                              final download = entry.value;
                              return Column(
                                children: [
                                  _buildDownloadButton(
                                    download,
                                    context,
                                    theme,
                                    accentColor,
                                    surfaceColor,
                                  ),
                                  if (index < event.downloads.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ],
                          
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
                                      height: 1.8,
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

