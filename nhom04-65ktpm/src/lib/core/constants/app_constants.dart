class AppConstants {
  AppConstants._();

  static const appName = 'TLU B1 Daily';

  /// Quỹ thời gian học mỗi ngày (phút) mà sinh viên được chọn.
  static const dailyMinuteOptions = [30, 45, 60];
}

/// Tên collection Firestore, khớp Mục 9.6 của đề cương.
/// Dùng hằng số này thay vì gõ chuỗi trực tiếp.
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const b1Materials = 'b1_materials';
  static const b1Exercises = 'b1_exercises';
  static const englishTours = 'english_tours';

  // Sub-collection dưới users/{uid}
  static const attempts = 'attempts';
  static const learningPaths = 'learning_paths';
  static const dailyLogs = 'daily_logs';
}
