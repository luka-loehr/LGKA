// Copyright Luka Löhr 2025

import 'dart:io';

/// Represents the state of a single substitution PDF (today or tomorrow)
class SubstitutionState {
  final bool isLoading;
  final bool hasData;
  final String? error;
  final String? weekday;
  final String? date;
  final String? lastUpdated;
  final File? file;
  final DateTime? downloadTimestamp; // Debug: timestamp when PDF was downloaded

  const SubstitutionState({
    this.isLoading = false,
    this.hasData = false,
    this.error,
    this.weekday,
    this.date,
    this.lastUpdated,
    this.file,
    this.downloadTimestamp,
  });

  SubstitutionState copyWith({
    bool? isLoading,
    bool? hasData,
    String? error,
    String? weekday,
    String? date,
    String? lastUpdated,
    File? file,
    DateTime? downloadTimestamp,
  }) {
    return SubstitutionState(
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      error: error,
      weekday: weekday,
      date: date,
      lastUpdated: lastUpdated,
      file: file,
      downloadTimestamp: downloadTimestamp ?? this.downloadTimestamp,
    );
  }

  /// Returns true if this PDF represents a weekend/holiday (no data)
  bool get isWeekend => weekday == 'weekend';
  
  /// Returns true if this PDF can be displayed
  bool get canDisplay {
    final hasWeekday = (weekday != null && weekday!.isNotEmpty && weekday != 'weekend');
    final hasDateString = (date != null && date!.isNotEmpty);
    return hasData && hasWeekday && hasDateString && file != null;
  }
}
