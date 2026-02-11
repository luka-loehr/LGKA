// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../schedule/presentation/schedule_page.dart';
import '../../settings/presentation/settings_modal.dart';
import '../../../../services/haptic_service.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/constrained_modal_bottom_sheet.dart';
import 'drawer_modal.dart';
import '../../../../l10n/app_localizations.dart';

/// Main home screen with schedule as primary view
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize substitution provider
  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(substitutionProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: _buildAppBar(),
      body: const SafeArea(
        child: SchedulePage(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBackground,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        onPressed: () {
          HapticService.light();
          _showDrawer();
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.appSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.menu,
            color: AppColors.primaryText,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'LGKA+',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticService.light();
            _showSettings();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.appSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showConstrainedModalBottomSheet(
      context: context,
      child: const SettingsModal(),
    );
  }

  void _showDrawer() {
    showConstrainedModalBottomSheet(
      context: context,
      child: const DrawerModal(),
    );
  }
}
