// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/color_provider.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_info.dart';

/// Settings bottom sheet
class SettingsModal extends ConsumerWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, _bottomPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Text(
                  AppLocalizations.of(context)!.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: context.appPrimaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

              // ── Appearance ─────────────────────────────────────────────
              _sectionLabel(context, AppLocalizations.of(context)!.settingsSectionAppearance),
              const SizedBox(height: 8),
              _card(context, [
                _appearanceRow(context, ref),
                _internalDivider(context),
                _colorRow(context, ref),
              ]),

              const SizedBox(height: 20),

              // ── Links ───────────────────────────────────────────────────
              _sectionLabel(context, AppLocalizations.of(context)!.settingsSectionMore),
              const SizedBox(height: 8),
              _card(context, [
                _linkTile(
                  context,
                  icon: Icons.bug_report_outlined,
                  label: AppLocalizations.of(context)!.bugReport,
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    HapticService.light();
                    context.push(AppRouter.bugReport);
                  },
                ),
                _internalDivider(context),
                _linkTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: AppLocalizations.of(context)!.privacyLabel,
                  trailing: const Icon(Icons.open_in_new, size: 14),
                  onTap: () {
                    HapticService.light();
                    _launchURL('https://luka-loehr.github.io/LGKA/privacy.html');
                  },
                ),
                _internalDivider(context),
                _linkTile(
                  context,
                  icon: Icons.info_outline,
                  label: AppLocalizations.of(context)!.legalLabel,
                  trailing: const Icon(Icons.open_in_new, size: 14),
                  onTap: () {
                    HapticService.light();
                    _launchURL('https://luka-loehr.github.io/LGKA/impressum.html');
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // ── Footer ──────────────────────────────────────────────────
              _buildFooter(context),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.appSecondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _internalDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 0,
      color: context.appDividerColor,
    );
  }

  // ── Appearance ─────────────────────────────────────────────────────────────

  Widget _appearanceRow(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(preferencesManagerProvider).themeMode;
    final isDark = context.appBrightness == Brightness.dark;

    final l = AppLocalizations.of(context)!;
    final modes = [
      (mode: 'dark', icon: Icons.dark_mode_rounded, label: l.themeDark),
      (mode: 'light', icon: Icons.light_mode_rounded, label: l.themeLight),
      (mode: 'system', icon: Icons.brightness_auto_rounded, label: l.themeAuto),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.appearanceTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appPrimaryText,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: modes.map((m) {
                final isSelected = currentMode == m.mode;
                return GestureDetector(
                  onTap: () {
                    HapticService.light();
                    ref
                        .read(preferencesManagerProvider.notifier)
                        .setThemeMode(m.mode);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      m.icon,
                      size: 17,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : context.appSecondaryText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(BuildContext context, WidgetRef ref) {
    final choosableColors = ref.watch(choosableColorsProvider);
    final currentColorName = ref.watch(colorProvider);
    const ringColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.accentColor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appPrimaryText,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: choosableColors.map((cp) {
              final isSelected = currentColorName == cp.name;
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  ref.read(colorProvider.notifier).setColor(cp.name);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cp.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? ringColor : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cp.color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 13, color: ringColor)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Link tile ──────────────────────────────────────────────────────────────

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.appSecondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appPrimaryText,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
            IconTheme(
              data: IconThemeData(
                  color: context.appSecondaryText.withValues(alpha: 0.5),
                  size: 16),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    final year = DateTime.now().year;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '© $year ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appSecondaryText.withValues(alpha: 0.4),
                ),
          ),
          Text(
            'Luka Löhr',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            ' • v${AppInfo.version}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appSecondaryText.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  // ── Utils ──────────────────────────────────────────────────────────────────

  double _bottomPadding(BuildContext context) {
    final mq = MediaQuery.of(context);
    final gi = mq.systemGestureInsets.bottom;
    if (gi >= 45) return 54.0;
    if (gi <= 25) return 8.0;
    return mq.viewPadding.bottom > 50 ? 54.0 : 8.0;
  }

  void _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }
}
