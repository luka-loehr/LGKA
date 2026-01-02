import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_logger.dart';

/// Service for sharing PDF documents.
class PdfShareService {
  /// Shares the PDF file with a nicely formatted filename.
  /// 
  /// [pdfFile] - The PDF file to share.
  /// [dayName] - Optional day name used to determine the filename.
  /// [shareButtonKey] - GlobalKey of the share button for iPad popover positioning.
  /// [l10n] - Localization instance for translated strings.
  static Future<void> sharePdf({
    required File pdfFile,
    required String? dayName,
    required GlobalKey? shareButtonKey,
    required AppLocalizations l10n,
  }) async {
    try {
      // Create a nice filename for sharing
      String fileName;
      String subject;

      if (dayName != null && dayName.isNotEmpty) {
        // Check if this is a schedule (contains "Klassen" or "J11/J12")
        if (dayName.contains('Klassen') || dayName.contains('J11/J12')) {
          // This is a schedule PDF
          final cleanName = dayName
              .replaceAll('Klassen ', '')
              .replaceAll('J11/J12', 'J11-12')
              .replaceAll(' - ', '_')
              .replaceAll(' ', '');
          fileName = '${l10n.filenameSchedulePrefix}$cleanName.pdf';
          subject = l10n.subjectSchedule;
        } else {
          // This is a substitution plan
          final dayFormatted = dayName.toLowerCase();
          fileName = '${l10n.filenameSubstitutionPrefix}$dayFormatted.pdf';
          subject = l10n.subjectSubstitution;
        }
      } else {
        fileName = 'LGKA_Document.pdf';
        subject = 'LGKA+ Document';
      }

      // Create a temporary file with the nice name for sharing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await pdfFile.copy(tempFile.path);

      // Calculate share button position for iPad popover positioning
      Rect? sharePositionOrigin;
      if (Platform.isIOS && shareButtonKey != null) {
        final RenderBox? renderBox =
            shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          sharePositionOrigin = Rect.fromLTWH(
            position.dx,
            position.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      AppLogger.error('Error sharing PDF: $e', module: 'PdfShareService');
      rethrow;
    }
  }
}
