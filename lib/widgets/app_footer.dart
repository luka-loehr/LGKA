// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';

/// Reusable app footer with copyright and version information.
/// 
/// This is a stateless widget that caches the current year to avoid
/// repeated DateTime.now() calls on every rebuild, improving performance.
class AppFooter extends StatelessWidget {
  final double bottomPadding;
  
  // Cache the current year as a static variable since it rarely changes
  static final int _currentYear = DateTime.now().year;
  
  const AppFooter({
    super.key,
    this.bottomPadding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '© $_currentYear ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText.withValues(alpha: 0.5),
            ),
          ),
          Text(
            'Luka Löhr',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            ' • v${AppInfo.version}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

