import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../data/pdf_repository.dart';
import '../providers/haptic_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isTodayLoading = false;
  bool _isTomorrowLoading = false;
  bool _showInfoSheet = false;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.fastOutSlowIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastOutSlowIn,
    ));

    // Preload PDFs when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPdfs();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _refreshPdfs() async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.preloadPdfs(forceReload: true);
  }

  void _showInfo() {
    setState(() => _showInfoSheet = true);
    _fadeController.forward();
    _slideController.forward();
    HapticService.subtle();
  }

  void _hideInfo() {
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() => _showInfoSheet = false);
        }
      });
    });
  }

  Future<void> _openPdf(String filename, bool isToday) async {
    setState(() {
      if (isToday) {
        _isTodayLoading = true;
      } else {
        _isTomorrowLoading = true;
      }
      _error = null;
    });

    try {
      final pdfRepo = ref.read(pdfRepositoryProvider);
      
      // Check for cached file first
      var file = await pdfRepo.getCachedPdf(filename);
      
      // If no cached file or empty, download it
      if (file == null || file.lengthSync() == 0) {
        final url = isToday ? PdfRepository.todayUrl : PdfRepository.tomorrowUrl;
        file = await pdfRepo.downloadPdf(url, filename);
      }

      if (file != null) {
        await OpenFilex.open(file.path);
        await HapticService.success();
      } else {
        setState(() => _error = 'Fehler beim Herunterladen der PDF-Datei');
        await HapticService.error();
      }
    } catch (e) {
      setState(() => _error = 'Fehler: ${e.toString()}');
      await HapticService.error();
    } finally {
      setState(() {
        if (isToday) {
          _isTodayLoading = false;
        } else {
          _isTomorrowLoading = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'Vertretungsplan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Loading indicator
              if (_isTodayLoading || _isTomorrowLoading || !pdfRepo.weekdaysLoaded)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
                  height: 5,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.appBlueAccent.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.appBlueAccent),
                  ),
                ),

              // PDF Options
              if (!_isTodayLoading && !_isTomorrowLoading && pdfRepo.weekdaysLoaded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        
                        _PlanOptions(
                          todayWeekday: pdfRepo.todayWeekday,
                          tomorrowWeekday: pdfRepo.tomorrowWeekday,
                          isTodayLoading: _isTodayLoading,
                          isTomorrowLoading: _isTomorrowLoading,
                          onTodayClick: () => _openPdf(PdfRepository.todayFilename, true),
                          onTomorrowClick: () => _openPdf(PdfRepository.tomorrowFilename, false),
                        ),
                        
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: const Color(0xFF442727),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFCF6679),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Info sheet overlay
          if (_showInfoSheet) ...[
            // Semi-transparent background
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _hideInfo,
                  child: Container(
                    color: Colors.black.withValues(alpha: _fadeAnimation.value),
                  ),
                );
              },
            ),

            // Info sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _slideAnimation.value.dy * MediaQuery.of(context).size.height,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 100),
                      decoration: const BoxDecoration(
                        color: AppColors.appSurface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: _InfoSheetContent(
                        todayPdfTimestamp: pdfRepo.todayLastUpdated,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanOptions extends StatelessWidget {
  final String todayWeekday;
  final String tomorrowWeekday;
  final bool isTodayLoading;
  final bool isTomorrowLoading;
  final VoidCallback onTodayClick;
  final VoidCallback onTomorrowClick;

  const _PlanOptions({
    required this.todayWeekday,
    required this.tomorrowWeekday,
    required this.isTodayLoading,
    required this.isTomorrowLoading,
    required this.onTodayClick,
    required this.onTomorrowClick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlanOptionButton(
          title: todayWeekday,
          icon: Icons.calendar_today,
          isLoading: isTodayLoading,
          enabled: !isTodayLoading && !isTomorrowLoading,
          onClick: onTodayClick,
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          title: tomorrowWeekday,
          icon: Icons.calendar_today,
          isLoading: isTomorrowLoading,
          enabled: !isTodayLoading && !isTomorrowLoading,
          onClick: onTomorrowClick,
        ),
      ],
    );
  }
}

class _PlanOptionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onClick;

  const _PlanOptionButton({
    required this.title,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.onClick,
  });

  @override
  State<_PlanOptionButton> createState() => _PlanOptionButtonState();
}

class _PlanOptionButtonState extends State<_PlanOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
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
    return GestureDetector(
      onTapDown: widget.enabled ? (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      } : null,
      onTapUp: widget.enabled ? (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onClick();
        HapticService.subtle();
      } : null,
      onTapCancel: widget.enabled ? () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      } : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.calendarIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.appOnSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoSheetContent extends StatelessWidget {
  final String todayPdfTimestamp;

  const _InfoSheetContent({
    required this.todayPdfTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Über die App',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.appOnSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'LGKA – Lessing Gymnasium Karlsruhe App',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Einfacher Zugriff auf den Vertretungsplan des Lessing Gymnasiums Karlsruhe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          
          if (todayPdfTimestamp.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Stand des Vertretungsplans: $todayPdfTimestamp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          Text(
            'Entwickler: Luka Löhr',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '© 2025 Alle Rechte vorbehalten',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Divider(color: AppColors.secondaryText.withValues(alpha: 0.2)),
          
          const SizedBox(height: 16),
          
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data!.version : '1.1';
                return Text(
                  'Version $version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 