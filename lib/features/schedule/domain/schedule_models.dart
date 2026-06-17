// Copyright Luka Löhr 2026

/// Represents a schedule PDF with metadata
class ScheduleItem {
  final String title;
  final String url;
  final String halbjahr;
  final String gradeLevel;
  final String fullUrl;

  const ScheduleItem({
    required this.title,
    required this.url,
    required this.halbjahr,
    required this.gradeLevel,
    required this.fullUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'halbjahr': halbjahr,
        'gradeLevel': gradeLevel,
        'fullUrl': fullUrl,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        title: json['title'] as String,
        url: json['url'] as String,
        halbjahr: json['halbjahr'] as String,
        gradeLevel: json['gradeLevel'] as String,
        fullUrl: json['fullUrl'] as String,
      );

  @override
  String toString() {
    return 'ScheduleItem(title: $title, halbjahr: $halbjahr, gradeLevel: $gradeLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleItem &&
        other.title == title &&
        other.url == url &&
        other.halbjahr == halbjahr &&
        other.gradeLevel == gradeLevel &&
        other.fullUrl == fullUrl;
  }

  @override
  int get hashCode {
    return Object.hash(title, url, halbjahr, gradeLevel, fullUrl);
  }
}
