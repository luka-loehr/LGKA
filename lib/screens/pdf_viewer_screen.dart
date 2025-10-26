import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:lgka_flutter/providers/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  int _currentSearchIndex = -1;
  
  // Search bar state
  bool _isSearchBarVisible = false;
  
  // PDF loading state
  bool _isPdfReady = false;
  bool _hasJumpedToSavedPage = false;

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
              content: Text('Found pages: ${widget.targetPages!.join(", ")}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      });
    }
    
    // Initialize PDF ready detection
    _initializePdfReadyDetection();
  }
  
  @override
  void dispose() {
    _pdfController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Initialize PDF ready detection and attempt to jump to saved page
  void _initializePdfReadyDetection() {
    // Try to jump to saved page after a short delay to allow PDF to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptJumpToSavedPage();
    });
  }

  /// Attempt to jump to saved page when PDF is ready
  void _attemptJumpToSavedPage() {
    if (_hasJumpedToSavedPage) return; // Already jumped
    
    try {
      // Access preferences via ProviderScope context
      final container = ProviderScope.containerOf(context, listen: false);
      final prefs = container.read(preferencesManagerProvider);

      // Determine schedule type based on dayName labeling used in UI
      final dayLabel = (widget.dayName ?? '');
      final isSchedule5to10 = dayLabel.contains('Klassen');
      final isScheduleJ11J12 = dayLabel.contains('J11/J12');
      final isSubstitution = !isSchedule5to10 && !isScheduleJ11J12; // everything else

      // Only run jumper for Klassen 5–10
      if (!isSchedule5to10) {
        // keep logs quiet to avoid noise for other PDFs
        return;
      }

      int? lastPage;
      if (isSchedule5to10) {
        lastPage = prefs.lastSchedulePage5to10;
      }

      if ((widget.targetPages == null || widget.targetPages!.isEmpty) && 
          lastPage != null && lastPage > 0) {
        
        // Try to jump immediately first
        _tryJumpToPage(lastPage);
        
        // If that fails, set up a retry mechanism
        if (!_hasJumpedToSavedPage) {
          _setupRetryMechanism(lastPage);
        }
      }
    } catch (e) {
      // Error in saved page detection
    }
  }

  /// Try to jump to a specific page
  void _tryJumpToPage(int pageNumber) {
    try {
      _pdfController.jumpToPage(pageNumber - 1); // Convert to 0-based index
      _hasJumpedToSavedPage = true;
      AppLogger.pdf('Navigated to page $pageNumber in "${widget.dayName}"');
    } catch (e) {
      AppLogger.warning('Failed to jump to page $pageNumber', module: 'PDFViewer');
    }
  }

  /// Set up retry mechanism for page jumping
  void _setupRetryMechanism(int pageNumber) {
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 200);

    void retry() {
      if (_hasJumpedToSavedPage || retryCount >= maxRetries) return;
      
      retryCount++;
      
      Future.delayed(retryDelay, () {
        if (mounted && !_hasJumpedToSavedPage) {
          _tryJumpToPage(pageNumber);
          
          if (!_hasJumpedToSavedPage && retryCount < maxRetries) {
            retry(); // Continue retrying
          }
        }
      });
    }
    
    retry();
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

    // Show loading state
    setState(() {
      _currentSearchIndex = -1;
    });

    try {
      final bytes = await widget.pdfFile.readAsBytes();
      
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      final results = <SearchResult>[];

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        try {
          final textExtractor = syncfusion.PdfTextExtractor(document);
          final pageText = textExtractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );

          if (pageText.toLowerCase().contains(query.toLowerCase())) {
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
          // Skip pages with extraction errors
          continue;
        }
      }

      document.dispose();

      setState(() {
        _searchResults = results;
        _currentSearchIndex = results.isNotEmpty ? 0 : -1;
      });

      AppLogger.search('Search completed: ${results.length} results for "$query"');

      if (results.isNotEmpty) {
        HapticService.subtle();

        // Automatically navigate to the first result
        if (results.isNotEmpty) {
          AppLogger.search('Auto-navigating to first result: page ${results.first.pageNumber}');
          _navigateToSearchResult(results.first);
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(results.length == 1 
                ? '1 result found' 
                : '${results.length} results found'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show a message when no results are found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No results found'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${AppLocalizations.of(context)!.errorLoadingGeneric}: $e'),
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
      // Persist last successful search result
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final prefs = container.read(preferencesManagerProvider);
        // Store per schedule type only; ignore substitution plans
        final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen');
        if (isSchedule5to10) {
          prefs.setLastScheduleQuery5to10(result.query);
          prefs.setLastSchedulePage5to10(result.pageNumber);
        }
        // J11/J12 schedules no longer use page persistence
      } catch (_) {}
      
      // Provide haptic feedback
      HapticService.subtle();
      

    } catch (e) {
      if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text('Error navigating to page ${result.pageNumber}'),
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

  void _showSearchBar() {
    setState(() {
      _isSearchBarVisible = true;
    });
    
    // Focus the search field after the widget is built to open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Use a small delay to ensure the TextField is fully rendered
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            // Request focus using the dedicated focus node
            _searchFocusNode.requestFocus();
            
            // Set cursor position to end of text
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }
        });
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
      // Optimistically store query; page will be stored on navigation
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final prefs = container.read(preferencesManagerProvider);
        final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen');
        final isScheduleJ11J12 = (widget.dayName ?? '').contains('J11/J12');
        if (isSchedule5to10) {
          prefs.setLastScheduleQuery5to10(query.trim());
        } else if (isScheduleJ11J12) {
          prefs.setLastScheduleQueryJ11J12(query.trim());
        }
      } catch (_) {}
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
          fileName = '${AppLocalizations.of(context)!.filenameSchedulePrefix}$cleanName.pdf';
          subject = AppLocalizations.of(context)!.subjectSchedule;
        } else {
          // This is a substitution plan
          final dayFormatted = widget.dayName!.toLowerCase();
          fileName = '${AppLocalizations.of(context)!.filenameSubstitutionPrefix}$dayFormatted.pdf';
          subject = AppLocalizations.of(context)!.subjectSubstitution;
        }
      } else {
        fileName = 'LGKA_Document.pdf';
        subject = 'LGKA+ Document';
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
    // Determine the appropriate header based on the dayName
    String headerTitle;
    bool isSchedule = false;
    if (widget.dayName != null && widget.dayName!.isNotEmpty) {
      // Check if this is a schedule (supports German and English labels)
      final dn = widget.dayName!;
      isSchedule = dn.contains('Klassen') || dn.contains('Grades') || dn.contains('J11/J12');
      if (isSchedule) {
        // Always show generic schedule title
        headerTitle = AppLocalizations.of(context)!.scheduleTitle;
      } else {
        // Substitution plan - use the localized day name as provided
        headerTitle = dn;
      }
    } else {
      // Fallback to default
      headerTitle = AppLocalizations.of(context)!.documentTitle;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          headerTitle,
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
          // Search functionality - only show for schedules, not substitution plans
          if (isSchedule) ...[
            if (_searchResults.isEmpty && !_isSearchBarVisible) ...[
              IconButton(
                onPressed: _showSearchBar,
                icon: const Icon(
                  Icons.search,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.searchInPdf,
              ),
            ] else if (_isSearchBarVisible) ...[
              // Clear search when search bar is visible
              IconButton(
                onPressed: _hideSearchBar,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.cancelSearch,
              ),
            ] else if (_searchResults.isNotEmpty) ...[
              // Search navigation
              IconButton(
                onPressed: _previousSearchResult,
                icon: const Icon(
                  Icons.arrow_upward,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.previousResult,
              ),
              IconButton(
                onPressed: _nextSearchResult,
                icon: const Icon(
                  Icons.arrow_downward,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.nextResult,
              ),
              IconButton(
                onPressed: _showSearchBar,
                icon: const Icon(
                  Icons.search,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.newSearch,
              ),
            ],
          ],
          IconButton(
            key: _shareButtonKey, // Add key for position calculation
            onPressed: _sharePdf,
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.secondaryText,
            ),
            tooltip: AppLocalizations.of(context)!.sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Expandable search bar below app bar - only show for schedules
          if (_isSearchBarVisible && isSchedule) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.appSurface.withValues(alpha: 0.95),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.appBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primaryText,
                      ),
                      onSubmitted: _onSearchSubmitted,
                      onTapOutside: (event) => _hideSearchBar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _hideSearchBar,
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    tooltip: 'Suche abbrechen',
                  ),
                ],
              ),
            ),
          ],
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
    // Mark PDF as ready when first page is being built
    if (!_isPdfReady) {
      _isPdfReady = true;
      
      // Try to jump to saved page now that PDF is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasJumpedToSavedPage) {
          _attemptJumpToSavedPage();
        }
      });

      // Trigger haptic feedback when PDF is loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasTriggeredLoadedHaptic) {
          _hasTriggeredLoadedHaptic = true;
          HapticService.pdfLoading();
        }
      });
    }

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