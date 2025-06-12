import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
import 'package:lgka_flutter/providers/haptic_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String? dayName; // Optional day name for filename

  const PDFViewerScreen({super.key, required this.pdfFile, this.dayName});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late final PdfController _pdfController;
  bool _hasTriggeredLoadedHaptic = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfFile.path),
    );
    
    // Trigger haptic feedback after a short delay to indicate PDF is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasTriggeredLoadedHaptic) {
          _hasTriggeredLoadedHaptic = true;
          HapticService.pdfLoading();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _sharePdf() async {
    // Subtle haptic feedback when share button is pressed
    await HapticService.subtle();
    
    try {
          // Create a nice filename for sharing
    String fileName;
    if (widget.dayName != null && widget.dayName!.isNotEmpty) {
      final dayFormatted = widget.dayName!.toLowerCase();
      fileName = '${dayFormatted}_vertretungsplan.pdf';
    } else {
      fileName = 'vertretungsplan.pdf';
    }

      // Create a temporary file with the nice name for sharing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await widget.pdfFile.copy(tempFile.path);

      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'LGKA+ Vertretungsplan',
        subject: 'Vertretungsplan - Lessing Gymnasium Karlsruhe',
      );

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // No success message needed - users can see the sharing worked themselves
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Teilen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dayName ?? 'Vertretungsplan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        // Override the back button to add haptic feedback
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primaryText,
          onPressed: () {
            HapticService.subtle(); // Add haptic feedback
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            onPressed: _sharePdf,
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.secondaryText,
            ),
            tooltip: 'PDF teilen',
          ),
        ],
      ),
      body: PdfView(
        controller: _pdfController,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(
            loaderSwitchDuration: Duration.zero, // Remove animation duration
            transitionBuilder: _noTransition, // Use instant transition
          ),
          documentLoaderBuilder: (_) => const SizedBox.shrink(), // Remove document loading spinner
          pageLoaderBuilder: (_) => const SizedBox.shrink(), // Remove page loading spinner
          errorBuilder: (_, error) => Center(child: Text(error.toString())),
          pageBuilder: _pageBuilder,
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _pageBuilder(
    BuildContext context,
    Future<PdfPageImage> pageImage,
    int index,
    PdfDocument document,
  ) {
    return PhotoViewGalleryPageOptions(
      imageProvider: PdfPageImageProvider(
        pageImage,
        index,
        document.id,
      ),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
    );
  }

  // Custom transition that removes all animations
  static Widget _noTransition(Widget child, Animation<double> animation) {
    return child; // Return the widget directly without any animation
  }
} 