import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';

class ClassSelectorScreen extends ConsumerStatefulWidget {
  const ClassSelectorScreen({super.key});

  @override
  ConsumerState<ClassSelectorScreen> createState() => _ClassSelectorScreenState();
}

class _ClassSelectorScreenState extends ConsumerState<ClassSelectorScreen> {
  final TextEditingController _classController = TextEditingController();
  String? _errorMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _classController.addListener(_validateClass);
  }

  @override
  void dispose() {
    _classController.dispose();
    super.dispose();
  }

  void _validateClass() {
    final input = _classController.text.toLowerCase().trim();
    
    // Regex für Klassen 5-10 mit Buchstaben
    final regex = RegExp(r'^([5-9]|10)[a-z]$');
    
    setState(() {
      if (input.isEmpty) {
        _errorMessage = null;
        _isValid = false;
      } else if (regex.hasMatch(input)) {
        _errorMessage = null;
        _isValid = true;
      } else {
        _errorMessage = 'Ungültige Klasse. Beispiele: 5a, 9b, 10c';
        _isValid = false;
      }
    });
  }

  void _continue() async {
    if (_isValid) {
      await HapticService.subtle();
      final className = _classController.text.toLowerCase().trim();
      context.push(AppRouter.classConfirmation, extra: className);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Titel
              Text(
                'Deine Klasse',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Gib deine Klasse ein, um personalisierte Vertretungen zu erhalten.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Eingabefeld
              Container(
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorMessage != null 
                        ? Colors.red.withOpacity(0.5)
                        : _isValid 
                            ? AppColors.appBlueAccent.withOpacity(0.5)
                            : AppColors.appSurface,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _classController,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'z.B. 9b',
                    hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.secondaryText.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  onSubmitted: (_) => _continue(),
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Beispiele
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.appSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beispiele:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '5a, 6b, 7c, 8d, 9e, 10f',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Weiter Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid 
                        ? AppColors.appBlueAccent 
                        : AppColors.appSurface,
                    foregroundColor: _isValid 
                        ? Colors.white 
                        : AppColors.secondaryText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Weiter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isValid ? Colors.white : AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 