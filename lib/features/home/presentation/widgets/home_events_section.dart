import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/haptic_service.dart';
import '../../../../../theme/app_theme.dart';
import '../../../events/application/events_provider.dart';
import '../../../events/domain/event_model.dart';
import 'skeleton_card.dart';

class HomeEventsSection extends ConsumerWidget {
  const HomeEventsSection({super.key, required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsProvider);

    final Widget child;
    final String key;

    if (isRefreshing || eventsState.isLoading) {
      key = 'events-loading';
      child = const Column(
        children: [
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
        ],
      );
    } else if (eventsState.hasError && eventsState.events.isEmpty) {
      key = 'events-error';
      child = _buildEventsError(context, ref);
    } else if (eventsState.events.isEmpty) {
      key = 'events-empty';
      child = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              color: context.appSecondaryText.withValues(alpha: 0.4),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.noEventsAvailable,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.appSecondaryText),
            ),
          ],
        ),
      );
    } else {
      key = 'events-content';
      final displayEvents = eventsState.events.take(4).toList();
      final items = <Widget>[];
      for (final event in displayEvents) {
        items.add(_buildEventCard(context, event));
        items.add(const SizedBox(height: 12));
      }
      if (items.isNotEmpty && items.last is SizedBox) {
        items.removeLast();
      }
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }

    return _fadeSwitch(key, child);
  }

  Widget _buildEventCard(BuildContext context, SchoolEvent event) {
    final primary = Theme.of(context).colorScheme.primary;
    final locale = Localizations.localeOf(context).languageCode;

    final dateLocale = locale == 'de' ? 'de_DE' : 'en_US';
    final weekdayFormat = DateFormat('EEE', dateLocale);
    final dayMonthFormat = DateFormat('d. MMMM', dateLocale);

    final weekday = weekdayFormat.format(event.date);
    final dayMonth = dayMonthFormat.format(event.date);
    final subtitle = event.time != null
        ? '$weekday, $dayMonth · ${event.time}'
        : '$weekday, $dayMonth';

    return Container(
      height: kHomeCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsError(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_outlined,
            color: context.appSecondaryText.withValues(alpha: 0.5),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.serverConnectionFailed,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.appSecondaryText),
            ),
          ),
          IconButton(
            onPressed: () async {
              HapticService.light();
              await ref.read(eventsProvider.notifier).refresh();
            },
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _fadeSwitch(String key, Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}
