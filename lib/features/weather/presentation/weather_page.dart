// Copyright Luka Löhr 2026

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart' hide WeatherDataState;
import 'package:weather_icons/weather_icons.dart';
import '../../../theme/app_theme.dart';
import '../../../services/haptic_service.dart';
import '../application/weather_provider.dart';
import '../domain/weather_models.dart';

class WeatherPage extends ConsumerWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherDataProvider);

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        backgroundColor: context.appBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.appPrimaryText),
          onPressed: () {
            HapticService.light();
            if (context.mounted) context.pop();
          },
        ),
        title: Text(
          'Wetter Karlsruhe',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appPrimaryText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, WeatherDataState state) {
    if (state.isLoading && state.current == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.current == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: context.appSecondaryText.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Wetterdaten nicht verfügbar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.appPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte prüfe deine Internetverbindung.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.appSecondaryText),
            ),
          ],
        ),
      );
    }

    final current = state.current!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _buildCurrentCard(context, current, state.daily),
              const SizedBox(height: 16),
              _buildStatsRow(context, current),
              if (state.hourly.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildSectionHeader(context, 'STÜNDLICH'),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ),
        if (state.hourly.isNotEmpty)
          SliverToBoxAdapter(child: _buildHourlyScroll(context, state.hourly)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (state.daily.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildSectionHeader(context, '3 TAGE'),
                const SizedBox(height: 12),
                _buildDailyForecast(context, state.daily),
              ],
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Daten: Open-Meteo · open-meteo.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            context.appSecondaryText.withValues(alpha: 0.4),
                      ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Current card ────────────────────────────────────────────────────────────

  Widget _buildCurrentCard(BuildContext context, CurrentWeather current,
      List<DailyForecast> daily) {
    final today = daily.isNotEmpty ? daily.first : null;
    final scene = WmoUtils.weatherType(current.weatherCode, current.isDay);
    const textShadows = [Shadow(color: Colors.black38, blurRadius: 8)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            // Animated weather scene fills the entire card
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => WeatherBg(
                  weatherType: scene,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
              ),
            ),
            // Subtle gradient overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black26],
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BoxedIcon(
                          WmoUtils.icon(current.weatherCode, current.isDay),
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${current.temp.round()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 80,
                            height: 1,
                            shadows: textShadows,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _capitalize(current.description),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                            shadows: textShadows,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today != null
                          ? 'Gefühlt ${current.feelsLike.round()}°  ·  H ${today.tempMax.round()}°  T ${today.tempMin.round()}°'
                          : 'Gefühlt ${current.feelsLike.round()}°',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            shadows: textShadows,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, CurrentWeather c) {
    final windDir = _compassDir(c.windDeg);
    final uviLabel = _uviLabel(c.uvi);

    return Row(
      children: [
        _statChip(context,
            icon: Icons.water_drop_outlined,
            value: '${c.humidity}%',
            label: 'Luftfeuchte'),
        const SizedBox(width: 10),
        _statChip(context,
            icon: Icons.air,
            value: '$windDir ${c.windSpeed.round()} km/h',
            label: 'Wind'),
        const SizedBox(width: 10),
        _statChip(context,
            icon: Icons.speed,
            value: '${c.pressure}',
            label: 'hPa'),
        const SizedBox(width: 10),
        _statChip(context,
            icon: Icons.wb_sunny_outlined,
            value: c.uvi.toStringAsFixed(1),
            label: uviLabel),
      ],
    );
  }

  Widget _statChip(BuildContext context,
      {required IconData icon,
      required String value,
      required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: context.appSecondaryText),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appPrimaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondaryText.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Hourly scroll ───────────────────────────────────────────────────────────

  Widget _buildHourlyScroll(
      BuildContext context, List<HourlyForecast> hourly) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _hourlyItem(context, hourly[i]),
      ),
    );
  }

  Widget _hourlyItem(BuildContext context, HourlyForecast h) {
    final timeStr = DateFormat('HH:mm').format(h.dt.toLocal());
    final showPop = h.pop >= 0.1;

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            timeStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appSecondaryText,
                  fontSize: 11,
                ),
          ),
          BoxedIcon(
            WmoUtils.icon(h.weatherCode, h.isDay),
            size: 28,
            color: context.appSecondaryText,
          ),
          Text(
            '${h.temp.round()}°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appPrimaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (showPop)
            Text(
              '${(h.pop * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Daily forecast ──────────────────────────────────────────────────────────

  Widget _buildDailyForecast(
      BuildContext context, List<DailyForecast> daily) {
    final weekMin = daily.map((d) => d.tempMin).reduce(min);
    final weekMax = daily.map((d) => d.tempMax).reduce(max);

    return Container(
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: daily.asMap().entries.map((e) {
          final isLast = e.key == daily.length - 1;
          return Column(
            children: [
              _dailyRow(context, e.value, weekMin, weekMax),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: context.appDividerColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _dailyRow(BuildContext context, DailyForecast d, double weekMin,
      double weekMax) {
    final isToday = _isSameDay(d.dt, DateTime.now());
    final dayLabel = isToday
        ? 'Heute'
        : DateFormat('EEE', 'de_DE').format(d.dt);
    final showPop = d.pop >= 0.1;
    final rangeSpan = (weekMax - weekMin).clamp(1.0, double.infinity);
    final barStart = (d.tempMin - weekMin) / rangeSpan;
    final barEnd = (d.tempMax - weekMin) / rangeSpan;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Weekday
          SizedBox(
            width: 44,
            child: Text(
              dayLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isToday ? primary : context.appPrimaryText,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          // Icon
          BoxedIcon(
            WmoUtils.icon(d.weatherCode, true),
            size: 28,
            color: context.appSecondaryText,
          ),
          // Pop
          SizedBox(
            width: 36,
            child: showPop
                ? Text(
                    '${(d.pop * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
          // Temp min
          SizedBox(
            width: 32,
            child: Text(
              '${d.tempMin.round()}°',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondaryText,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // Temp bar
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.appSecondaryText.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: Stack(
                    children: [
                      Positioned(
                        left: w * barStart,
                        right: w * (1 - barEnd),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.6),
                                primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // Temp max
          SizedBox(
            width: 32,
            child: Text(
              '${d.tempMax.round()}°',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.appSecondaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _compassDir(int deg) {
    const dirs = ['N', 'NO', 'O', 'SO', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }

  String _uviLabel(double uvi) {
    if (uvi < 3) return 'Niedrig';
    if (uvi < 6) return 'Mittel';
    if (uvi < 8) return 'Hoch';
    if (uvi < 11) return 'Sehr hoch';
    return 'Extrem';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

}
