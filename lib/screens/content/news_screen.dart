// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/news_provider.dart';
import '../../providers/haptic_service.dart';
import '../../providers/color_provider.dart';
import '../../services/news_service.dart';
import '../../l10n/app_localizations.dart';
import '../../navigation/app_router.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  bool _hasAnimatedList = false;
  bool _wasNewsLoading = true;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Load news when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsProvider.notifier).loadNews();
      // If events are already loaded (returning to screen), skip animation
      final newsState = ref.read(newsProvider);
      if (newsState.events.isNotEmpty) {
        _hasAnimatedList = true;
        _listAnimationController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsProvider);
    final backgroundColor = AppColors.appBackground;
    final surfaceColor = AppColors.appSurface;
    final primaryTextColor = AppColors.primaryText;
    final secondaryTextColor = AppColors.secondaryText;
    final accentColor = ref.watch(currentColorProvider);

    // Trigger haptic feedback when news finishes loading and data becomes available
    final becameAvailable = _wasNewsLoading && !newsState.isLoading && newsState.events.isNotEmpty;
    if (becameAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await HapticService.light();
      });
    }
    _wasNewsLoading = newsState.isLoading;

    // Trigger list animation once when events become available
    // Only animate if we haven't animated before and events just became available
    if (newsState.events.isNotEmpty && !_hasAnimatedList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasAnimatedList && mounted) {
          _hasAnimatedList = true;
          _listAnimationController.forward(from: 0);
        }
      });
    } else if (newsState.events.isNotEmpty && _hasAnimatedList && _listAnimationController.value < 1.0) {
      // If returning to screen and animation was already played, ensure it's at end state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _listAnimationController.value < 1.0) {
          _listAnimationController.value = 1.0;
        }
      });
    }

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
          onPressed: () async {
            // Provide haptic feedback when navigating back
            await HapticService.light();
            if (context.mounted) {
              context.go(AppRouter.home);
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
      ),
      body: CustomScrollView(
        slivers: [
          if (newsState.isLoading && newsState.events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.loadingNews,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (newsState.hasError && newsState.events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.newspaper_rounded,
                      size: 64,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.errorLoadingNews,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticService.light();
                        ref.read(newsProvider.notifier).refreshNews();
                      },
                      icon: const Icon(Icons.refresh_outlined),
                      label: Text(AppLocalizations.of(context)!.tryAgain),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (newsState.events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(AppLocalizations.of(context)!.noNewsAvailable),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = newsState.events[index];
                    // Create a per-item animation that fades and slightly slides
                    // cards in from top to bottom.
                    final itemCount = newsState.events.length.clamp(1, 50);
                    final startInterval = (index / itemCount) * 0.6;
                    final endInterval = startInterval + 0.4;
                    final animation = CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        startInterval.clamp(0.0, 1.0),
                        endInterval.clamp(0.0, 1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: _NewsCard(
                          event: event,
                          surfaceColor: surfaceColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          accentColor: accentColor,
                        ),
                      ),
                    );
                  },
                  childCount: newsState.events.length,
                ),
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

class _NewsCard extends StatelessWidget {
  final NewsEvent event;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  const _NewsCard({
    required this.event,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
  });

  void _navigateToDetail(BuildContext context) async {
    // Provide haptic feedback when navigating
    await HapticService.light();
    context.push(AppRouter.newsDetail, extra: event);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _navigateToDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                    Icon(
                      Icons.newspaper_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      event.createdDate == 'Unknown'
                          ? AppLocalizations.of(context)!.unknown
                          : event.createdDate,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: secondaryTextColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.views}',
                          style: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: TextStyle(
                      color: secondaryTextColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.author == 'Unknown' 
                                  ? AppLocalizations.of(context)!.unknown
                                  : event.author,
                              style: TextStyle(
                                color: secondaryTextColor.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.learnMore,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: accentColor,
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
    );
  }
}

