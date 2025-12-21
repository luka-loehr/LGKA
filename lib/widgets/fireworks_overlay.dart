// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fireworks_provider.dart';
import '../providers/haptic_service.dart';

class FireworksOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const FireworksOverlay({super.key, required this.child});

  @override
  ConsumerState<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends ConsumerState<FireworksOverlay> {
  Timer? _fireworksTimer;
  Timer? _particleHapticTimer;
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
    _particleHapticTimer?.cancel();
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
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () => HapticService.subtle());
    }
    _controller?.fireSingleRocket(color: _colors[_random.nextInt(_colors.length)]);
    Future.delayed(const Duration(milliseconds: 1000), _startParticleHaptics);
  }

  void _startParticleHaptics() {
    _particleHapticTimer?.cancel();
    final endTime = DateTime.now().millisecondsSinceEpoch + 1000;
    void scheduleNext() {
      if (DateTime.now().millisecondsSinceEpoch >= endTime) return;
      _particleHapticTimer = Timer(Duration(milliseconds: 50 + _random.nextInt(150)), () {
        if (mounted && DateTime.now().millisecondsSinceEpoch < endTime) {
          HapticService.light();
          scheduleNext();
        }
      });
    }
    scheduleNext();
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
