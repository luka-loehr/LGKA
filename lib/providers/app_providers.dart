// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';
import '../services/review_service.dart';
import '../services/version_service.dart';

// Preferences Manager Provider
final preferencesManagerProvider = Provider<PreferencesManager>((ref) {
  throw UnimplementedError('PreferencesManager must be overridden');
});

// PDF Repository Provider
final pdfRepositoryProvider = ChangeNotifierProvider<PdfRepository>((ref) {
  return PdfRepository();
});

// App State Providers
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Navigation State Provider
final currentRouteProvider = StateProvider<String>((ref) => '/welcome');

// User Class State Provider
final userClassProvider = StateProvider<String?>((ref) => null);

// Use AI Version State Provider
final useAiVersionProvider = StateProvider<bool>((ref) => false);

// Review Service Provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final preferencesManager = ref.watch(preferencesManagerProvider);
  return ReviewService(preferencesManager);
});

// Version Service Provider
final versionServiceProvider = Provider<VersionService>((ref) {
  final preferencesManager = ref.watch(preferencesManagerProvider);
  return VersionService(preferencesManager);
});