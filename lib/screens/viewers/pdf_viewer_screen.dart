import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/services/haptic_service.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../../utils/app_logger.dart';

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

class _PDFViewerScreenState extends State<PDFViewerScreen>
    with TickerProviderStateMixin {
  late final pdfx.PdfController _pdfController;
  final GlobalKey _shareButtonKey = GlobalKey(); // Key for share button position
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  
  // Search bar state
  bool _isSearchBarVisible = false;
  bool _canDismissSearchBar = false;
  
  // PDF loading state
  bool _isPdfReady = false;
  bool _hasJumpedToSavedPage = false;
  
  // Class input modal state
  bool _showClassModal = false;
  final TextEditingController _classInputController = TextEditingController();
  bool _isValidatingClass = false;
  bool _showClassNotFoundError = false;
  bool _showClassSuccessFlash = false;
  
  // Button animation state
  late AnimationController _buttonColorController;
  late Animation<Color?> _buttonColorAnimation;
  late AnimationController _successColorController;
  late Animation<Color?> _successColorAnimation;
  static const Duration _buttonAnimationDuration = Duration(milliseconds: 300);
  static const Color _errorRedColor = Colors.red;
  static const Color _successGreenColor = Colors.green;
  
  // Timer for retry mechanism (to prevent memory leaks)
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    
    // Setup button color animation
    _buttonColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );
    
    // Setup success color animation
    _successColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );
    
    // Initialize animation - will be updated in didChangeDependencies with actual theme color
    _buttonColorAnimation = ColorTween(
      begin: Colors.blue, // Temporary, will be updated
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize success animation - will be updated in didChangeDependencies with actual theme color
    _successColorAnimation = ColorTween(
      begin: Colors.blue, // Temporary, will be updated
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to text changes to enable/disable save button and clear errors
    _classInputController.addListener(() {
      if (_showClassNotFoundError) {
        setState(() {
          _showClassNotFoundError = false;
        });
        _buttonColorController.reverse();
      }
      if (_showClassSuccessFlash) {
        setState(() {
          _showClassSuccessFlash = false;
        });
        _successColorController.reset();
      }
      setState(() {});
    });
    
    // Allow all orientations for PDF viewing (landscape is useful for documents)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Check if this is a 5-10 schedule and if class needs to be set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowClassModal();
    });
    
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
              content: Text(AppLocalizations.of(context)!.foundPages(widget.targetPages!.join(", "))),
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
  
  void _checkAndShowClassModal() {
    final dayLabel = widget.dayName ?? '';
    final isSchedule5to10 = dayLabel.contains('Klassen') || dayLabel.contains('Grades');
    
    if (isSchedule5to10) {
      final container = ProviderScope.containerOf(context, listen: false);
      final prefsState = container.read(preferencesManagerProvider);
      final currentClass = prefsState.lastScheduleQuery5to10;
      
      if (currentClass == null || currentClass.trim().isEmpty) {
        setState(() {
          _showClassModal = true;
        });
      }
    }
  }
  
  Future<void> _validateAndSaveClass() async {
    final classInput = _classInputController.text.trim();
    if (classInput.isEmpty || _isValidatingClass) return;
    
    // Haptic feedback for save button press
    HapticService.medium();
    
    // Start loading state
    setState(() {
      _isValidatingClass = true;
      _showClassNotFoundError = false;
    });
    
    // Validate class exists in PDF
    final classExists = await _checkClassExistsInPdf(classInput);
    
    if (!mounted) return;
    
    if (!classExists) {
      // Class not found - show error
      setState(() {
        _isValidatingClass = false;
        _showClassNotFoundError = true;
      });
      
      // Animate button to red
      _buttonColorController.forward();
      
      
      // Reset button color after delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _buttonColorController.reverse();
        }
      });
      
      return;
    }
    
    // Class found - show success flash immediately
    setState(() {
      _isValidatingClass = false;
      _showClassSuccessFlash = true;
      _showClassNotFoundError = false;
    });
    
    // Start success animation with smooth fade
    _successColorController.forward();
    
    
    if (!mounted) return;
    
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(preferencesManagerProvider.notifier).setLastScheduleQuery5to10(classInput);
    
    // Hold the green color briefly
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;
    
    setState(() {
      _showClassModal = false;
      _showClassSuccessFlash = false;
    });
    
    // Reset success animation
    _successColorController.reset();
    
    // Wait for PDF to be ready before performing search
    await _waitForPdfReady();
    
    if (!mounted) return;
    
    // Perform search with the entered class (will show success message if found)
    _onSearchSubmitted(classInput);
  }
  
  Future<bool> _checkClassExistsInPdf(String className) async {
    try {
      final bytes = await widget.pdfFile.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      final textExtractor = syncfusion.PdfTextExtractor(document);
      final allText = textExtractor.extractText(
        startPageIndex: 0,
        endPageIndex: pageCount - 1,
      );
      
      document.dispose();
      
      // Check if class name exists in PDF (case-insensitive)
      return allText.toLowerCase().contains(className.toLowerCase());
    } catch (e) {
      AppLogger.debug('Error checking class in PDF: $e', module: 'PDFViewer');
      // If validation fails, allow saving anyway (fail gracefully)
      return true;
    }
  }
  
  /// Wait for PDF to be ready for navigation, with a timeout
  Future<void> _waitForPdfReady() async {
    // If PDF is already ready, return immediately
    if (_isPdfReady) {
      // Small delay to ensure UI has updated after modal close
      await Future.delayed(const Duration(milliseconds: 50));
      return;
    }
    
    // Wait for PDF to be ready with a timeout
    const maxWaitTime = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 50);
    final startTime = DateTime.now();
    
    while (!_isPdfReady && mounted) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        // Timeout reached - proceed anyway (PDF might be ready but flag not set)
        AppLogger.debug('PDF ready check timeout, proceeding with search', module: 'PDFViewer');
        break;
      }
      await Future.delayed(checkInterval);
    }
    
    // Small delay to ensure UI has updated after modal close
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  bool get _canSaveClass {
    return _classInputController.text.trim().isNotEmpty && 
           !_isValidatingClass && 
           !_showClassNotFoundError;
  }
  
  Color get _currentButtonColor {
    if (_showClassSuccessFlash) {
      return _successColorAnimation.value ?? _successGreenColor;
    }
    
    if (_showClassNotFoundError) {
      return _buttonColorAnimation.value ?? _errorRedColor;
    }
    
    if (_canSaveClass) {
      return Theme.of(context).colorScheme.primary;
    }
    
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Update button color animation with actual theme color
    _buttonColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primary,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));
    
    // Update success color animation with actual theme color
    _successColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primary,
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _pdfController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _classInputController.dispose();
    _buttonColorController.dispose();
    _successColorController.dispose();
    // Restore portrait-only orientation when leaving PDF viewer
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
      final isSchedule5to10 = dayLabel.contains('Klassen') || dayLabel.contains('Grades');

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
      AppLogger.debug('Error detecting saved page: $e', module: 'PDFViewer');
    }
  }

  /// Try to jump to a specific page
  void _tryJumpToPage(int pageNumber, {int attemptNumber = 1}) {
    try {
      _pdfController.jumpToPage(pageNumber - 1); // Convert to 0-based index
      _hasJumpedToSavedPage = true;
      AppLogger.pdf('Navigated to page $pageNumber in "${widget.dayName}" (attempt $attemptNumber)');
    } catch (e) {
      // Don't log failure here - let the retry mechanism handle final failure logging
      AppLogger.debug('Jump to page failed: $e', module: 'PDFViewer');
    }
  }

  /// Set up retry mechanism for page jumping using a Timer to prevent memory leaks
  void _setupRetryMechanism(int pageNumber) {
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 200);

    // Cancel any existing timer
    _retryTimer?.cancel();

    _retryTimer = Timer.periodic(retryDelay, (timer) {
      if (!mounted || _hasJumpedToSavedPage || retryCount >= maxRetries) {
        timer.cancel();
        if (retryCount >= maxRetries && !_hasJumpedToSavedPage) {
          AppLogger.warning('Failed to jump to page $pageNumber after $maxRetries attempts', module: 'PDFViewer');
        }
        return;
      }

      retryCount++;
      _tryJumpToPage(pageNumber, attemptNumber: retryCount);
    });
  }

  // Search functionality
  Future<void> _searchInPdf(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

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
          AppLogger.debug('Error extracting text from page $pageIndex: $e', module: 'PDFViewer');
          continue;
        }
      }

      document.dispose();

      setState(() {
        _searchResults = results;
      });

      AppLogger.search('Search completed: ${results.length} results for "$query"');

      if (results.isNotEmpty) {

        // Automatically navigate to the first result
        if (results.isNotEmpty) {
          AppLogger.search('Auto-navigating to first result: page ${results.first.pageNumber}');
          _navigateToSearchResult(results.first);
        }
        
        // Show success message
        if (mounted) {
          final firstQuery = results.first.query;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                results.length == 1
                    ? AppLocalizations.of(context)!.singleResultFound(firstQuery)
                    : AppLocalizations.of(context)!.multipleResultsFound(results.length),
              ),
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
              content: Text(AppLocalizations.of(context)!.noResultsFound(query)),
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
        final prefsNotifier = container.read(preferencesManagerProvider.notifier);
        // Store per schedule type only; ignore substitution plans
        final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen') || (widget.dayName ?? '').contains('Grades');
        if (isSchedule5to10) {
          unawaited(prefsNotifier.setLastScheduleQuery5to10(result.query));
          unawaited(prefsNotifier.setLastSchedulePage5to10(result.pageNumber));
        }
        // J11/J12 schedules no longer use page persistence
      } catch (e) {
        AppLogger.debug('Error saving search result: $e', module: 'PDFViewer');
      }
    } catch (e) {
      if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text(AppLocalizations.of(context)!.errorNavigatingToPage(result.pageNumber.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showSearchBar() {
    setState(() {
      _isSearchBarVisible = true;
      _canDismissSearchBar = false; // Prevent immediate dismissal
    });
    
    // Enable dismissal after a delay to prevent immediate close
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isSearchBarVisible) {
        setState(() {
          _canDismissSearchBar = true;
        });
      }
    });
    
    // Focus the search field after the widget is built to open keyboard
    // Use multiple callbacks for better reliability on iPad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // First attempt after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isSearchBarVisible) {
            _requestSearchFocus();
          }
        });
        
        // Retry after a longer delay for iPad (which may need more time)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isSearchBarVisible && !_searchFocusNode.hasFocus) {
            _requestSearchFocus();
          }
        });
      }
    });
  }
  
  void _requestSearchFocus() {
    if (!mounted || !_isSearchBarVisible) return;
    
    // Check if focus node is attached before requesting focus
    if (_searchFocusNode.canRequestFocus) {
      _searchFocusNode.requestFocus();
      
      // Set cursor position to end of text after focus is granted
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _searchFocusNode.hasFocus) {
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        }
      });
    }
  }

  void _hideSearchBar() {
    if (!_canDismissSearchBar) return; // Prevent dismissal if not ready
    
    setState(() {
      _isSearchBarVisible = false;
      _canDismissSearchBar = false;
      _searchResults.clear();
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
        final prefsNotifier = container.read(preferencesManagerProvider.notifier);
        final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen') || (widget.dayName ?? '').contains('Grades');
        final isScheduleJ11J12 = (widget.dayName ?? '').contains('J11/J12');
        if (isSchedule5to10) {
          unawaited(prefsNotifier.setLastScheduleQuery5to10(query.trim()));
        } else if (isScheduleJ11J12) {
          unawaited(prefsNotifier.setLastScheduleQueryJ11J12(query.trim()));
        }
      } catch (e) {
        AppLogger.debug('Error saving search query: $e', module: 'PDFViewer');
      }
    }
  }

  Future<void> _sharePdf() async {
    // Capture localization before async operations to avoid BuildContext usage across async gaps
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    // Check mounted again after async operation
    if (!mounted) return;
    
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
          fileName = '${l10n.filenameSchedulePrefix}$cleanName.pdf';
          subject = l10n.subjectSchedule;
        } else {
          // This is a substitution plan
          final dayFormatted = widget.dayName!.toLowerCase();
          fileName = '${l10n.filenameSubstitutionPrefix}$dayFormatted.pdf';
          subject = l10n.subjectSubstitution;
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

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
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
            content: Text('${AppLocalizations.of(context)!.shareError}: ${e.toString()}'),
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

    if (_showClassModal) {
      return _buildClassInputModal(context);
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            HapticService.light();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Search functionality - only show for schedules, not substitution plans
          if (isSchedule) ...[
            if (!_isSearchBarVisible) ...[
              // Show search icon when search bar is not visible
              IconButton(
                onPressed: _showSearchBar,
                icon: const Icon(
                  Icons.search,
                  color: AppColors.secondaryText,
                ),
                tooltip: _searchResults.isEmpty 
                    ? AppLocalizations.of(context)!.searchInPdf
                    : AppLocalizations.of(context)!.newSearch,
              ),
            ] else ...[
              // Close button when search bar is visible
              IconButton(
                onPressed: _hideSearchBar,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.secondaryText,
                ),
                tooltip: AppLocalizations.of(context)!.cancelSearch,
              ),
            ],
          ],
          IconButton(
            key: _shareButtonKey, // Add key for position calculation
            onPressed: () {
              HapticService.light();
              _sharePdf();
            },
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.secondaryText,
            ),
            tooltip: AppLocalizations.of(context)!.sharePdf,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF viewer - takes full space
          pdfx.PdfView(
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
          // Search bar overlay - only show for schedules
          if (isSchedule)
            AnimatedOpacity(
              opacity: _isSearchBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: IgnorePointer(
                ignoring: !_isSearchBarVisible,
                child: Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(3),
                          ],
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchHint,
                            prefixIcon: const Icon(Icons.school, color: AppColors.secondaryText),
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
                          onTapOutside: (event) {
                            if (_canDismissSearchBar) {
                              _hideSearchBar();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final query = _searchController.text.trim();
                          if (query.isNotEmpty) {
                            HapticService.light();
                            _onSearchSubmitted(query);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.check, size: 20),
                      ),
                      ],
                    ),
                  ),
                ),
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
  
  Widget _buildClassInputModal(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primaryText,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.setClassTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.setClassMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryText,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _classInputController,
                autofocus: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchHint,
                  prefixIcon: const Icon(Icons.school, color: AppColors.secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _showClassNotFoundError 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _showClassNotFoundError 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.appSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryText,
                    ),
                onSubmitted: (_) {
                  if (_canSaveClass) {
                    _validateAndSaveClass();
                  }
                },
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _buttonColorAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: Stack(
                      children: [
                        // Animated background button
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: _buttonAnimationDuration,
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: _currentButtonColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        // Clickable transparent button with always-white text
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: InkWell(
                            onTap: _canSaveClass ? _validateAndSaveClass : null,
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Center(
                              child: _isValidatingClass
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        strokeCap: StrokeCap.round,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.setClassButton,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 