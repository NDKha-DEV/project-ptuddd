/// Kỹ năng tiếng Anh B1 và từ vựng dùng trong lộ trình M4.
enum SkillType {
  listening,
  reading,
  writing,
  speaking,
  vocabulary;

  /// Các kỹ năng cốt lõi dùng để tính điểm và cân bằng lộ trình 4 kỹ năng.
  static const List<SkillType> coreSkills = [
    SkillType.listening,
    SkillType.reading,
    SkillType.writing,
    SkillType.speaking,
  ];

  String get key => name;

  String get labelVi {
    switch (this) {
      case SkillType.listening:
        return 'Nghe';
      case SkillType.reading:
        return 'Đọc';
      case SkillType.writing:
        return 'Viết';
      case SkillType.speaking:
        return 'Nói';
      case SkillType.vocabulary:
        return 'Từ vựng';
    }
  }

  static SkillType fromKey(String? key) {
    return SkillType.values.firstWhere(
      (skill) => skill.name == key,
      orElse: () => SkillType.reading,
    );
  }
}

/// Điểm 4 kỹ năng B1 chuẩn hóa theo thang 0..100.
class SkillScores {
  SkillScores({
    required int listening,
    required int reading,
    required int writing,
    required int speaking,
  }) : listening = listening.clamp(0, 100),
       reading = reading.clamp(0, 100),
       writing = writing.clamp(0, 100),
       speaking = speaking.clamp(0, 100);

  factory SkillScores.baseline() {
    return SkillScores(listening: 45, reading: 50, writing: 40, speaking: 40);
  }

  factory SkillScores.fromJson(Map<String, dynamic> json) {
    return SkillScores(
      listening: (json['listening'] as num?)?.round() ?? 45,
      reading: (json['reading'] as num?)?.round() ?? 50,
      writing: (json['writing'] as num?)?.round() ?? 40,
      speaking: (json['speaking'] as num?)?.round() ?? 40,
    );
  }

  final int listening;
  final int reading;
  final int writing;
  final int speaking;

  int scoreOf(SkillType skill) {
    switch (skill) {
      case SkillType.listening:
        return listening;
      case SkillType.reading:
        return reading;
      case SkillType.writing:
        return writing;
      case SkillType.speaking:
        return speaking;
      case SkillType.vocabulary:
        return reading;
    }
  }

  double get averageScore => (listening + reading + writing + speaking) / 4.0;

  /// Trả về kỹ năng có điểm thấp nhất (ưu tiên theo thứ tự Nghe, Đọc, Viết, Nói).
  SkillType get weakestSkill {
    var weakest = SkillType.listening;
    var minScore = listening;
    for (final skill in SkillType.coreSkills.skip(1)) {
      final score = scoreOf(skill);
      if (score < minScore) {
        minScore = score;
        weakest = skill;
      }
    }
    return weakest;
  }

  SkillScores updateSkill(SkillType skill, int newScore) {
    final clamped = newScore.clamp(0, 100);
    switch (skill) {
      case SkillType.listening:
        return copyWith(listening: clamped);
      case SkillType.reading:
      case SkillType.vocabulary:
        return copyWith(reading: clamped);
      case SkillType.writing:
        return copyWith(writing: clamped);
      case SkillType.speaking:
        return copyWith(speaking: clamped);
    }
  }

  SkillScores copyWith({
    int? listening,
    int? reading,
    int? writing,
    int? speaking,
  }) {
    return SkillScores(
      listening: listening ?? this.listening,
      reading: reading ?? this.reading,
      writing: writing ?? this.writing,
      speaking: speaking ?? this.speaking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listening': listening,
      'reading': reading,
      'writing': writing,
      'speaking': speaking,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillScores &&
        other.listening == listening &&
        other.reading == reading &&
        other.writing == writing &&
        other.speaking == speaking;
  }

  @override
  int get hashCode => Object.hash(listening, reading, writing, speaking);
}
