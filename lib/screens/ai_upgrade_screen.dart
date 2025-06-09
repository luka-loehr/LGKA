import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';

class AiUpgradeScreen extends ConsumerWidget {
  const AiUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header with Brain Icon and Title
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.appBlueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 60,
                      color: AppColors.appBlueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NEU: KI in der LGKA+ App',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erlebe Vertretungspläne auf eine völlig neue Art',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Benefits List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _FeatureCard(
                        icon: Icons.smart_toy_outlined,
                        title: 'Intelligente Aufbereitung',
                        description: 'Deine Vertretungen werden automatisch für deine Klasse gefiltert und übersichtlich dargestellt.',
                        gradient: LinearGradient(
                          colors: [AppColors.appBlueAccent.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _FeatureCard(
                        icon: Icons.schedule_outlined,
                        title: 'Strukturierte Übersicht',
                        description: 'Alle wichtigen Infos auf einen Blick: Stunde, Fach, Lehrer, Raum und Hinweise.',
                        gradient: LinearGradient(
                          colors: [Colors.green.withOpacity(0.1), AppColors.appBlueAccent.withOpacity(0.1)],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _FeatureCard(
                        icon: Icons.trending_up_outlined,
                        title: 'Immer aktuell',
                        description: 'Automatische Updates alle 5 Minuten sorgen dafür, dass du nie etwas verpasst.',
                        gradient: LinearGradient(
                          colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.1)],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _FeatureCard(
                        icon: Icons.phone_android_outlined,
                        title: 'Perfekte Bedienung',
                        description: 'Einfach zwischen den Tagen wischen und alle Infos sofort finden.',
                        gradient: LinearGradient(
                          colors: [Colors.teal.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Column(
                children: [
                  // Primary Button - Switch to AI
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await HapticService.medium();
                        
                        // Switch to AI version
                        final preferencesManager = ref.read(preferencesManagerProvider);
                        await preferencesManager.setUseAiVersion(true);
                        ref.read(useAiVersionProvider.notifier).state = true;
                        
                        // Navigate to class selector if no class is set
                        if (preferencesManager.userClass == null) {
                          context.pushReplacement(AppRouter.classSelector);
                        } else {
                          context.pushReplacement(AppRouter.home);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appBlueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Jetzt zur KI-Version wechseln',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary Button - Maybe Later
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticService.subtle();
                        // Check if we can pop (showing from within app) or need to replace (initial route)
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // If this is the initial route, navigate to home
                          context.pushReplacement(AppRouter.home);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Jetzt nicht',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.appBlueAccent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.appBlueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.appBlueAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 