// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/color_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../../services/haptic_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../config/app_credentials.dart';

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
  bool _shouldShowOffset = false;
  bool _hasInitializedAnimations = false;
  
  // Adaptive offset calculation based on screen height
  double _getAdaptiveOffset(BuildContext context) {
    // With textScaleFactor fixed to 1.0, a fixed offset works well
    return -185.0;
  }
  
  // Base offset for unfocused UI (to center it better)
  static const double _baseOffset = -30.0;
  
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Duration _buttonAnimationDuration = Duration(milliseconds: 300);
  
  // Colors
  static const Color _errorRedColor = Colors.red;
  static const Color _successGreenColor = Colors.green;
  
  static const Duration _buttonColorTransitionDuration = Duration(milliseconds: 300);
  
  late AnimationController _buttonColorController;
  late Animation<Color?> _buttonColorAnimation;
  late AnimationController _successColorController;
  late Animation<Color?> _successColorAnimation;

  // Get accent color from color provider
  Color get _activeColor => ref.watch(currentColorProvider);
  
  // Inactive color with transparency
  Color get _inactiveColor => _activeColor.withValues(alpha: 0.5); // 50% opacity

  @override
  void initState() {
    super.initState();
    
    // Get initial accent color
    // Initialize accent color from preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Accent color is managed via provider, no need to store locally
    });
    
    // Setup button color animation with accent color
    _buttonColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    // Setup success color animation
    _successColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );
    
    // Set up focus listeners
    _usernameFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleTextChange);
    
    // Listen for text changes to update button state
    _usernameController.addListener(_handleTextChange);
    _passwordController.addListener(_handleTextChange);
  }


  // Update animations when accent color changes
  void _updateAnimations() {
    _buttonColorAnimation = ColorTween(
      begin: _activeColor,
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

    _successColorAnimation = ColorTween(
      begin: _activeColor,
      end: _successGreenColor,
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _handleFocusChange() {
    _updateOffsetState();
  }
  
  void _handleTextChange() {
    // Force rebuild to update button state
    setState(() {});
  }
  
  void _updateOffsetState() {
    final bool hasFocus = _usernameFocusNode.hasFocus || _passwordFocusNode.hasFocus;
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // Only show offset if field has focus AND keyboard is visible
    final bool shouldOffset = hasFocus && keyboardVisible;
    
    if (shouldOffset != _shouldShowOffset) {
      setState(() {
        _shouldShowOffset = shouldOffset;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Setup color animations only once after dependencies are available
    if (!_hasInitializedAnimations) {
      final activeColor = ref.read(currentColorProvider);
      
      _buttonColorAnimation = ColorTween(
        begin: activeColor, // Current accent color
        end: _errorRedColor,
      ).animate(CurvedAnimation(
        parent: _buttonColorController,
        curve: Curves.easeInOut,
      ));

      _successColorAnimation = ColorTween(
        begin: activeColor, // Current accent color
        end: _successGreenColor,
      ).animate(CurvedAnimation(
        parent: _successColorController,
        curve: Curves.easeInOut,
      ));
      
      _hasInitializedAnimations = true;
    }
    
    // Ensure keyboard animation updates when keyboard visibility changes
    _updateOffsetState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _buttonColorController.dispose();
    _successColorController.dispose();
    super.dispose();
  }

  void _validateLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == AppCredentials.username && password == AppCredentials.password) {
      // Show success flash immediately
      setState(() {
        _showSuccessFlash = true;
        _showErrorFlash = false;
      });
      
      // Start success animation with smooth fade
      _successColorController.forward();
      
      // Success with premium haptic feedback
      await HapticService.intense();
      
      if (!mounted) return;
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      // Hold the green color briefly, then start loading while staying green
      await Future.delayed(const Duration(milliseconds: 600));
      
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
      await ref.read(preferencesManagerProvider.notifier).setFirstLaunch(false);
      await ref.read(preferencesManagerProvider.notifier).setOnboardingCompleted(true);
      // isAuthenticatedProvider is managed via preferencesManagerProvider
      
      // Additional success haptic just before navigation
      await HapticService.light();
      
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
      });
      
      // Start error animation immediately on press
      _buttonColorController.forward(from: 0);
      
      // Premium error feedback - single, clean haptic pulse
      await HapticService.medium();
      
      // Hold the red color briefly
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          // Smoothly animate back to blue
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
    
    if (_canLogin) {
      return _activeColor; // Active blue when fields have content
    }
    
    return _inactiveColor; // Grayed-out blue when fields are empty
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible to update offset state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOffsetState();
    });
    
    // Listen for accent color changes
    ref.listen(preferencesManagerProvider, (previous, next) {
      if (previous?.accentColor != next.accentColor) {
        _updateAnimations();
        setState(() {}); // Trigger rebuild to update colors
      }
    });
    
    // Get screen metrics for responsive design
    final screenSize = MediaQuery.of(context).size;
    // Force text scale factor to 1.0 for consistent UI across all devices
    const textScaleFactor = 1.0;
    
    // Calculate responsive sizes
    final bool isSmallScreen = screenSize.height < 700;
    final double topSpacing = isSmallScreen ? 60 : 100;
    final double formWidth = screenSize.width * 0.85;
    final double maxFormWidth = 400; // Max width for larger screens
    
    return Scaffold(
      backgroundColor: Colors.black,
      // This silences the overflow messages without changing behavior
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          // Clear focus when tapping outside fields
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeOutQuad,
          transform: Matrix4.translationValues(
            0, 
            _shouldShowOffset ? _getAdaptiveOffset(context) : _baseOffset, 
            0
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: topSpacing),
                      
                      // Title
                      Text(
                        AppLocalizations.of(context)!.authTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28 / textScaleFactor, // Adjust for text scale factor
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      Text(
                        AppLocalizations.of(context)!.authSubtitle,
                        style: TextStyle(
                          color: const Color(0xB3FFFFFF), // 70% white
                          fontSize: 14 / textScaleFactor, // Adjust for text scale factor
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 40 : 60),
                      
                      // Card with form fields
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxFormWidth,
                        ),
                        child: Container(
                          width: formWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Username Field with rounded corners
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16), 
                                  topRight: Radius.circular(16),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  focusNode: _usernameFocusNode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.username,
                                    hintStyle: const TextStyle(
                                      color: Color(0x80FFFFFF),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF8E8E93),
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E1E),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              
                              // Divider
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              
                              // Password Field with rounded corners
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16), 
                                  bottomRight: Radius.circular(16),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.password,
                                    hintStyle: const TextStyle(
                                      color: Color(0x80FFFFFF),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF8E8E93),
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E1E),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (_canLogin) _validateLogin();
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Button with animated color
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxFormWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_buttonColorAnimation, _successColorAnimation]),
                          builder: (context, child) {
                            return SizedBox(
                              width: formWidth,
                              height: 46,
                              child: Stack(
                                children: [
                                  // Animated background button
                                  Positioned.fill(
                                    child: AnimatedContainer(
                                      duration: _buttonColorTransitionDuration,
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        color: _currentButtonColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  
                                  // Clickable transparent button with always-white text
                                  SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: InkWell(
                                      onTap: _canLogin && !_showErrorFlash && !_showSuccessFlash ? _validateLogin : null,
                                      borderRadius: BorderRadius.circular(12),
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      child: Center(
                                        child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                strokeCap: StrokeCap.round,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              AppLocalizations.of(context)!.login,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontSize: 15 / textScaleFactor,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 40 : 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
