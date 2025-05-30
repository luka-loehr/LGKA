import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';

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