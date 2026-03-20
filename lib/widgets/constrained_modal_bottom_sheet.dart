// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

/// Reusable modal bottom sheet wrapper with proper width constraints
/// for iPad/tablet devices and transparent tappable barrier.
///
/// On tablets (width > 600px), the modal is constrained to 600px width.
/// On phones, it uses full width.
///
/// Wraps content in the correct [Theme] driven by Riverpod providers so
/// that live theme switches (e.g. dark ↔ light inside the Settings modal)
/// are reflected immediately without needing to reopen the sheet.
class ConstrainedModalBottomSheet extends ConsumerWidget {
  final Widget child;

  const ConstrainedModalBottomSheet({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 600.0 : screenWidth;

    // Explicitly watch the theme providers so the modal reacts to theme
    // changes even when the MaterialApp's inherited Theme hasn't propagated
    // through the overlay route yet.
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformBrightness == Brightness.dark);
    final theme = isDark
        ? ref.watch(themeProvider)
        : ref.watch(lightThemeProvider);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Stack(
          children: [
            // Tappable barrier to dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Modal content
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to barrier
                child: Container(
                  width: maxWidth,
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: ModalScrollController.of(context),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show a constrained modal bottom sheet
Future<void> showConstrainedModalBottomSheet({
  required BuildContext context,
  required Widget child,
}) {
  return showMaterialModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ConstrainedModalBottomSheet(
      child: child,
    ),
  );
}
