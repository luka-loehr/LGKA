import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';

/// A modal screen for entering a class name for schedule navigation.
class ClassInputModal extends StatelessWidget {
  /// Controller for the class input text field.
  final TextEditingController controller;

  /// Focus node for the class input text field.
  final FocusNode focusNode;

  /// Whether the class is currently being validated.
  final bool isValidating;

  /// Whether the save button can be pressed.
  final bool canSave;

  /// The current color of the save button (animated).
  final Color buttonColor;

  /// Animation for button color changes.
  final Animation<Color?>? buttonColorAnimation;

  /// Animation for success color changes.
  final Animation<Color?>? successColorAnimation;

  /// Callback when the save button is pressed.
  final VoidCallback? onSave;

  /// Callback when the back button is pressed.
  final VoidCallback onBack;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  const ClassInputModal({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isValidating,
    required this.canSave,
    required this.buttonColor,
    this.buttonColorAnimation,
    this.successColorAnimation,
    this.onSave,
    required this.onBack,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primaryText,
          onPressed: onBack,
        ),
        title: Text(
          l10n.setClassTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setClassMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryText,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTextField(context, l10n),
              const SizedBox(height: 24),
              _buildSaveButton(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      inputFormatters: [
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.school, color: AppColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: AppColors.appSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryText,
          ),
      onSubmitted: (_) {
        if (canSave) {
          onSave?.call();
        }
      },
      textCapitalization: TextCapitalization.characters,
      onChanged: onChanged,
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    final animations = <Listenable>[];
    if (buttonColorAnimation != null) animations.add(buttonColorAnimation!);
    if (successColorAnimation != null) animations.add(successColorAnimation!);

    if (animations.isEmpty) {
      return _buildButtonContent(context, l10n);
    }

    return AnimatedBuilder(
      animation: Listenable.merge(animations),
      builder: (context, child) => _buildButtonContent(context, l10n),
    );
  }

  Widget _buildButtonContent(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSave && !isValidating ? onSave : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isValidating
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
                    l10n.setClassButton,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
