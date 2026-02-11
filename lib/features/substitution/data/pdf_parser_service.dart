// Copyright Luka Löhr 2026

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/substitution_models.dart';

/// Result of parsing an entry
class _ParseResult {
  final List<SubstitutionEntry> entries;
  final SubstitutionType? lastType;
  final int nextIndex;
  
  _ParseResult(this.entries, this.lastType, this.nextIndex);
}

/// Service for parsing substitution PDFs into structured data
class PdfParserService {
  /// Parse a PDF file and extract substitution data
  static Future<ParsedSubstitutionData> parsePdf(File file) async {
    return await compute(_parsePdfInIsolate, await file.readAsBytes());
  }

  /// Parse a PDF file and return JSON string
  static Future<String> parsePdfToJson(File file, {bool pretty = true}) async {
    final data = await parsePdf(file);
    return data.toJsonString(pretty: pretty);
  }

  /// Parse PDF bytes in an isolate
  static ParsedSubstitutionData _parsePdfInIsolate(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      String text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
      document.dispose();

      // Normalize text but preserve newlines
      text = _normalizeText(text);

      // Check if PDF is empty (weekend/holiday)
      if (text.trim().length < 50) {
        return ParsedSubstitutionData.empty();
      }

      // Extract metadata
      final metadata = _extractMetadata(text);
      
      // Extract absent teachers
      final absentTeachers = _extractAbsentTeachers(text);
      
      // Extract duty info (Hofdienst)
      final dutyInfo = _extractDutyInfo(text);
      
      // Extract blocked rooms
      final blockedRooms = _extractBlockedRooms(text);
      
      // Parse substitution entries
      final entries = _parseEntries(text);

      return ParsedSubstitutionData(
        date: metadata['date'] ?? '',
        weekday: metadata['weekday'] ?? '',
        lastUpdated: metadata['lastUpdated'],
        entries: entries,
        absentTeachers: absentTeachers,
        dutyInfo: dutyInfo,
        blockedRooms: blockedRooms,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('PDF Parse Error: $e');
        print(stackTrace);
      }
      return ParsedSubstitutionData.empty();
    }
  }

  /// Normalize text for parsing - preserve newlines for table structure
  static String _normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('\u2060', '')
        .replaceAll('\u2044', '/')
        .replaceAll('\u2215', '/')
        .replaceAll('\u2010', '-')
        .replaceAll('\u2011', '-')
        .replaceAll('\u2012', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2212', '-')
        .trim();
  }

  /// Extract metadata (date, weekday, lastUpdated) from text
  static Map<String, String> _extractMetadata(String text) {
    String weekday = '';
    String date = '';
    String? lastUpdated;

    // Extract last updated timestamp - look for pattern like "10.2.2026 15:25"
    final timestampPattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2})');
    final timestampMatch = timestampPattern.firstMatch(text);
    lastUpdated = timestampMatch?.group(1);

    // Try to find year from footer like "11.2.2026 (7)"
    final footerMatch = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.((?:19|20)\d{2})\s*\(\d+\)')
        .firstMatch(text);
    String? detectedYear = footerMatch?.group(3);

    // Header pattern: "Lessing-Klassen 11.2. / Mittwoch"
    final headerPattern = RegExp(
      r'Lessing\S*Klassen\s+(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
      caseSensitive: false,
    );
    final headerMatch = headerPattern.firstMatch(text);
    
    if (headerMatch != null) {
      final partialDate = headerMatch.group(1);
      final weekdayGroup = headerMatch.group(2);
      if (partialDate != null && weekdayGroup != null) {
        weekday = weekdayGroup;
        final year = detectedYear ?? DateTime.now().year.toString();
        date = '$partialDate$year';
      }
    }

    // Normalize date format
    if (date.isNotEmpty) {
      date = date.replaceAllMapped(
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'),
        (m) {
          final g1 = m.group(1);
          final g2 = m.group(2);
          final g3 = m.group(3);
          if (g1 != null && g2 != null && g3 != null) {
            return '${g1.padLeft(2, '0')}.${g2.padLeft(2, '0')}.$g3';
          }
          return date;
        },
      );
    }

    return {
      'weekday': weekday,
      'date': date,
      'lastUpdated': lastUpdated ?? '',
    };
  }

  /// Extract absent teachers from text
  static List<String> _extractAbsentTeachers(String text) {
    final pattern = RegExp(
      r'Abwesende Lehrer:[\s\n]*([^\n]+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    
    if (match != null) {
      final teachersText = match.group(1) ?? '';
      return teachersText
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty && !t.startsWith('Art'))
          .toList();
    }
    
    return [];
  }

  /// Extract duty info (Hofdienst) from text
  static String? _extractDutyInfo(String text) {
    final pattern = RegExp(
      r'Hofdienst\s+(\S+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Extract blocked rooms from text
  static List<String> _extractBlockedRooms(String text) {
    final pattern = RegExp(
      r'Blockierte Räume:[\s\n]*([^\n]+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    
    if (match != null) {
      final roomsText = match.group(1) ?? '';
      return roomsText
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty && !r.startsWith('Art'))
          .toList();
    }
    
    return [];
  }

  /// Parse substitution entries from the table
  static List<SubstitutionEntry> _parseEntries(String text) {
    final entries = <SubstitutionEntry>[];
    
    // Split into lines
    final lines = text.split('\n');
    
    // Find the table header line index
    int headerIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().toLowerCase() == 'art') {
        headerIndex = i;
        break;
      }
    }
    
    if (headerIndex == -1) return entries;
    
    // Skip header lines (Art, Stunde, Klas.., etc.)
    int currentIndex = headerIndex;
    while (currentIndex < lines.length && 
           (lines[currentIndex].trim().isEmpty ||
            ['art', 'stunde', 'klas..', 'vertret', 'fach', 'raum', '(fach)', '(lehrer)', '(raum)', 'text']
                .contains(lines[currentIndex].trim().toLowerCase()))) {
      currentIndex++;
    }
    
    // Parse entries
    SubstitutionType? currentType;
    
    while (currentIndex < lines.length) {
      final line = lines[currentIndex].trim();
      
      // Check for footer
      if (line.contains('Periode') || line.contains('SJ') && line.contains('20')) {
        break;
      }
      
      // Skip empty lines
      if (line.isEmpty) {
        currentIndex++;
        continue;
      }
      
      // Parse an entry starting from current position
      final result = _parseEntryFromLines(lines, currentIndex, currentType);
      
      if (result != null) {
        entries.addAll(result.entries);
        currentType = result.lastType;
        currentIndex = result.nextIndex;
      } else {
        currentIndex++;
      }
    }
    
    return entries;
  }

  /// Parse a single entry from lines array
  static _ParseResult? _parseEntryFromLines(
    List<String> lines, 
    int startIndex, 
    SubstitutionType? defaultType,
  ) {
    // Type patterns
    final typePatterns = {
      'Betreuung': SubstitutionType.supervision,
      'Entfall': SubstitutionType.cancellation,
      'Verlegung': SubstitutionType.relocation,
      'Tausch': SubstitutionType.exchange,
      'Raum-Vtr.': SubstitutionType.roomChange,
      'Raum- Vtr.': SubstitutionType.roomChange,
      'Raum Vtr.': SubstitutionType.roomChange,
      'Raumvtr.': SubstitutionType.roomChange,
      'Sonderein': SubstitutionType.specialUnit,
      'Sondereinheit': SubstitutionType.specialUnit,
      'Lehrprobe': SubstitutionType.teacherObservation,
      'Unterricht': SubstitutionType.substitution,
      'Vertretung': SubstitutionType.substitution,
    };
    
    if (startIndex >= lines.length) return null;
    
    // First line should be the type or we use default
    String firstLine = lines[startIndex].trim();
    SubstitutionType? type;
    
    for (final entry in typePatterns.entries) {
      if (firstLine == entry.key || firstLine.startsWith(entry.key)) {
        type = entry.value;
        if (firstLine == entry.key) {
          startIndex++; // Consume type line
        }
        break;
      }
    }
    
    type ??= defaultType ?? SubstitutionType.unknown;
    
    if (startIndex >= lines.length) return null;
    
    // Read period
    final period = lines[startIndex].trim();
    if (!_isValidPeriod(period)) return null;
    startIndex++;
    
    if (startIndex >= lines.length) return null;
    
    // Check for period range (e.g., "3 - 4")
    String fullPeriod = period;
    if (startIndex < lines.length && lines[startIndex].trim() == '-') {
      startIndex++; // Skip '-'
      if (startIndex < lines.length) {
        final endPeriod = lines[startIndex].trim();
        fullPeriod = '$period-$endPeriod';
        startIndex++;
      }
    }
    
    if (startIndex >= lines.length) return null;
    
    // Read class(es)
    final classPart = lines[startIndex].trim();
    startIndex++;
    
    final classes = _expandClasses(classPart);
    if (classes.isEmpty) return null;
    
    // Read remaining fields for this entry
    final fields = <String>[];
    while (startIndex < lines.length) {
      final line = lines[startIndex].trim();
      
      // Stop at next type, empty line, or footer
      if (line.isEmpty || 
          _isTypeLine(line) || 
          line.contains('Periode') ||
          (line.contains('SJ') && line.contains('20'))) {
        break;
      }
      
      fields.add(line);
      startIndex++;
    }
    
    if (fields.isEmpty) return null;
    
    // Create entries for each expanded class
    final entries = <SubstitutionEntry>[];
    for (final className in classes) {
      final entry = _createEntryFromFields(
        type: type,
        period: fullPeriod,
        className: className,
        fields: fields,
      );
      if (entry != null) {
        entries.add(entry);
      }
    }
    
    if (entries.isEmpty) return null;
    
    return _ParseResult(entries, type, startIndex);
  }

  /// Check if a line is a type line
  static bool _isTypeLine(String line) {
    final typeWords = [
      'Betreuung', 'Entfall', 'Verlegung', 'Tausch', 
      'Raum-Vtr.', 'Raum-V tr.', 'Raum Vtr.', 'Sonderein', 
      'Lehrprobe', 'Unterricht', 'Vertretung', 'Sondereinheit',
    ];
    final trimmed = line.trim();
    return typeWords.any((t) => trimmed == t || trimmed.startsWith(t));
  }

  /// Check if a string is a valid period
  static bool _isValidPeriod(String period) {
    return RegExp(r'^\d{1,2}$').hasMatch(period);
  }

  /// Expand class abbreviations
  static List<String> _expandClasses(String classPart) {
    final classes = <String>[];
    
    final match = RegExp(r'^([\dJ]+)([a-z]+)?$', caseSensitive: false).firstMatch(classPart);
    if (match == null) {
      return [classPart];
    }
    
    final numberPart = match.group(1) ?? '';
    final letterPart = match.group(2) ?? '';
    
    if (letterPart.isEmpty) {
      return [classPart];
    }
    
    for (final letter in letterPart.split('')) {
      classes.add('$numberPart$letter');
    }
    
    return classes;
  }

  /// Create entry from parsed fields
  static SubstitutionEntry? _createEntryFromFields({
    required SubstitutionType type,
    required String period,
    required String className,
    required List<String> fields,
  }) {
    if (fields.isEmpty) return null;
    
    // Field mapping based on typical structure:
    // 0: Vertret (substitute teacher) or ---
    // 1: Fach (subject) or ---
    // 2: Raum (room) or ---
    // 3: (Fach) original subject or next entry
    // 4: (Lehrer) original teacher
    // 5: (Raum) original room
    // 6+: Text or next type
    
    String substituteTeacher = '';
    String subject = '';
    String room = '';
    String? originalTeacher;
    String? originalSubject;
    String? originalRoom;
    String? text;
    
    int idx = 0;
    
    // Vertret
    if (idx < fields.length && fields[idx] != '---') {
      substituteTeacher = fields[idx];
    }
    idx++;
    
    // Fach
    if (idx < fields.length && fields[idx] != '---') {
      subject = fields[idx];
    }
    idx++;
    
    // Raum
    if (idx < fields.length && fields[idx] != '---') {
      room = fields[idx];
    }
    idx++;
    
    // Look for original info (not --- and not a type)
    if (idx < fields.length && 
        fields[idx] != '---' && 
        !_isTypeLine(fields[idx])) {
      originalSubject = fields[idx];
      idx++;
    }
    
    if (idx < fields.length && 
        fields[idx] != '---' && 
        !_isTypeLine(fields[idx])) {
      originalTeacher = fields[idx];
      idx++;
    }
    
    if (idx < fields.length && 
        fields[idx] != '---' && 
        !_isTypeLine(fields[idx]) &&
        _isRoomLike(fields[idx])) {
      originalRoom = fields[idx];
      idx++;
    }
    
    // Remaining is text
    if (idx < fields.length) {
      final textParts = fields.sublist(idx).where((f) => !_isTypeLine(f)).toList();
      if (textParts.isNotEmpty) {
        text = textParts.join(' ');
      }
    }
    
    return SubstitutionEntry(
      type: type,
      period: period,
      className: className,
      subject: subject,
      room: room,
      substituteTeacher: substituteTeacher,
      originalTeacher: originalTeacher,
      originalSubject: originalSubject,
      originalRoom: originalRoom,
      text: text,
      rawText: fields.join(' '),
    );
  }

  /// Check if string looks like a room
  static bool _isRoomLike(String str) {
    return RegExp(r'^[\dA-Z]').hasMatch(str);
  }

  /// Export parsed data to JSON file
  static Future<void> exportToJsonFile(
    ParsedSubstitutionData data, 
    String filePath, {
    bool pretty = true,
  }) async {
    final file = File(filePath);
    final jsonString = data.toJsonString(pretty: pretty);
    await file.writeAsString(jsonString);
  }

  /// Parse PDF and save JSON to file
  static Future<String> parsePdfAndSaveJson(
    File pdfFile, 
    String outputPath, {
    bool pretty = true,
  }) async {
    final data = await parsePdf(pdfFile);
    await exportToJsonFile(data, outputPath, pretty: pretty);
    return outputPath;
  }

  /// Convert PDF to JSON map (for API usage)
  static Future<Map<String, dynamic>> parsePdfToMap(File file) async {
    final data = await parsePdf(file);
    return data.toJson();
  }
}

/// Extension methods for JSON operations on SubstitutionEntry
extension SubstitutionEntryJson on SubstitutionEntry {
  /// Serialize to JSON string
  String toJsonString() => jsonEncode(toJson());
}

/// Extension methods for JSON operations on ParsedSubstitutionData
extension ParsedSubstitutionDataJson on ParsedSubstitutionData {
  /// Serialize to JSON string
  String toJsonString({bool pretty = false}) {
    final encoder = pretty 
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }
  
  /// Save to JSON file
  Future<void> saveToFile(String path, {bool pretty = true}) async {
    final file = File(path);
    await file.writeAsString(toJsonString(pretty: pretty));
  }
}
