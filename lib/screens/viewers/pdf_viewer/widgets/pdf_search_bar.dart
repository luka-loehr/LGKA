import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/app_theme.dart';

/// A search bar overlay for searching within PDF documents.
class PdfSearchBar extends StatelessWidget {
  /// Controller for the search text field.
  final TextEditingController controller;

  /// Focus node for the search text field.
  final FocusNode focusNode;

  /// Whether the search bar is currently visible.
  final bool isVisible;

  /// Callback when the search is submitted.
  final ValueChanged<String> onSubmitted;

  const PdfSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isVisible,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 100),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(context, l10n),
                ),
                const SizedBox(width: 12),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: false, // Focus handled externally
      inputFormatters: [
        LengthLimitingTextInputFormatter(3),
      ],
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.text,
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
        fillColor: AppColors.appBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryText,
          ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Unfocus the TextField first
        focusNode.unfocus();
        final query = controller.text.trim();
        if (query.isNotEmpty) {
          HapticService.medium();
          onSubmitted(query);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Icon(Icons.check, size: 20),
    );
  }
}
