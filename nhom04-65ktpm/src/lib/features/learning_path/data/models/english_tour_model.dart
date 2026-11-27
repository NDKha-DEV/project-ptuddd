import 'package:flutter/foundation.dart';

/// Thông tin tour dẫn tiếng Anh / CLB giao lưu thực tế tại Hà Nội (english_tours/{tourId}).
class EnglishTour {
  const EnglishTour({
    required this.tourId,
    required this.title,
    required this.organizer,
    required this.scheduleText,
    required this.location,
    required this.levelRecommended,
    required this.samplePhrases,
    required this.sourceUrl,
    required this.lastVerifiedAt,
  });

  factory EnglishTour.fromJson(Map<String, dynamic> json) {
    final rawPhrases = json['samplePhrases'] as List<dynamic>? ?? const [];
    return EnglishTour(
      tourId: json['tourId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      organizer: json['organizer'] as String? ?? '',
      scheduleText: json['scheduleText'] as String? ?? '',
      location: json['location'] as String? ?? '',
      levelRecommended: json['levelRecommended'] as String? ?? 'A2–B1',
      samplePhrases: rawPhrases.map((phrase) => phrase.toString()).toList(),
      sourceUrl: json['sourceUrl'] as String? ?? '',
      lastVerifiedAt: json['lastVerifiedAt'] as String? ?? '',
    );
  }

  final String tourId;
  final String title;
  final String organizer;
  final String scheduleText;
  final String location;
  final String levelRecommended;
  final List<String> samplePhrases;
  final String sourceUrl;
  final String lastVerifiedAt;

  bool get isWeekend {
    final lower = scheduleText.toLowerCase();
    return lower.contains('thứ bảy') ||
        lower.contains('chủ nhật') ||
        lower.contains('cuối tuần') ||
        lower.contains('weekend');
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'title': title,
      'organizer': organizer,
      'scheduleText': scheduleText,
      'location': location,
      'levelRecommended': levelRecommended,
      'samplePhrases': samplePhrases,
      'sourceUrl': sourceUrl,
      'lastVerifiedAt': lastVerifiedAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnglishTour &&
        other.tourId == tourId &&
        other.title == title &&
        other.organizer == organizer &&
        other.scheduleText == scheduleText &&
        other.location == location &&
        other.levelRecommended == levelRecommended &&
        listEquals(other.samplePhrases, samplePhrases) &&
        other.sourceUrl == sourceUrl &&
        other.lastVerifiedAt == lastVerifiedAt;
  }

  @override
  int get hashCode => Object.hash(
    tourId,
    title,
    organizer,
    scheduleText,
    location,
    levelRecommended,
    Object.hashAll(samplePhrases),
    sourceUrl,
    lastVerifiedAt,
  );
}
