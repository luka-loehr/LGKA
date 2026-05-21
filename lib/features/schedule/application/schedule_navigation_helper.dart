// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/schedule_models.dart';
import 'schedule_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';

/// Extension on BuildContext to centralize schedule fetching, downloading,
/// progress indication, and PDF viewer routing logic.
extension ScheduleNavigationHelper on BuildContext {
  Future<void> openScheduleForClass(
    WidgetRef ref,
    List<ScheduleItem> group,
    String? selectedClass,
  ) async {
    final l10n = AppLocalizations.of(this)!;
    final notifier = ref.read(scheduleProvider.notifier);
    final scheduleState = ref.read(scheduleProvider);

    // Determine which PDF to open based on selected class
    final isJahrgang = selectedClass != null && selectedClass.startsWith('j');
    ScheduleItem? target;
    if (isJahrgang) {
      target = group.where((s) => s.gradeLevel == 'J11/J12').firstOrNull;
    }
    // Fall back to Klassen 5-10 for non-Jahrgang or if J11/J12 is not found
    target ??= group.where((s) => s.gradeLevel == 'Klassen 5-10').firstOrNull;
    target ??= group.firstOrNull;

    if (target == null) return;

    final halbjahr = target.halbjahr;
    final halfLabel = _localizeHalbjahr(l10n, halbjahr);
    final title = selectedClass != null
        ? _formatClassName(l10n, selectedClass)
        : _localizeGradeLevel(l10n, target.gradeLevel);
    final dayName = '$title – $halfLabel';

    // Look up target page from the appropriate index
    List<int>? targetPages;
    if (selectedClass != null && scheduleState.isIndexBuilt) {
      final page = isJahrgang
          ? notifier.getClassPageJ(selectedClass)
          : notifier.getClassPage(selectedClass);
      if (page != null) targetPages = [page];
    }

    // Check cached file
    final cached = await notifier.getCachedScheduleFile(target);
    if (cached != null && await cached.exists()) {
      if (mounted) {
        push(
          AppRouter.pdfViewer,
          extra: {
            'file': cached,
            'dayName': dayName,
            'targetPages': ?targetPages,
            'isSchedule': true,
            'gradeLevel': target.gradeLevel,
          },
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(dialogCtx).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(AppLocalizations.of(dialogCtx)!.loadingSchedule),
          ],
        ),
      ),
    );

    notifier.downloadSchedule(target).then((file) {
      if (!mounted) return;
      Navigator.of(this).pop();

      if (file != null) {
        // Re-fetch class page in case index was built during download
        if (selectedClass != null && scheduleState.isIndexBuilt) {
          final page = isJahrgang
              ? notifier.getClassPageJ(selectedClass)
              : notifier.getClassPage(selectedClass);
          if (page != null) targetPages = [page];
        }
        push(
          AppRouter.pdfViewer,
          extra: {
            'file': file,
            'dayName': dayName,
            'targetPages': ?targetPages,
            'isSchedule': true,
            'gradeLevel': target!.gradeLevel,
          },
        );
      } else {
        ScaffoldMessenger.of(this).showSnackBar(
          SnackBar(
            content: Text(
              '$halfLabel ${AppLocalizations.of(this)!.scheduleNotAvailable}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }).catchError((e) {
      if (!mounted) return;
      Navigator.of(this).pop();
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(this)!.errorLoadingGeneric),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  String _formatClassName(AppLocalizations l, String className) {
    if (className == 'j11') return l.jahrgang11;
    if (className == 'j12') return l.jahrgang12;
    return l.klasseLabel(
      '${className[0].toUpperCase()}${className.substring(1)}',
    );
  }

  String _localizeGradeLevel(AppLocalizations l, String gradeLevel) {
    if (gradeLevel == 'Klassen 5-10') return l.grades5to10;
    if (gradeLevel == 'J11/J12') return l.j11j12;
    return gradeLevel;
  }

  String _localizeHalbjahr(AppLocalizations l, String halbjahr) {
    if (halbjahr == '1. Halbjahr') return l.firstSemester;
    if (halbjahr == '2. Halbjahr') return l.secondSemester;
    return halbjahr;
  }
}
