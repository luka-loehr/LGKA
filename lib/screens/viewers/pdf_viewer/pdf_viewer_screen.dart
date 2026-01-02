import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/schedule_provider.dart';
import '../../../services/haptic_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/floating_toast.dart';
import 'models/search_result.dart';
import 'services/pdf_search_service.dart';
import 'services/pdf_share_service.dart';
import 'widgets/class_input_modal.dart';
import 'widgets/pdf_search_bar.dart';

/// A screen for viewing PDF documents with search and share functionality.
class PDFViewerScreen extends StatefulWidget {
  /// The PDF file to display.
  final File pdfFile;

  /// Optional day name for filename when sharing.
  final String? dayName;

  /// Optional target pages for direct navigation.
  final List<int>? targetPages;

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
  // PDF controller
  late final pdfx.PdfController _pdfController;
  final GlobalKey _shareButtonKey = GlobalKey();

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
  final FocusNode _classInputFocusNode = FocusNode();
  bool _isValidatingClass = false;
  bool _showClassNotFoundError = false;
  bool _showClassSuccessFlash = false;

  // Button animation controllers
  late AnimationController _buttonColorController;
  late Animation<Color?> _buttonColorAnimation;
  late AnimationController _successColorController;
  late Animation<Color?> _successColorAnimation;

  static const Duration _buttonAnimationDuration = Duration(milliseconds: 300);
  static const Color _errorRedColor = Colors.red;
  static const Color _successGreenColor = Colors.green;

