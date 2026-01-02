// Copyright Luka Löhr 2025

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/color_provider.dart';

/// Shows a floating toast message with accent color, rounded corners, and shadow
class FloatingToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static GlobalKey<_FloatingToastWidgetState>? _stateKey;

  /// Show a floating toast message
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    // Hide any existing toast
    hide();

    // Get accent color from provider
    Color accentColor;
    if (backgroundColor != null) {
      accentColor = backgroundColor;
    } else {
      final container = ProviderScope.containerOf(context, listen: false);
      accentColor = container.read(currentColorProvider);
    }

    // Create state key
    _stateKey = GlobalKey<_FloatingToastWidgetState>();

    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingToastWidget(
        key: _stateKey,
        message: message,
        backgroundColor: accentColor,
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-hide after duration
    _timer = Timer(duration, () {
      hide();
    });
  }

  /// Hide the current toast with animation
  static void hide() {
    _timer?.cancel();
    _timer = null;
    
    // Animate out before removing
    final state = _stateKey?.currentState;
    if (state != null && state.mounted) {
      state.animateOut().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _stateKey = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _stateKey = null;
    }
  }
}

class _FloatingToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;

  const _FloatingToastWidget({
    super.key,
    required this.message,
    required this.backgroundColor,
  });

  @override
  State<_FloatingToastWidget> createState() => _FloatingToastWidgetState();
}

class _FloatingToastWidgetState extends State<_FloatingToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  /// Animate out the toast
  Future<void> animateOut() async {
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
