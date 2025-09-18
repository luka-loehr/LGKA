import 'dart:io';
import 'package:lgka_flutter/data/pdf_repository.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/parse_pdf_debug.dart <path-to-pdf>');
    exit(2);
  }
  final file = File(args[0]);
  if (!await file.exists()) {
    stderr.writeln('File not found: ${file.path}');
    exit(2);
  }
  final bytes = await file.readAsBytes();
  final result = debugExtractPdfDataFromBytes(bytes);
  stdout.writeln('weekday=${result['weekday']}');
  stdout.writeln('date=${result['date']}');
  stdout.writeln('lastUpdated=${result['lastUpdated']}');
}

