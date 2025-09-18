import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Map<String, String> extractFromBytes(List<int> bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
  document.dispose();

  if (text.trim().length < 50) {
    return {'weekday': 'weekend', 'date': '', 'lastUpdated': ''};
  }

  String weekday = '';
  String date = '';

  final patternA = RegExp(
    r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)[,\s]+' r'(\d{1,2}\.\d{1,2}\.(?:\d{2}|\d{4}))',
    caseSensitive: false,
  );
  final matchA = patternA.firstMatch(text);

  final patternB = RegExp(
    r'(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
    caseSensitive: false,
  );
  final matchB = patternB.firstMatch(text);

  if (matchA != null) {
    weekday = matchA.group(1)!;
    date = matchA.group(2)!;
    date = date.replaceAllMapped(RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2})$'),
        (m) => '${m.group(1)!.padLeft(2, '0')}.${m.group(2)!.padLeft(2, '0')}.20${m.group(3)}');
  } else if (matchB != null) {
    final partialDate = matchB.group(1)!;
    weekday = matchB.group(2)!;
    final start = (matchB.start - 160).clamp(0, text.length);
    final end = (matchB.end + 160).clamp(0, text.length);
    final local = text.substring(start as int, end as int);
    final yearInContext = RegExp(r'(\d{4})').firstMatch(local)?.group(1);
    final year = yearInContext ?? DateTime.now().year.toString();
    date = '$partialDate$year';
  } else {
    final weekdayOnly = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false)
        .firstMatch(text);
    if (weekdayOnly != null) {
      weekday = weekdayOnly.group(1)!;
      final start = (weekdayOnly.start - 160).clamp(0, text.length);
      final end = (weekdayOnly.end + 160).clamp(0, text.length);
      final local = text.substring(start as int, end as int);
      final dateNearby = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(local);
      if (dateNearby != null) {
        date = '${dateNearby.group(1)!.padLeft(2, '0')}.${dateNearby.group(2)!.padLeft(2, '0')}.${dateNearby.group(3)}';
      }
    }
    if (date.isEmpty) {
      final anyDate = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(text);
      if (anyDate != null) {
        date = '${anyDate.group(1)!.padLeft(2, '0')}.${anyDate.group(2)!.padLeft(2, '0')}.${anyDate.group(3)}';
      }
    }
  }

  if (weekday.isNotEmpty) {
    final lower = weekday.toLowerCase();
    weekday = lower[0].toUpperCase() + lower.substring(1);
  }
  if (date.isNotEmpty) {
    date = date.replaceAllMapped(RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'),
        (m) => '${m.group(1)!.padLeft(2, '0')}.${m.group(2)!.padLeft(2, '0')}.${m.group(3)}');
  }

  final ts = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2})').firstMatch(text)?.group(1) ?? '';
  return {'weekday': weekday, 'date': date, 'lastUpdated': ts};
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/parse_pdf_standalone.dart <path-to-pdf>');
    exit(2);
  }
  final file = File(args[0]);
  if (!await file.exists()) {
    stderr.writeln('File not found: ${file.path}');
    exit(2);
  }
  final bytes = await file.readAsBytes();
  final result = extractFromBytes(bytes);
  stdout.writeln('weekday=${result['"' + 'weekday' + '"']}'
      .replaceAll('"', '"'));
  stdout.writeln('date=${result['"' + 'date' + '"']}'
      .replaceAll('"', '"'));
  stdout.writeln('lastUpdated=${result['"' + 'lastUpdated' + '"']}'
      .replaceAll('"', '"'));
}

