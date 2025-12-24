// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/substitution_provider.dart';
import '../../services/haptic_service.dart';
import '../../navigation/app_router.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_footer.dart';
import '../../l10n/app_localizations.dart';
import '../../services/substitution_service.dart';

/// Substitution plan screen with today and tomorrow options
class SubstitutionScreen extends ConsumerStatefulWidget {
  const SubstitutionScreen({super.key});

  @override
  ConsumerState<SubstitutionScreen> createState() => _SubstitutionScreenState();
}

class _SubstitutionScreenState extends ConsumerState<SubstitutionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasShownButtons = false;
  bool _wasLoading = true;
  bool _hadDataPreviously = false;
  bool _hapticScheduled = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startButtonAnimation() {
    if (!_hasShownButtons) {
      _hasShownButtons = true;
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final substitutionState = ref.watch(substitutionProvider);
    final isLoading = substitutionState.isLoading || !substitutionState.isInitialized;
    final isError = substitutionState.hasAnyError && !substitutionState.hasAnyData;
    final hasData = substitutionState.hasAnyData;
    
    // Trigger haptic when transitioning from loading to success (when spinner disappears)
    // Only trigger if we didn't have data previously (real load, not cache check)
    // Use a flag to ensure it only fires once even if build is called multiple times rapidly
    if (_wasLoading && !isLoading && !isError && hasData && !_hadDataPreviously && !_hapticScheduled) {
      _hapticScheduled = true;
      
      // Log successful load
      final availableCount = (substitutionState.todayState.canDisplay ? 1 : 0) + 
                            (substitutionState.tomorrowState.canDisplay ? 1 : 0);
      AppLogger.success('Substitution plan load complete: $availableCount available', module: 'SubstitutionPage');
      
      Future.microtask(() {
        if (mounted) {
          HapticService.medium();
        }
      });
    }
    
    // Reset flag when loading starts again or error occurs
    if (isLoading || isError) {
      _hapticScheduled = false;
    }
    
    // Track state for next build
    _wasLoading = isLoading;
    _hadDataPreviously = hasData;
    
    if (!substitutionState.isInitialized || substitutionState.isLoading) {
      return _LoadingView();
    }

    if (substitutionState.hasAnyError && !substitutionState.hasAnyData) {
      return _ErrorView(
        onRetry: () {
          ref.read(substitutionProvider.notifier).retryAll();
        },
      );
    }

    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Log when buttons are shown (before setting flag)
      final availableCount = (substitutionState.todayState.canDisplay ? 1 : 0) + 
                            (substitutionState.tomorrowState.canDisplay ? 1 : 0);
      if (availableCount > 0 && !_hasShownButtons) {
        AppLogger.schedule('Substitution buttons shown: $availableCount available');
      }
      
      _startButtonAnimation();
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Plan options with proper fade-in animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPlanOptions(substitutionState, ref),
          ),
          
          const Spacer(),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildPlanOptions(SubstitutionProviderState substitutionState, WidgetRef ref) {
    return Column(
      children: [
        _PlanOptionButton(
          pdfState: substitutionState.todayState,
          label: AppLocalizations.of(context)!.today,
          onTap: () => _openPdf(substitutionState, ref, true),
          onRetry: () {
            ref.read(substitutionProvider.notifier).retryPdf(true);
          },
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          pdfState: substitutionState.tomorrowState,
          label: AppLocalizations.of(context)!.tomorrow,
          onTap: () => _openPdf(substitutionState, ref, false),
          onRetry: () {
            ref.read(substitutionProvider.notifier).retryPdf(false);
          },
        ),
      ],
    );
  }

  void _openPdf(SubstitutionProviderState substitutionState, WidgetRef ref, bool isToday) {
    final substitutionNotifier = ref.read(substitutionProvider.notifier);
    if (!substitutionNotifier.canOpenPdf(isToday)) return;

    // Get the PDF file and actual weekday from the substitution state
    final pdfFile = substitutionNotifier.getPdfFile(isToday);
    final pdfState = isToday ? substitutionState.todayState : substitutionState.tomorrowState;
    String weekday = pdfState.weekday ?? (isToday ? AppLocalizations.of(context)!.today : AppLocalizations.of(context)!.tomorrow);
    // Translate German weekdays to English for display when locale is English
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'en') {
      const Map<String, String> germanToEnglishWeekday = {
        'Montag': 'Monday',
        'Dienstag': 'Tuesday',
        'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday',
        'Freitag': 'Friday',
        'Samstag': 'Saturday',
        'Sonntag': 'Sunday',
      };
      if (germanToEnglishWeekday.containsKey(weekday)) {
        weekday = germanToEnglishWeekday[weekday]!;
      }
    }

    AppLogger.pdf('Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');

    if (pdfFile != null) {
      // Navigate to PDF viewer screen
      context.push(AppRouter.pdfViewer, extra: {
        'file': pdfFile,
        'dayName': weekday,
      });
    }
  }

  Widget _buildFooter(BuildContext context) {
    return AppFooter(bottomPadding: _getFooterPadding(context));
  }

  double _getFooterPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;
    
    // Determine navigation mode based on gesture insets
    if (gestureInsets >= 45) {
      return 34.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      // Ambiguous range - use viewPadding as secondary indicator
      return viewPadding > 50 ? 34.0 : 8.0;
    }
  }
}

