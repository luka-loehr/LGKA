// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Helper function to show a modal bottom sheet with proper width constraints
/// for iPad/tablet devices and transparent tappable barrier.
/// 
/// On tablets (width > 600px), the modal is constrained to 600px width.
/// On phones, it uses full width.
/// 
/// The modal includes:
/// - Transparent tappable barrier to dismiss when tapping outside
/// - Proper scroll controller for status bar tap functionality
/// - Centered alignment on tablets
Future<void> showConstrainedModalBottomSheet({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth > 600;
  final maxWidth = isTablet ? 600.0 : screenWidth;
  
  return showMaterialModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
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
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: builder(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
