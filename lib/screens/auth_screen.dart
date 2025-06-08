// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../theme/app_theme.dart';

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
  
  // Fixed animation values
  static const double _contentOffsetY = -125.0; // Exactly 125px up
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Duration _buttonAnimationDuration = Duration(milliseconds: 300);
  
  // Colors
  static const Color _activeBlueColor = AppColors.appBlueAccent; // Use centralized brand color
  static const Color _inactiveBlueColor = Color(0xFF1D3A80); // Darker blue instead of gray-blue
  static const Color _errorRedColor = Colors.red;
  static const Color _successGreenColor = Colors.green;
  
  static const Duration _buttonColorTransitionDuration = Duration(milliseconds: 300);
  
  late AnimationController _buttonColorController;
  late Animation<Color?> _buttonColorAnimation;
  late AnimationController _successColorController;
  late Animation<Color?> _successColorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup button color animation - 300ms fade in/out
    _buttonColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    _buttonColorAnimation = ColorTween(
      begin: _activeBlueColor, // Blue
      end: _errorRedColor,
    ).animate(CurvedAnimation(
      parent: _buttonColorController,
      curve: Curves.easeInOut,
    ));

    // Setup success color animation
    _successColorController = AnimationController(
      duration: _buttonAnimationDuration,
      vsync: this,
    );

    _successColorAnimation = ColorTween(
      begin: _activeBlueColor, // Blue
      end: _successGreenColor, // Green
    ).animate(CurvedAnimation(
      parent: _successColorController,
      curve: Curves.easeInOut,
    ));
    
    // Set up focus listeners
    _usernameFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);
    
    // Listen for text changes to update button state
    _usernameController.addListener(_handleTextChange);
    _passwordController.addListener(_handleTextChange);
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

    if (username == "vertretungsplan" && password == "ephraim") {
      // Show success flash immediately
      setState(() {
        _showSuccessFlash = true;
        _showErrorFlash = false;
      });
      
      // Start success animation with smooth fade
      _successColorController.forward();
      
      // Success with premium haptic feedback
      await HapticService.success();
      
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
      final prefsManager = ref.read(preferencesManagerProvider);
      await prefsManager.setAuthenticated(true);
      ref.read(isAuthenticatedProvider.notifier).state = true;
      
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
      await HapticService.error();
      
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
      return _activeBlueColor; // Active blue when fields have content
    }
    
    return _inactiveBlueColor; // Grayed-out blue when fields are empty
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible to update offset state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOffsetState();
    });
    
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
            _shouldShowOffset ? _contentOffsetY : 0.0, 
            0
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: constraints.maxHeight > 700 ? 160 : 80), // Responsive spacer at top
                  
                  // Title
                  const Text(
                    'Anmeldung erforderlich',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  const Text(
                    'Verwende die Zugangsdaten, die du bereits\nvom Vertretungsplan kennst',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF), // 70% white
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 70),
                  
                  // Card with form fields
                  Container(
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
                              fontSize: 18,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Benutzername',
                              hintStyle: TextStyle(
                                color: Color(0x80FFFFFF),
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Color(0xFF8E8E93),
                                size: 24,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 22,
                              ),
                              filled: true,
                              fillColor: Color(0xFF1E1E1E),
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
                              fontSize: 18,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Passwort',
                              hintStyle: TextStyle(
                                color: Color(0x80FFFFFF),
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Color(0xFF8E8E93),
                                size: 24,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 22,
                              ),
                              filled: true,
                              fillColor: Color(0xFF1E1E1E),
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
                  
                  const SizedBox(height: 42),
                  
                  // Login Button with animated color
                  AnimatedBuilder(
                    animation: Listenable.merge([_buttonColorAnimation, _successColorAnimation]),
                    builder: (context, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
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
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          strokeCap: StrokeCap.round,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Anmelden',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                  
                          SizedBox(height: constraints.maxHeight > 700 ? 160 : 80), // Responsive spacer at bottom
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
} 