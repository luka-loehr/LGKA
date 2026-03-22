// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'skeleton_card.dart';

/// A card that responds to tap gestures with a scale-down press animation.
class TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TappableCard({super.key, required this.child, required this.onTap});

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _scale.reverse();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _scale.forward();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _scale.forward();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _pressed ? _scale.value : 1.0,
          child: Container(
            height: kHomeCardHeight,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: context.appSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _pressed
                  ? null
                  : [
                      BoxShadow(
                        color: context.appBrightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
