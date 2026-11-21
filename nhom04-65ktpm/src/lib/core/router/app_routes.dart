/// Đường dẫn route dùng chung. Module nào thêm màn hình thì khai báo ở đây
/// để các module khác điều hướng tới (ví dụ M4 mở bài tập của M3).
class AppRoutes {
  AppRoutes._();

  static const login = '/login';

  // Tab chính
  static const home = '/home'; // M5 - Daily You
  static const materials = '/materials'; // M2
  static const exercises = '/exercises'; // M3
  static const learningPath = '/learning-path'; // M4
  static const profile = '/profile'; // M1

  // Màn hình chi tiết
  static String materialDetail(String materialId) => '$materials/$materialId';
  static String exerciseDetail(String exerciseId) => '$exercises/$exerciseId';
}
