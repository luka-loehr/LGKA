/// PDF Viewer module.
///
/// This module provides a complete PDF viewing experience with:
/// - PDF document display
/// - Text search functionality
/// - Class-based navigation (for school schedules)
/// - PDF sharing
///
/// Usage:
/// ```dart
/// import 'package:lgka_flutter/screens/viewers/pdf_viewer/pdf_viewer.dart';
///
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PDFViewerScreen(pdfFile: file),
///   ),
/// );
/// ```
library pdf_viewer;

export 'models/search_result.dart';
export 'pdf_viewer_screen.dart';
export 'services/pdf_search_service.dart';
export 'services/pdf_share_service.dart';
export 'widgets/class_input_modal.dart';
export 'widgets/pdf_search_bar.dart';
