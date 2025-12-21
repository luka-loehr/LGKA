// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fireworks_provider.dart';
import '../providers/haptic_service.dart';

/// Global fireworks overlay that displays fireworks on New Year's Day
class FireworksOverlay extends ConsumerStatefulWidget {
  final Widget child;
  
  const FireworksOverlay({super.key, required this.child});

  @override
  ConsumerState<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends ConsumerState<FireworksOverlay> {
  Timer? _fireworksTimer;
  Timer? _particleHapticTimer;
  FireworksController? _fireworksController;
  bool _wasShowingFireworks = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Initialize controller with 500 particles, longer duration, no fade out
    _fireworksController = FireworksController(
      minParticleCount: 500,
      maxParticleCount: 500,
      minExplosionDuration: 5.0,
      maxExplosionDuration: 8.0,
      fadeOutDuration: 0.0, // No fade out
    );
  }

  @override
  void dispose() {
    _stopFireworksTimer();
    _stopParticleHaptics();
    _fireworksController?.dispose();
    super.dispose();
  }

  void _startFireworksTimer() {
    _stopFireworksTimer();
    
    // Launch first firework immediately
    _launchSingleRocket();
    
    // Then launch every 4 seconds
    _fireworksTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _launchSingleRocket();
      }
    });
  }

  void _stopFireworksTimer() {
    _fireworksTimer?.cancel();
    _fireworksTimer = null;
  }

  void _launchSingleRocket() {
    // Short burst small vibrations on launch
    _triggerLaunchHaptics();
    
    // Single rocket with 500 particles
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.yellow,
      Colors.pink,
    ];
    _fireworksController?.fireSingleRocket(
      color: colors[_random.nextInt(colors.length)],
    );
    
    // Explosion haptic after rocket travel time (approximately 1-2 seconds)
    Future.delayed(const Duration(milliseconds: 1500), () {
      _triggerExplosionHaptic();
      _startParticleHaptics();
    });
  }

  void _triggerLaunchHaptics() {
    // Short burst of small vibrations on launch
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        HapticService.subtle();
      });
    }
  }

  void _triggerExplosionHaptic() {
    // One really short big vibration when it explodes
    HapticService.medium();
  }

  void _startParticleHaptics() {
    _stopParticleHaptics();
    
    // Random small fast light vibrations as particles emerge
    // Duration matches explosion duration (5-8 seconds)
    final explosionDuration = 5000 + _random.nextInt(3000); // 5-8 seconds
    final endTime = DateTime.now().millisecondsSinceEpoch + explosionDuration;
    
    void scheduleNextHaptic() {
      if (DateTime.now().millisecondsSinceEpoch >= endTime) {
        return;
      }
      
      // Random delay between 50-200ms for fast random vibrations
      final delay = 50 + _random.nextInt(150);
      _particleHapticTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted && DateTime.now().millisecondsSinceEpoch < endTime) {
          HapticService.light();
          scheduleNextHaptic();
        }
      });
    }
    
    scheduleNextHaptic();
  }

  void _stopParticleHaptics() {
    _particleHapticTimer?.cancel();
    _particleHapticTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final showFireworks = ref.watch(fireworksProvider);
    
    // Handle state changes in build method
    if (showFireworks && !_wasShowingFireworks) {
      // Just started showing fireworks
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startFireworksTimer();
        }
      });
      _wasShowingFireworks = true;
    } else if (!showFireworks && _wasShowingFireworks) {
      // Just stopped showing fireworks
      _stopFireworksTimer();
      _wasShowingFireworks = false;
    }
    
    return Stack(
      children: [
        widget.child,
        if (showFireworks && _fireworksController != null)
          Positioned.fill(
            child: FireworksDisplay(
              controller: _fireworksController!,
            ),
          ),
      ],
    );
  }
}

