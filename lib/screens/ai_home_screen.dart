import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/haptic_service.dart';
import '../data/substitution_model.dart';
import '../navigation/app_router.dart';

// Helper function for robust navigation bar detection across all Android devices
bool _isButtonNavigation(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final gestureInsets = mediaQuery.systemGestureInsets.bottom;
  final viewPadding = mediaQuery.viewPadding.bottom;
  
  if (gestureInsets >= 45) {
    // Very likely button navigation - high confidence
    return true;
  } else if (gestureInsets <= 25) {
    // Very likely gesture navigation - high confidence
    return false;
  } else {
    // Ambiguous range (26-44) - use viewPadding as secondary indicator
    // Button navigation typically has higher viewPadding
    return viewPadding > 50;
  }
}

class AiHomeScreen extends ConsumerStatefulWidget {
  const AiHomeScreen({super.key});

  @override
  ConsumerState<AiHomeScreen> createState() => _AiHomeScreenState();
}

class _AiHomeScreenState extends ConsumerState<AiHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock-Daten für Demo
  final Map<String, List<Substitution>> _mockData = {
    'Montag': [
      Substitution(
        className: '9b',
        lesson: '3',
        subject: 'Mathematik',
        room: 'A201',
        substitutionTeacher: 'Herr Schmidt',
        type: 'Vertretung',
        text: 'Hausaufgaben kontrollieren',
      ),
      Substitution(
        className: '9b',
        lesson: '5-6',
        subject: 'Englisch',
        room: 'B102',
        substitutionTeacher: 'Frau Weber',
        type: 'Vertretung',
        text: 'Unit 4 wiederholen',
      ),
    ],
    'Dienstag': [
      Substitution(
        className: '9b',
        lesson: '2',
        subject: 'Deutsch',
        room: 'C205',
        substitutionTeacher: 'Herr Müller',
        type: 'Vertretung',
        text: 'Gedichtanalyse besprechen',
      ),
      Substitution(
        className: '9b',
        lesson: '7',
        subject: 'Geschichte',
        room: 'fällt aus',
        substitutionTeacher: '',
        type: 'Entfall',
        text: 'Stunde entfällt',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mockData.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheetContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferencesManager = ref.watch(preferencesManagerProvider);
    final userClassFromState = ref.watch(userClassProvider);
    final userClass = (userClassFromState ?? preferencesManager.userClass)?.toUpperCase() ?? 'KLASSE';

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'Vertretungen für $userClass',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              HapticService.subtle();
              _showSettingsBottomSheet();
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.secondaryText,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.appBlueAccent,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.appBlueAccent,
          indicatorWeight: 3,
          tabs: _mockData.keys.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _mockData.entries.map((entry) {
          final day = entry.key;
          final substitutions = entry.value;

          if (substitutions.isEmpty) {
            return _EmptyState(day: day);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: substitutions.length,
                  itemBuilder: (context, index) {
                    return _SubstitutionCard(substitution: substitutions[index]);
                  },
                ),
              ),
              // Footer with version and copyright at bottom
              Padding(
                padding: EdgeInsets.only(
                  bottom: _isButtonNavigation(context)
                    ? 34.0  // Button navigation (3 buttons) - 26px higher than gesture nav
                    : 8.0,   // Gesture navigation (white bar) - perfect position
                ),
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? snapshot.data!.version : '1.5.5';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '© 2025 ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          'Luka Löhr',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.appBlueAccent.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • v$version',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText.withOpacity(0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SubstitutionCard extends StatelessWidget {
  final Substitution substitution;

  const _SubstitutionCard({required this.substitution});

  @override
  Widget build(BuildContext context) {
    final isEntfall = substitution.type == 'Entfall';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEntfall 
              ? Colors.red.withOpacity(0.3)
              : AppColors.appBlueAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEntfall 
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.appBlueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${substitution.lesson}. Stunde',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isEntfall ? Colors.red : AppColors.appBlueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEntfall 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  substitution.type,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isEntfall ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Subject
          Text(
            substitution.subject,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Details
          if (!isEntfall) ...[
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Lehrer',
              value: substitution.substitutionTeacher,
            ),
            _DetailRow(
              icon: Icons.room_outlined,
              label: 'Raum',
              value: substitution.room,
            ),
          ],
          
          if (substitution.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.info_outline,
              label: 'Hinweis',
              value: substitution.text,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String day;

  const _EmptyState({required this.day});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Vertretungen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Für $day sind keine Vertretungen für deine Klasse eingetragen.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Footer with version and copyright at bottom
        Padding(
          padding: EdgeInsets.only(
            bottom: _isButtonNavigation(context)
              ? 34.0  // Button navigation (3 buttons) - 26px higher than gesture nav
              : 8.0,   // Gesture navigation (white bar) - perfect position
          ),
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? snapshot.data!.version : '1.5.5';
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '© 2025 ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    'Luka Löhr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.appBlueAccent.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ' • v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsSheetContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        _isButtonNavigation(context)
          ? 54.0  // Button navigation (3 buttons) - higher position
          : 24.0,   // Gesture navigation (white bar) - normal padding
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Einstellungen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.class_outlined, color: AppColors.appBlueAccent),
            title: const Text('Klasse ändern'),
            subtitle: Text('Aktuelle Klasse: ${ref.watch(preferencesManagerProvider).userClass?.toUpperCase() ?? 'Nicht festgelegt'}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              // Navigation zur Klassenauswahl
              context.push(AppRouter.classSelector);
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppColors.appBlueAccent),
            title: const Text('Zur einfachen Version wechseln'),
            subtitle: const Text('PDF-Ansicht verwenden'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final preferencesManager = ref.read(preferencesManagerProvider);
              await preferencesManager.setUseAiVersion(false);
              
              // Aktualisiere auch den State Provider für sofortigen Rebuild
              ref.read(useAiVersionProvider.notifier).state = false;
              
              Navigator.pop(context);
              // Der Home Screen rebuildet automatisch durch den StateProvider
            },
          ),
        ],
      ),
    );
  }
} 