  // Timer for retry mechanism
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextControllerListener();
    _enableLandscapeOrientation();
    _initializePdfController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowClassModal();
    });
  }

  void _initializeAnimations() {
    _buttonColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    _successColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    // Add listeners to trigger rebuilds when animations change
    _buttonColorController.addListener(_onAnimationTick);
    _successColorController.addListener(_onAnimationTick);

    // Initialize with placeholder colors (updated in didChangeDependencies)
    _buttonColorAnimation = ColorTween(
      begin: Colors.blue,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

    _successColorAnimation = ColorTween(
      begin: Colors.blue,
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
  }

  void _onAnimationTick() {
    if (mounted) setState(() {});
  }

  void _setupTextControllerListener() {
    _classInputController.addListener(() {
      if (_showClassNotFoundError) {
        setState(() => _showClassNotFoundError = false);
        _buttonColorController.reverse();
      }
      if (_showClassSuccessFlash) {
        setState(() => _showClassSuccessFlash = false);
        _successColorController.reverse();
      }
      setState(() {});
    });
  }

  void _enableLandscapeOrientation() {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
  }

  void _initializePdfController() {
    _pdfController = pdfx.PdfController(
      document: pdfx.PdfDocument.openFile(widget.pdfFile.path),
    );

    // Navigate to target page if provided
    if (widget.targetPages != null && widget.targetPages!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetPage = widget.targetPages!.first;
        _pdfController.jumpToPage(targetPage - 1);

        if (mounted) {
          FloatingToast.show(
            context,
            message: AppLocalizations.of(context)!
                .foundPages(widget.targetPages!.join(", ")),
            duration: const Duration(seconds: 3),
          );
        }
      });
    }

    _initializePdfReadyDetection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _buttonColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primary,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

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
    _classInputFocusNode.dispose();
    _buttonColorController.removeListener(_onAnimationTick);
    _successColorController.removeListener(_onAnimationTick);
    _buttonColorController.dispose();
    _successColorController.dispose();

    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}

    super.dispose();
  }

  // ============================================================================
  // Class Modal Methods
  // ============================================================================

  void _checkAndShowClassModal() {
    final dayLabel = widget.dayName ?? '';
    final isSchedule5to10 =
        dayLabel.contains('Klassen') || dayLabel.contains('Grades');

    if (isSchedule5to10) {
      final container = ProviderScope.containerOf(context, listen: false);
      final prefsState = container.read(preferencesManagerProvider);
      final currentClass = prefsState.lastScheduleQuery5to10;

      if (currentClass == null || currentClass.trim().isEmpty) {
        setState(() => _showClassModal = true);
      }
    }
  }

  Future<void> _validateAndSaveClass() async {
    final classInput = _classInputController.text.trim();
    if (classInput.isEmpty || _isValidatingClass) return;

    HapticService.medium();

    final container = ProviderScope.containerOf(context, listen: false);
    final scheduleState = container.read(scheduleProvider);
    final scheduleNotifier = container.read(scheduleProvider.notifier);

    // Check class index for instant validation
    if (scheduleState.isIndexBuilt &&
        !scheduleState.classIndex5to10.containsKey(classInput.toLowerCase())) {
      _showInstantError();
      return;
    }

    final pageFromIndex = scheduleNotifier.getClassPage(classInput);

    // If we already know the class exists (from index), show success immediately
    if (pageFromIndex != null) {
      setState(() {
        _isValidatingClass = true;
        _showClassNotFoundError = false;
        _showClassSuccessFlash = true;
      });
      _successColorController.forward();

      // Wait 1 second while showing green loading
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      await _handleSuccessfulValidation(classInput, pageFromIndex, container, skipAnimation: true);
      return;
    }

    // Otherwise, validate via PDF search
    setState(() {
      _isValidatingClass = true;
      _showClassNotFoundError = false;
    });

    // Validate with minimum loading time
    final results = await Future.wait([
      PdfSearchService.checkQueryExistsInPdf(widget.pdfFile, classInput),
      Future.delayed(const Duration(seconds: 1)),
    ]);
    final classExists = results[0] as bool;

    if (!mounted) return;

    if (!classExists) {
      _showValidationError();
      return;
    }

    await _handleSuccessfulValidation(classInput, pageFromIndex, container);
  }

  void _showInstantError() {
    setState(() => _showClassNotFoundError = true);
    _buttonColorController.forward();

    // Re-request focus to keep keyboard open
    _classInputFocusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _buttonColorController.reverse().then((_) {
          if (mounted) setState(() => _showClassNotFoundError = false);
        });
      }
    });
  }

  void _showValidationError() {
    setState(() {
      _isValidatingClass = false;
      _showClassNotFoundError = true;
    });

    _buttonColorController.forward();

    // Re-request focus to keep keyboard open
    _classInputFocusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _buttonColorController.reverse().then((_) {
          if (mounted) setState(() => _showClassNotFoundError = false);
        });
      }
    });
  }

  Future<void> _handleSuccessfulValidation(
    String classInput,
    int? pageFromIndex,
    ProviderContainer container, {
    bool skipAnimation = false,
  }) async {
    // If not coming from instant success path, start the animation now
    if (!skipAnimation) {
      setState(() {
        _showClassSuccessFlash = true;
        _showClassNotFoundError = false;
        // Keep _isValidatingClass = true to show loading spinner
      });

      _successColorController.forward();

      // Keep loading spinner visible for 1 second while button is green
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    await container
        .read(preferencesManagerProvider.notifier)
        .setLastScheduleQuery5to10(classInput);

    if (!mounted) return;

    setState(() {
      _isValidatingClass = false; // Now stop loading
      _showClassModal = false;
      _showClassSuccessFlash = false;
    });

    _successColorController.reset();

    await _waitForPdfReady();

    if (!mounted) return;

    if (pageFromIndex != null) {
      _pdfController.jumpToPage(pageFromIndex - 1);
      await container
          .read(preferencesManagerProvider.notifier)
          .setLastSchedulePage5to10(pageFromIndex);

      if (mounted) {
        FloatingToast.show(
          context,
          message:
              AppLocalizations.of(context)!.singleResultFound(classInput),
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      _onSearchSubmitted(classInput);
    }
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
    if (_isValidatingClass) {
      return Theme.of(context).colorScheme.primary;
    }
    if (_canSaveClass) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
  }

  // ============================================================================
  // PDF Navigation Methods
  // ============================================================================

  void _initializePdfReadyDetection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptJumpToSavedPage();
    });
  }

  void _attemptJumpToSavedPage() {
    if (_hasJumpedToSavedPage) return;

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final prefs = container.read(preferencesManagerProvider);
      final dayLabel = widget.dayName ?? '';
      final isSchedule5to10 =
          dayLabel.contains('Klassen') || dayLabel.contains('Grades');

      if (!isSchedule5to10) return;

      final lastPage = prefs.lastSchedulePage5to10;

      if ((widget.targetPages == null || widget.targetPages!.isEmpty) &&
          lastPage != null &&
          lastPage > 0) {
        _tryJumpToPage(lastPage, silent: true);

        if (!_hasJumpedToSavedPage) {
          _setupRetryMechanism(lastPage);
        }
      }
    } catch (e) {
      AppLogger.debug('Error detecting saved page: $e', module: 'PDFViewer');
    }
  }

  void _tryJumpToPage(int pageNumber, {int attemptNumber = 1, bool silent = false}) {
    try {
      _pdfController.jumpToPage(pageNumber - 1);
      _hasJumpedToSavedPage = true;
      AppLogger.pdf(
          'Navigated to page $pageNumber in "${widget.dayName}" (attempt $attemptNumber)');
    } catch (e) {
      if (!silent) {
        AppLogger.debug('Jump to page failed: $e', module: 'PDFViewer');
      }
    }
  }

  void _setupRetryMechanism(int pageNumber) {
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 200);

    _retryTimer?.cancel();

    _retryTimer = Timer.periodic(retryDelay, (timer) {
      if (!mounted || _hasJumpedToSavedPage || retryCount >= maxRetries) {
        timer.cancel();
        if (retryCount >= maxRetries && !_hasJumpedToSavedPage) {
          AppLogger.warning(
              'Failed to jump to page $pageNumber after $maxRetries attempts',
              module: 'PDFViewer');
        }
        return;
      }

      retryCount++;
      _tryJumpToPage(pageNumber, attemptNumber: retryCount, silent: true);
    });
  }

  Future<void> _waitForPdfReady() async {
    if (_isPdfReady) {
      await Future.delayed(const Duration(milliseconds: 50));
      return;
    }

    const maxWaitTime = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 50);
    final startTime = DateTime.now();

    while (!_isPdfReady && mounted) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        AppLogger.debug('PDF ready check timeout, proceeding with search',
            module: 'PDFViewer');
        break;
      }
      await Future.delayed(checkInterval);
    }

    await Future.delayed(const Duration(milliseconds: 50));
  }

  // ============================================================================
  // Search Methods
  // ============================================================================

  Future<void> _searchInPdf(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    try {
      final results = await PdfSearchService.searchInPdf(widget.pdfFile, query);

      setState(() => _searchResults = results);

      if (results.isNotEmpty) {
        AppLogger.search(
            'Auto-navigating to first result: page ${results.first.pageNumber}');
        _navigateToSearchResult(results.first);

        if (mounted) {
          FloatingToast.show(
            context,
            message: results.length == 1
                ? AppLocalizations.of(context)!
                    .singleResultFound(results.first.query)
                : AppLocalizations.of(context)!
                    .multipleResultsFound(results.length),
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        if (mounted) {
          FloatingToast.show(
            context,
            message: AppLocalizations.of(context)!
                .noResultsFound(query.trim().toUpperCase()),
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        FloatingToast.show(
          context,
          message: '${AppLocalizations.of(context)!.errorLoadingGeneric}: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _navigateToSearchResult(SearchResult result) {
    try {
      _pdfController.jumpToPage(result.pageNumber - 1);

      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final prefsNotifier =
            container.read(preferencesManagerProvider.notifier);
        final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen') ||
            (widget.dayName ?? '').contains('Grades');

        if (isSchedule5to10) {
          unawaited(prefsNotifier.setLastScheduleQuery5to10(result.query));
          unawaited(prefsNotifier.setLastSchedulePage5to10(result.pageNumber));
        }
      } catch (e) {
        AppLogger.debug('Error saving search result: $e', module: 'PDFViewer');
      }
    } catch (e) {
      if (mounted) {
        FloatingToast.show(
          context,
          message: AppLocalizations.of(context)!
              .errorNavigatingToPage(result.pageNumber.toString()),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showSearchBar() {
    setState(() {
      _isSearchBarVisible = true;
      _canDismissSearchBar = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isSearchBarVisible) {
        setState(() => _canDismissSearchBar = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isSearchBarVisible) {
            _requestSearchFocus();
          }
        });

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

    if (_searchFocusNode.canRequestFocus) {
      _searchFocusNode.requestFocus();

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
    if (!_canDismissSearchBar) return;

    // Unfocus to dismiss keyboard
    _searchFocusNode.unfocus();

    setState(() {
      _isSearchBarVisible = false;
      _canDismissSearchBar = false;
      _searchResults.clear();
    });
    _searchController.clear();
  }

  void _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim().toLowerCase();
    final container = ProviderScope.containerOf(context, listen: false);
    final isSchedule5to10 = (widget.dayName ?? '').contains('Klassen') ||
        (widget.dayName ?? '').contains('Grades');
    final isScheduleJ11J12 = (widget.dayName ?? '').contains('J11/J12');

    if (isSchedule5to10) {
      await _handleSchedule5to10Search(trimmedQuery, container);
      return;
    }

    // For other schedules (J11/J12), use normal search
    _searchInPdf(query);
    setState(() => _isSearchBarVisible = false);

    try {
      final prefsNotifier =
          container.read(preferencesManagerProvider.notifier);
      if (isScheduleJ11J12) {
        unawaited(prefsNotifier.setLastScheduleQueryJ11J12(query.trim()));
      }
    } catch (e) {
      AppLogger.debug('Error saving search query: $e', module: 'PDFViewer');
    }
  }

  Future<void> _handleSchedule5to10Search(
    String trimmedQuery,
    ProviderContainer container,
  ) async {
    final scheduleState = container.read(scheduleProvider);
    final scheduleNotifier = container.read(scheduleProvider.notifier);
    final prefsState = container.read(preferencesManagerProvider);
    final currentClass = prefsState.lastScheduleQuery5to10?.toLowerCase();

    if (currentClass != null && currentClass == trimmedQuery) {
      setState(() => _isSearchBarVisible = false);

      if (mounted) {
        FloatingToast.show(
          context,
          message: AppLocalizations.of(context)!
              .classAlreadySet(trimmedQuery.toUpperCase()),
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (scheduleState.isIndexBuilt &&
        scheduleState.classIndex5to10.containsKey(trimmedQuery)) {
      final page = scheduleNotifier.getClassPage(trimmedQuery);
      if (page != null) {
        setState(() => _isSearchBarVisible = false);

        _pdfController.jumpToPage(page - 1);

        final prefsNotifier =
            container.read(preferencesManagerProvider.notifier);
        unawaited(prefsNotifier.setLastSchedulePage5to10(page));
        unawaited(prefsNotifier.setLastScheduleQuery5to10(trimmedQuery));

        if (mounted) {
          FloatingToast.show(
            context,
            message: AppLocalizations.of(context)!
                .classChanged(trimmedQuery.toUpperCase()),
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }
    }

    setState(() => _isSearchBarVisible = false);

    if (mounted) {
      FloatingToast.show(
        context,
        message: AppLocalizations.of(context)!
            .noResultsFound(trimmedQuery.toUpperCase()),
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ============================================================================
  // Share Methods
  // ============================================================================

  Future<void> _sharePdf() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      await PdfShareService.sharePdf(
        pdfFile: widget.pdfFile,
        dayName: widget.dayName,
        shareButtonKey: _shareButtonKey,
        l10n: l10n,
      );
    } catch (e) {
      if (mounted) {
        FloatingToast.show(
          context,
          message: '${AppLocalizations.of(context)!.shareError}: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // ============================================================================
  // Build Methods
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final headerTitle = _getHeaderTitle();
    final isSchedule5to10 = _isSchedule5to10();

    if (_showClassModal) {
      return ClassInputModal(
        controller: _classInputController,
        focusNode: _classInputFocusNode,
        isValidating: _isValidatingClass,
        canSave: _canSaveClass,
        buttonColor: _currentButtonColor,
        buttonColorAnimation: _buttonColorAnimation,
        successColorAnimation: _successColorAnimation,
        onSave: _validateAndSaveClass,
        onBack: () => Navigator.of(context).pop(),
        onChanged: (_) => setState(() {}),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(headerTitle, isSchedule5to10),
      body: Stack(
        children: [
          _buildPdfViewer(),
          if (isSchedule5to10) _buildSearchBarOverlay(),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    if (widget.dayName != null && widget.dayName!.isNotEmpty) {
      final dn = widget.dayName!;
      final isSchedule = dn.contains('Klassen') ||
          dn.contains('Grades') ||
          dn.contains('J11/J12');
      if (isSchedule) {
        return AppLocalizations.of(context)!.scheduleTitle;
      }
      return dn;
    }
    return AppLocalizations.of(context)!.documentTitle;
  }

  bool _isSchedule() {
    if (widget.dayName == null || widget.dayName!.isEmpty) return false;
    final dn = widget.dayName!;
    return dn.contains('Klassen') ||
        dn.contains('Grades') ||
        dn.contains('J11/J12');
  }

  bool _isSchedule5to10() {
    if (widget.dayName == null || widget.dayName!.isEmpty) return false;
    final dn = widget.dayName!;
    return dn.contains('Klassen') || dn.contains('Grades');
  }

  AppBar _buildAppBar(String headerTitle, bool isSchedule5to10) {
    return AppBar(
      title: Text(
        headerTitle,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
      ),
      centerTitle: false,
      backgroundColor: AppColors.appBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primaryText),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: AppColors.primaryText,
        onPressed: () {
          HapticService.light();
          Navigator.of(context).pop();
        },
      ),
      actions: [
        if (isSchedule5to10) ...[
          if (!_isSearchBarVisible)
            IconButton(
              onPressed: _showSearchBar,
              icon: const Icon(Icons.search, color: AppColors.secondaryText),
              tooltip: _searchResults.isEmpty
                  ? AppLocalizations.of(context)!.searchInPdf
                  : AppLocalizations.of(context)!.newSearch,
            )
          else
            IconButton(
              onPressed: _hideSearchBar,
              icon: const Icon(Icons.close, color: AppColors.secondaryText),
              tooltip: AppLocalizations.of(context)!.cancelSearch,
            ),
        ],
        IconButton(
          key: _shareButtonKey,
          onPressed: () {
            HapticService.light();
            _sharePdf();
          },
          icon: const Icon(Icons.share_outlined, color: AppColors.secondaryText),
          tooltip: AppLocalizations.of(context)!.sharePdf,
        ),
      ],
    );
  }

  Widget _buildPdfViewer() {
    return pdfx.PdfView(
      controller: _pdfController,
      builders: pdfx.PdfViewBuilders<pdfx.DefaultBuilderOptions>(
        options: pdfx.DefaultBuilderOptions(
          loaderSwitchDuration: const Duration(milliseconds: 200),
          transitionBuilder: _smoothTransition,
        ),
        documentLoaderBuilder: (_) => const SizedBox.shrink(),
        pageLoaderBuilder: (_) => const SizedBox.shrink(),
        errorBuilder: (_, error) => Center(child: Text(error.toString())),
        pageBuilder: _pageBuilder,
      ),
    );
  }

  Widget _buildSearchBarOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: PdfSearchBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        isVisible: _isSearchBarVisible,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  PhotoViewGalleryPageOptions _pageBuilder(
    BuildContext context,
    Future<pdfx.PdfPageImage> pageImage,
    int index,
    pdfx.PdfDocument document,
  ) {
    if (!_isPdfReady) {
      _isPdfReady = true;

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

  static Widget _smoothTransition(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}
