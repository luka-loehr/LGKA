// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fireworks_provider.dart';
import '../services/haptic_service.dart';

class FireworksOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const FireworksOverlay({super.key, required this.child});

  @override
  ConsumerState<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends ConsumerState<FireworksOverlay> {
  Timer? _fireworksTimer;
  FireworksController? _controller;
  bool _wasShowing = false;
  final Random _random = Random();
  static const _colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.yellow, Colors.pink];

  @override
  void initState() {
    super.initState();
    _controller = FireworksController(
      minParticleCount: 500,
      maxParticleCount: 500,
      minExplosionDuration: 5.0,
      maxExplosionDuration: 8.0,
      fadeOutDuration: 0.0,
    );
  }

  @override
  void dispose() {
    _fireworksTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startFireworksTimer() {
    _fireworksTimer?.cancel();
    _launchSingleRocket();
    _fireworksTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _launchSingleRocket();
    });
  }

  void _launchSingleRocket() {
    _controller?.fireSingleRocket(color: _colors[_random.nextInt(_colors.length)]);
    // Add haptic feedback when rocket launches
    HapticService.medium();
  }


  @override
  Widget build(BuildContext context) {
    final showFireworks = ref.watch(fireworksProvider);
    if (showFireworks && !_wasShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startFireworksTimer();
      });
      _wasShowing = true;
    } else if (!showFireworks && _wasShowing) {
      _fireworksTimer?.cancel();
      _wasShowing = false;
    }
    return Stack(
      children: [
        widget.child,
        if (showFireworks && _controller != null)
          Positioned.fill(child: FireworksDisplay(controller: _controller!)),
      ],
    );
  }
}
