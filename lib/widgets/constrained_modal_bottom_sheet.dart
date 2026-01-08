// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Reusable modal bottom sheet wrapper with proper width constraints
/// for iPad/tablet devices and transparent tappable barrier.
/// 
/// On tablets (width > 600px), the modal is constrained to 600px width.
/// On phones, it uses full width.
class ConstrainedModalBottomSheet extends StatelessWidget {
  final Widget child;

  const ConstrainedModalBottomSheet({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 600.0 : screenWidth;

    return Stack(
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
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: child,
              ),
            ),
          ),
        ),
      ],
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
