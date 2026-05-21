// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

class ScaleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final bool isLoading;
  final double? height;
  final double width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double elevation;

  const ScaleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.isLoading = false,
    this.height,
    this.width = double.infinity,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null || widget.isLoading) return;

    // Press down
    await _controller.forward();
    
    // Premium haptics
    await HapticService.light();
    
    // Reverse scale
    _controller.reverse();
    
    // Small delay to make the rebound feel natural before invoking callback
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (mounted) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final textColor = widget.foregroundColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ElevatedButton(
              onPressed: (widget.onTap == null || widget.isLoading) ? null : _handleTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                elevation: widget.isLoading ? 0 : widget.elevation,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : widget.child,
            ),
          ),
        );
      },
    );
  }
}
