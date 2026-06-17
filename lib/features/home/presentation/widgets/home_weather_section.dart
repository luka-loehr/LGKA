import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart'
    hide WeatherDataState;
import 'package:go_router/go_router.dart';
import 'package:weather_icons/weather_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../navigation/app_router.dart';
import '../../../../../services/haptic_service.dart';
import '../../../../../theme/app_theme.dart';
import '../../../weather/application/weather_provider.dart';
import '../../../weather/domain/weather_models.dart';
import 'skeleton_card.dart';

class HomeWeatherSection extends ConsumerWidget {
  const HomeWeatherSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherDataProvider);

    final Widget child;
    final String key;

    if (weatherState.isLoading && weatherState.current == null) {
      key = 'weather-loading';
      child = const SkeletonCard();
    } else if (weatherState.hasError && weatherState.current == null) {
      key = 'weather-error';
      child = _buildWeatherError(context, ref);
    } else if (weatherState.current != null) {
      key = 'weather-content';
      child = _buildWeatherCard(
        context,
        weatherState.current!,
        weatherState.daily,
      );
    } else {
      return const SizedBox.shrink();
    }

    return _fadeSwitch(key, child);
  }

  Widget _buildWeatherCard(
    BuildContext context,
    CurrentWeather current,
    List<DailyForecast> daily,
  ) {
    final today = daily.isNotEmpty ? daily.first : null;
    final scene = WmoUtils.weatherType(current.weatherCode, current.isDay);
    final l10n = AppLocalizations.of(context)!;

    const textShadows = [Shadow(color: Colors.black38, blurRadius: 6)];

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          BoxedIcon(
            WmoUtils.icon(current.weatherCode, current.isDay),
            size: 36,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${current.temp.round()}°',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: textShadows,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _capitalize(
                          WmoUtils.localizedDescription(
                            current.weatherCode,
                            l10n,
                          ),
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              shadows: textShadows,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  today != null
                      ? l10n.weatherFeelsLikeHighLow(
                          current.feelsLike.round(),
                          today.tempMax.round(),
                          today.tempMin.round(),
                        )
                      : l10n.weatherFeelsLikeHumidity(
                          current.feelsLike.round(),
                          current.humidity,
                        ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                    shadows: textShadows,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: kHomeCardHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('weather_card'),
            onTap: () {
              HapticService.medium();
              context.push(AppRouter.weather);
            },
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    // RepaintBoundary isolates the continuously-animating
                    // background so its repaints don't invalidate sibling slivers.
                    builder: (context, constraints) => RepaintBoundary(
                      child: WeatherBg(
                        weatherType: scene,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black12, Colors.black26],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherError(BuildContext context, WidgetRef ref) {
    return Container(
      height: kHomeCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 20,
            color: context.appSecondaryText.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.weatherDataNotAvailable,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appSecondaryText),
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.light();
              ref.read(weatherDataProvider.notifier).updateDataInBackground();
            },
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
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

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
