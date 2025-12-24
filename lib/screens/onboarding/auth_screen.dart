// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../providers/color_provider.dart';
import '../../navigation/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_credentials.dart';
import '../../providers/haptic_service.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const AuthScreen({super.key, this.onLoginSuccess});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _showErrorFlash = false;
  bool _showSuccessFlash = false;
  bool _showUsernameError = false;
  bool _showPasswordError = false;
  
  late AnimationController _buttonColorController;
  late Animation<Color?> _buttonColorAnimation;
  late AnimationController _successColorController;
  late Animation<Color?> _successColorAnimation;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  
  static const Duration _buttonAnimationDuration = Duration(milliseconds: 300);
  
  // Colors
  static const Color _errorRedColor = Colors.red;
  static const Color _successGreenColor = Colors.green;

  @override
  void initState() {
    super.initState();
    
    // Setup button color animation
    _buttonColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    // Setup success color animation
    _successColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );
    
    // Button press animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Content animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start content animation
    _contentController.forward();
    
    // Listen for text changes to update button state
    _usernameController.addListener(_handleTextChange);
    _passwordController.addListener(_handleTextChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Setup color animations after dependencies are available
    final activeColor = ref.read(currentColorProvider);
    
    _buttonColorAnimation = ColorTween(
      begin: activeColor,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

    _successColorAnimation = ColorTween(
      begin: activeColor,
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _buttonColorController.dispose();
    _successColorController.dispose();
    _buttonController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    // Clear error states when user types
    if (_showUsernameError || _showPasswordError) {
      setState(() {
        _showUsernameError = false;
        _showPasswordError = false;
      });
    }
    // Force rebuild to update button state
    setState(() {});
  }

  void _validateLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Haptic feedback for login button press
    HapticService.medium();

    if (username == AppCredentials.username && password == AppCredentials.password) {
      // Show success flash immediately
      setState(() {
        _showSuccessFlash = true;
        _showErrorFlash = false;
        _showUsernameError = false;
        _showPasswordError = false;
      });
      
      // Start success animation with smooth fade
      _successColorController.forward();
      
      if (!mounted) return;
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      // Hold the green color briefly, then start loading while staying green
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      
      // Haptic feedback for successful authentication (1 second after button press)
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        HapticService.medium();
      }
      
      if (!mounted) return;
      
      // Start loading state while keeping green color
      setState(() {
        _isLoading = true;
      });
      
      // Continue loading for visual feedback (button stays green)
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      
      // Update authentication state
      await ref.read(preferencesManagerProvider.notifier).setAuthenticated(true);
      ref.read(isAuthenticatedProvider.notifier).state = true;
      
      // Mark onboarding as completed only after successful authentication
      final notifier = ref.read(preferencesManagerProvider.notifier);
      await notifier.setOnboardingCompleted(true);
      await notifier.setFirstLaunch(false);
      
      // Small delay to let the haptic feedback register
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Reset success flash state before navigation
      setState(() {
        _showSuccessFlash = false;
      });
      
      // Trigger success callback or navigate
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else if (mounted) {
        context.go(AppRouter.home);
      }
    } else {
      // Show error immediately
      setState(() {
        _showErrorFlash = true;
        _showUsernameError = username != AppCredentials.username;
        _showPasswordError = password != AppCredentials.password;
      });
      
      // Start error animation immediately on press
      _buttonColorController.forward(from: 0);
      
      // Hold the red color briefly
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          // Smoothly animate back to accent color
          _buttonColorController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showErrorFlash = false;
              });
            }
          });
        }
      });
    }
  }

  bool get _canLogin {
    return _usernameController.text.trim().isNotEmpty &&
           _passwordController.text.trim().isNotEmpty &&
           !_isLoading;
  }
  
  // Get the current button color based on state
  Color get _currentButtonColor {
    if (_showSuccessFlash) {
      return _successColorAnimation.value ?? _successGreenColor;
    }
    
    if (_showErrorFlash) {
      return _buttonColorAnimation.value ?? _errorRedColor;
    }
    
    final activeColor = ref.read(currentColorProvider);
    
    if (_canLogin) {
      return activeColor; // Active accent color when fields have content
    }
    
    return activeColor.withValues(alpha: 0.5); // 50% opacity when fields are empty
  }

  Future<void> _selectColor(String colorName) async {
    setState(() {
      // Trigger rebuild to update colors
    });

    // Haptic feedback for color selection
    HapticService.light();

    // Save color preference using color provider
    await ref.read(colorProvider.notifier).setColor(colorName);
    
    // Update animations with new color
    final newColor = ref.read(currentColorProvider);
    _buttonColorAnimation = ColorTween(
      begin: newColor,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

    _successColorAnimation = ColorTween(
      begin: newColor,
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final choosableColors = ref.watch(choosableColorsProvider);
    final currentColorName = ref.watch(colorProvider);
    final activeColor = ref.watch(currentColorProvider);
    
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _contentController,
            _buttonController,
            _buttonColorAnimation,
            _successColorAnimation,
          ]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentSlide,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      
                      // Header
                      Text(
                        AppLocalizations.of(context)!.authTitle,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        AppLocalizations.of(context)!.authSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Accent Color Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.accentColor,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.chooseAccentColor,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: choosableColors.map((colorPalette) {
                              final isSelected = currentColorName == colorPalette.name;
                              return GestureDetector(
                                onTap: () => _selectColor(colorPalette.name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorPalette.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: isSelected ? 3 : 0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colorPalette.color.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    opacity: isSelected ? 1.0 : 0.0,
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Username Field
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        autofocus: true,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryText,
                            ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.username,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.secondaryText,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showUsernameError
                                  ? Colors.red
                                  : activeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showUsernameError
                                  ? Colors.red
                                  : activeColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.appSurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        onChanged: (_) => _handleTextChange(),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryText,
                            ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.secondaryText,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showPasswordError
                                  ? Colors.red
                                  : activeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showPasswordError
                                  ? Colors.red
                                  : activeColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.appSurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_canLogin) {
                            _buttonController.forward().then((_) {
                              _buttonController.reverse();
                              _validateLogin();
                            });
                          }
                        },
                        onChanged: (_) => _handleTextChange(),
                      ),

                      const Spacer(),

                      // Login Button
                      ScaleTransition(
                        scale: _buttonScale,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: _currentButtonColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isLoading || _showErrorFlash || _showSuccessFlash ? null : [
                                BoxShadow(
                                  color: _currentButtonColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _canLogin && !_showErrorFlash && !_showSuccessFlash
                                  ? () {
                                      _buttonController.forward().then((_) {
                                        _buttonController.reverse();
                                        _validateLogin();
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.login,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