/// Loading view while PDFs are being initialized
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingSubstitutions,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Error view when all PDFs fail to load
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.serverConnectionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticService.light();
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual plan option button
class _PlanOptionButton extends ConsumerStatefulWidget {
  final SubstitutionState pdfState;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _PlanOptionButton({
    required this.pdfState,
    required this.label,
    required this.onTap,
    required this.onRetry,
  });

  @override
  ConsumerState<_PlanOptionButton> createState() => _PlanOptionButtonState();
}

class _PlanOptionButtonState extends ConsumerState<_PlanOptionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.pdfState.canDisplay;
    final hasError = widget.pdfState.error != null;
    final isLoading = widget.pdfState.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _onTapDown(),
      onTapUp: isDisabled ? null : (_) => _onTapUp(),
      onTapCancel: isDisabled ? null : () => _onTapCancel(),
      onTap: isDisabled ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDisabled),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _getBoxShadow(isDisabled),
              ),
              child: Row(
                children: [
                  _buildIcon(isDisabled),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildContent(isDisabled, hasError, isLoading),
                  ),
                  if (hasError) _buildRetryButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.appSurface.withValues(alpha: 0.5);
    }
    if (_isPressed) {
      return AppColors.appSurface.withValues(alpha: 0.8);
    }
    return AppColors.appSurface;
  }

  List<BoxShadow> _getBoxShadow(bool isDisabled) {
    if (_isPressed || isDisabled) return [];
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildIcon(bool isDisabled) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDisabled 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.calendar_today,
        color: isDisabled ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildContent(bool isDisabled, bool hasError, bool isLoading) {
    String weekday = widget.pdfState.weekday ?? '';
    final date = widget.pdfState.date ?? '';
    
    String displayText;
    if (hasError) {
      displayText = AppLocalizations.of(context)!.errorLoading;
    } else if (weekday.isEmpty || weekday == 'weekend') {
      displayText = AppLocalizations.of(context)!.noInfoYet;
    } else {
      // Translate German weekday names to English for display if needed
      final localeCode = Localizations.localeOf(context).languageCode;
      if (localeCode == 'en') {
        const Map<String, String> germanToEnglishWeekday = {
          'Montag': 'Monday',
          'Dienstag': 'Tuesday',
          'Mittwoch': 'Wednesday',
          'Donnerstag': 'Thursday',
          'Freitag': 'Friday',
          'Samstag': 'Saturday',
          'Sonntag': 'Sunday',
        };
        if (germanToEnglishWeekday.containsKey(weekday)) {
          weekday = germanToEnglishWeekday[weekday]!;
        }
      }
      displayText = weekday;
    }

    return Row(
      children: [
        Text(
          displayText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDisabled 
                ? AppColors.appOnSurface.withValues(alpha: 0.5)
                : AppColors.appOnSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (date.isNotEmpty && !isDisabled) ...[
          const SizedBox(width: 8),
          Text(
            date,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton() {
    return IconButton(
      onPressed: widget.onRetry,
      icon: Icon(
        Icons.refresh,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    if (widget.pdfState.error != null) {
      HapticService.medium();
      widget.onRetry();
    } else {
      HapticService.medium();
      widget.onTap();
    }
  }
}
