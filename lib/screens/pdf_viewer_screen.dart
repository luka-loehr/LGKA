import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:lgka_flutter/providers/haptic_service.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

// Search result data class
class SearchResult {
  final int pageNumber;
  final String context;
  final String query;
  final int matchIndex;

  SearchResult({
    required this.pageNumber,
    required this.context,
    required this.query,
    required this.matchIndex,
  });
}

class PDFViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String? dayName; // Optional day name for filename
  final List<int>? targetPages; // Optional target pages for direct navigation

  const PDFViewerScreen({
    super.key, 
    required this.pdfFile, 
    this.dayName,
    this.targetPages,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late final pdfx.PdfController _pdfController;
  bool _hasTriggeredLoadedHaptic = false;
  final GlobalKey _shareButtonKey = GlobalKey(); // Key for share button position
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  int _currentSearchIndex = -1;
  
  // Search bar state
  bool _isSearchBarVisible = false;

  @override
  void initState() {
    super.initState();
    _pdfController = pdfx.PdfController(
      document: pdfx.PdfDocument.openFile(widget.pdfFile.path),
    );
    
    // Navigate to target page if provided
    if (widget.targetPages != null && widget.targetPages!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetPage = widget.targetPages!.first;
        _pdfController.jumpToPage(targetPage - 1); // Convert to 0-based index
        
        // Show snackbar with found pages
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gefundene Seiten: ${widget.targetPages!.join(", ")}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      });
    }
    
    // Trigger haptic feedback after a short delay to indicate PDF is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasTriggeredLoadedHaptic) {
          _hasTriggeredLoadedHaptic = true;
          HapticService.pdfLoading();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _pdfController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Search functionality
  Future<void> _searchInPdf(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
      });
      return;
    }

    print('🔍 [PDFViewer] Starting search for: "$query"');
    
    // Show loading state
    setState(() {
      _currentSearchIndex = -1;
    });

    try {
      final bytes = await widget.pdfFile.readAsBytes();
      print('🔍 [PDFViewer] PDF file size: ${bytes.length} bytes');
      
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      print('🔍 [PDFViewer] Searching ${pageCount} pages for "$query"');
      
      final results = <SearchResult>[];

      // Show progress to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durchsuche ${pageCount} Seiten nach "$query"...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        try {
          final textExtractor = syncfusion.PdfTextExtractor(document);
          final pageText = textExtractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );

          if (pageText.toLowerCase().contains(query.toLowerCase())) {
            print('🔍 [PDFViewer] Found match on page ${pageIndex + 2}');
            
            // Find all occurrences on this page
            final lowerText = pageText.toLowerCase();
            final lowerQuery = query.toLowerCase();
            int startIndex = 0;
            
            while (true) {
              final index = lowerText.indexOf(lowerQuery, startIndex);
              if (index == -1) break;
              
              // Get context around the match
              final contextStart = (index - 20).clamp(0, pageText.length);
              final contextEnd = (index + query.length + 20).clamp(0, pageText.length);
              final context = pageText.substring(contextStart, contextEnd);
              
              results.add(SearchResult(
                pageNumber: pageIndex + 2, // +2 instead of +1 to fix the offset
                context: context,
                query: query,
                matchIndex: index - contextStart,
              ));
              
              startIndex = index + 1;
            }
          }
        } catch (e) {
          print('🔍 [PDFViewer] Error processing page ${pageIndex + 1}: $e');
          // Skip pages with extraction errors
          continue;
        }
      }

      document.dispose();
      print('🔍 [PDFViewer] Search completed: ${results.length} results found');

      setState(() {
        _searchResults = results;
        _currentSearchIndex = results.isNotEmpty ? 0 : -1;
      });

      if (results.isNotEmpty) {
        HapticService.subtle();
        
        // Automatically navigate to the first result
        if (results.isNotEmpty) {
          print('🔍 [PDFViewer] Auto-navigating to first result: page ${results.first.pageNumber}');
          _navigateToSearchResult(results.first);
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${results.length} Ergebnisse für "$query" gefunden - springe zu Seite ${results.first.pageNumber}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show a message when no results are found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Keine Ergebnisse für "$query" in allen ${pageCount} Seiten gefunden'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('🔍 [PDFViewer] Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Suchen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSearchResult(SearchResult result) {
    try {
      // Navigate to the page (convert to 0-based index)
      _pdfController.jumpToPage(result.pageNumber - 1);
      
      // Provide haptic feedback
      HapticService.subtle();
      
      // Show a brief message indicating the navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seite ${result.pageNumber} - "${result.query}" gefunden'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      
      print('🔍 [PDFViewer] Navigated to page ${result.pageNumber}');
    } catch (e) {
      print('🔍 [PDFViewer] Error navigating to page ${result.pageNumber}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Navigieren zu Seite ${result.pageNumber}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextSearchResult() {
    if (_searchResults.isNotEmpty && _currentSearchIndex < _searchResults.length - 1) {
      setState(() {
        _currentSearchIndex++;
      });
      _navigateToSearchResult(_searchResults[_currentSearchIndex]);
    }
  }

  void _previousSearchResult() {
    if (_searchResults.isNotEmpty && _currentSearchIndex > 0) {
      setState(() {
        _currentSearchIndex--;
      });
      _navigateToSearchResult(_searchResults[_currentSearchIndex]);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _currentSearchIndex = -1;
      _isSearchBarVisible = false;
    });
  }

  void _showSearchBar() {
    setState(() {
      _isSearchBarVisible = true;
    });
    // Focus the search field after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      }
    });
  }

  void _hideSearchBar() {
    setState(() {
      _isSearchBarVisible = false;
      _searchResults.clear();
      _currentSearchIndex = -1;
    });
    _searchController.clear();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _searchInPdf(query);
      setState(() {
        _isSearchBarVisible = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    // Subtle haptic feedback when share button is pressed
    await HapticService.subtle();
    
    try {
      // Create a nice filename for sharing
      String fileName;
      String subject;
      
      if (widget.dayName != null && widget.dayName!.isNotEmpty) {
        // Check if this is a schedule (contains "Klassen" or "J11/J12")
        if (widget.dayName!.contains('Klassen') || widget.dayName!.contains('J11/J12')) {
          // This is a schedule PDF
          final cleanName = widget.dayName!
              .replaceAll('Klassen ', '')
              .replaceAll('J11/J12', 'J11-12')
              .replaceAll(' - ', '_')
              .replaceAll(' ', '');
          fileName = 'LGKA_Stundenplan_$cleanName.pdf';
          subject = 'LGKA+ Stundenplan';
        } else {
          // This is a substitution plan
          final dayFormatted = widget.dayName!.toLowerCase();
          fileName = 'LGKA_Vertretungsplan_$dayFormatted.pdf';
          subject = 'LGKA+ Vertretungsplan';
        }
      } else {
        fileName = 'LGKA_Dokument.pdf';
        subject = 'LGKA+ Dokument';
      }

      // Create a temporary file with the nice name for sharing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await widget.pdfFile.copy(tempFile.path);

      // Calculate share button position for iPad popover positioning
      Rect? sharePositionOrigin;
      if (Platform.isIOS) {
        final RenderBox? renderBox = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          sharePositionOrigin = Rect.fromLTWH(
            position.dx,
            position.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        }
      }

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // No success message needed - users can see the sharing worked themselves
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Teilen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchBarVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Suchbegriff eingeben...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.7),
                  ),
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                onSubmitted: _onSearchSubmitted,
                onTapOutside: (event) => _hideSearchBar(),
              )
            : Text(
                'Stundenplan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
              ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        // Override the back button to add haptic feedback
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primaryText,
          onPressed: () {
            HapticService.subtle(); // Add haptic feedback
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Search functionality
          if (_searchResults.isEmpty && !_isSearchBarVisible) ...[
            IconButton(
              onPressed: _showSearchBar,
              icon: const Icon(
                Icons.search,
                color: AppColors.secondaryText,
              ),
              tooltip: 'Im PDF suchen',
            ),
          ] else if (_isSearchBarVisible) ...[
            // Clear search when search bar is visible
            IconButton(
              onPressed: _hideSearchBar,
              icon: const Icon(
                Icons.close,
                color: AppColors.secondaryText,
              ),
              tooltip: 'Suche abbrechen',
            ),
          ] else if (_searchResults.isNotEmpty) ...[
            // Search navigation
            IconButton(
              onPressed: _previousSearchResult,
              icon: const Icon(
                Icons.arrow_upward,
                color: AppColors.secondaryText,
              ),
              tooltip: 'Vorheriges Ergebnis',
            ),
            IconButton(
              onPressed: _nextSearchResult,
              icon: const Icon(
                Icons.arrow_downward,
                color: AppColors.secondaryText,
              ),
              tooltip: 'Nächstes Ergebnis',
            ),
            IconButton(
              onPressed: _showSearchBar,
              icon: const Icon(
                Icons.search,
                color: AppColors.secondaryText,
              ),
              tooltip: 'Neue Suche',
            ),
          ],
          IconButton(
            key: _shareButtonKey, // Add key for position calculation
            onPressed: _sharePdf,
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.secondaryText,
            ),
            tooltip: 'PDF teilen',
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF viewer
          Expanded(
            child: pdfx.PdfView(
              controller: _pdfController,
              builders: pdfx.PdfViewBuilders<pdfx.DefaultBuilderOptions>(
                options: const pdfx.DefaultBuilderOptions(
                  loaderSwitchDuration: Duration.zero, // Remove animation duration
                  transitionBuilder: _noTransition, // Use instant transition
                ),
                documentLoaderBuilder: (_) => const SizedBox.shrink(), // Remove document loading spinner
                pageLoaderBuilder: (_) => const SizedBox.shrink(), // Remove page loading spinner
                errorBuilder: (_, error) => Center(child: Text(error.toString())),
                pageBuilder: _pageBuilder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PhotoViewGalleryPageOptions _pageBuilder(
    BuildContext context,
    Future<pdfx.PdfPageImage> pageImage,
    int index,
    pdfx.PdfDocument document,
  ) {
    return PhotoViewGalleryPageOptions(
      imageProvider: pdfx.PdfPageImageProvider(
        pageImage,
        index,
        document.id,
      ),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
    );
  }

  // Custom transition that removes all animations
  static Widget _noTransition(Widget child, Animation<double> animation) {
    return child; // Return the widget directly without any animation
  }
} 