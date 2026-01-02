import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/app_theme.dart';

/// A search bar overlay for searching within PDF documents.
class PdfSearchBar extends StatefulWidget {
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
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _canSubmit {
    return widget.controller.text.trim().length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 100),
      child: IgnorePointer(
        ignoring: !widget.isVisible,
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
      controller: widget.controller,
      focusNode: widget.focusNode,
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
      onSubmitted: (_) {
        if (_canSubmit) {
          widget.onSubmitted(widget.controller.text.trim());
        }
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final buttonColor = _canSubmit
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _canSubmit
            ? () {
                // Unfocus the TextField first
                widget.focusNode.unfocus();
                final query = widget.controller.text.trim();
                HapticService.medium();
                widget.onSubmitted(query);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
