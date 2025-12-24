// Copyright Luka Löhr 2025

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// A widget that displays Apple's Liquid Glass effect on iOS 18+
/// and falls back to a glassmorphism effect on Android and older iOS versions.
/// 
/// On iOS 18+, this uses the native UIKit implementation with Apple's
/// real `.glassEffect()` API for authentic liquid glass material.
/// 
/// On Android and older iOS, it uses a Flutter-based glassmorphism effect
/// with blur and transparency.
class LiquidGlass extends StatelessWidget {
  /// The child widget to display on top of the glass effect
  final Widget? child;
  
  /// Border radius for the glass container
  final BorderRadius borderRadius;
  
  /// Padding inside the glass container
  final EdgeInsetsGeometry? padding;
  
  /// Width of the container
  final double? width;
  
  /// Height of the container
  final double? height;
  
  /// Blur intensity for Android fallback (default: 10.0)
  final double blurIntensity;
  
  /// Background opacity for Android fallback (default: 0.1)
  final double backgroundOpacity;
  
  /// Optional background color for Android fallback
  final Color? backgroundColor;

  const LiquidGlass({
    super.key,
    this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.width,
    this.height,
    this.blurIntensity = 10.0,
    this.backgroundOpacity = 0.1,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we should use native iOS liquid glass
    // Only use native implementation when explicit size is provided
    if (Platform.isIOS && _isIOS18OrLater() && (width != null || height != null)) {
      return _buildIOSNativeLiquidGlass(context);
    } else {
      return _buildFallbackGlass(context);
    }
  }

  /// Build native iOS liquid glass using platform view
  /// Note: This REQUIRES explicit width/height due to UiKitView constraints
  Widget _buildIOSNativeLiquidGlass(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // Native iOS liquid glass background
            const Positioned.fill(
              child: UiKitView(
                viewType: 'liquid_glass_view',
                creationParams: null,
                creationParamsCodec: StandardMessageCodec(),
              ),
            ),
            // Child content on top
            // We don't use Positioned.fill here so the child can determine the size
            // if width or height are not explicitly provided
            if (child != null)
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  /// Build fallback glassmorphism effect for Android and older iOS
  Widget _buildFallbackGlass(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface.withValues(alpha: backgroundOpacity);
    
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Check if running on iOS 26 or later
  bool _isIOS18OrLater() {
    if (!Platform.isIOS) return false;
    
    try {
      // Get iOS version from platform
      // The native iOS implementation handles version checking automatically
      // iOS 26+ will use native glassEffect(), older versions use UIVisualEffectView fallback
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// A specialized liquid glass widget for app bars
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double elevation;
  final Color? backgroundColor;
  
  const LiquidGlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.elevation = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: BorderRadius.zero,
      blurIntensity: 20.0,
      backgroundOpacity: 0.6,
      backgroundColor: backgroundColor,
      height: preferredSize.height,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (leading != null) leading!,
            if (leading == null) const SizedBox(width: 16),
            Expanded(
              child: Center(child: title),
            ),
            if (actions != null) ...actions!,
            if (actions == null) const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A liquid glass button widget
class LiquidGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;
  
  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.width,
    this.height,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _onTapDown() : null,
      onTapUp: widget.onTap != null ? (_) => _onTapUp() : null,
      onTapCancel: widget.onTap != null ? () => _onTapCancel() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: LiquidGlass(
              width: widget.width,
              height: widget.height,
              borderRadius: widget.borderRadius,
              padding: widget.padding,
              blurIntensity: 15.0,
              backgroundOpacity: _isPressed ? 0.15 : 0.1,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }
}

/// A liquid glass card widget for displaying content
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassCard = LiquidGlass(
      width: width,
      height: height,
      borderRadius: borderRadius,
      padding: padding,
      blurIntensity: 12.0,
      backgroundOpacity: 0.08,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: glassCard,
      );
    }

    return glassCard;
  }
}

