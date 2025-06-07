import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgka_flutter/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfFile.path),
    );
  }

  Future<void> _sharePdf() async {
    try {
      // Create a nice filename for sharing
      String fileName;
      if (widget.dayName != null && widget.dayName!.isNotEmpty) {
        final dayFormatted = widget.dayName!.toLowerCase();
        fileName = '${dayFormatted}_LGKA+.pdf';
      } else {
        fileName = 'vertretungsplan_LGKA+.pdf';
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

      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF erfolgreich geteilt'),
              backgroundColor: AppColors.appBlueAccent,
            ),
          );
        }
      }
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
          'Vertretungsplan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
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
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
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
} 