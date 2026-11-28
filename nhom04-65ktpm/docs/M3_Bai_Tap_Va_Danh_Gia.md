# M3 - Bài Tập Và Đánh Giá (Issue #3)

Người phụ trách: Nguyễn Huy Hoàng. Nhánh: `feature/nhom04-65ktpm/M3-exercises`.

## 1. Phạm vi đã làm

| Yêu cầu Issue #3 | Trạng thái | Ghi chú |
| --- | --- | --- |
| ≥ 5 bộ đề mẫu, ≥ 100 câu hỏi B1 | Xong | 5 bộ đề, 100 câu trắc nghiệm (mỗi đề 8 Nghe + 12 Đọc), 10 đề Viết, 15 đề Nói |
| Luyện theo kỹ năng + thi thử tổng hợp | Xong | Tab "Theo kỹ năng" (Nghe/Đọc/Viết/Nói) và tab "Thi thử" (đủ 4 kỹ năng) |
| Đồng hồ đếm ngược | Xong | Đếm theo thời lượng phần thi, chuyển đỏ khi còn ≤ 60 giây, hết giờ tự nộp |
| Trình phát audio Nghe | Xong | `just_audio`: phát/tạm dừng, tua ±5 giây, kéo thanh tiến trình, tốc độ 0.75x/1x/1.25x |
| Chấm tự động Nghe/Đọc | Xong | Chấm ngay khi nộp, câu bỏ trống tính sai |
| Đáp án + giải thích tiếng Việt | Xong | Mỗi câu có giải thích; bài Nghe xem được transcript sau khi nộp |
| Rubric Viết/Nói + bài mẫu | Xong | 4 tiêu chí Viết, 5 tiêu chí Nói, mỗi tiêu chí 0–3 điểm; bài mẫu đối chiếu cho từng đề |
| Lưu lịch sử + thống kê theo kỹ năng | Xong | Lưu theo `uid` trên máy; tab "Kết quả": điểm TB, cao nhất, xu hướng 5 lần, kỹ năng yếu nhất |

Ngoài phạm vi (theo đề cương 5.2): không chấm phát âm/bài viết bằng AI, không ghi âm giọng nói.

## 2. Ngân hàng đề

- Dữ liệu: `src/assets/data/m3/set_01.json` … `set_05.json`.
- Chủ đề: (1) Học tập & đời sống sinh viên, (2) Du lịch & giao thông, (3) Sức khỏe & thể thao, (4) Môi trường & công nghệ, (5) Công việc, mua sắm & giải trí.
- Cấu trúc mỗi đề:

| Phần | Nội dung | Số câu | Thời gian |
| --- | --- | --- | --- |
| Listening | Part 1: 4 hội thoại ngắn (1 câu/đoạn); Part 2: 1 hội thoại/bài nói dài (4 câu) | 8 | 20 phút |
| Reading | Part 1: điền từ/ngữ pháp; Part 2: 4 thông báo/tin nhắn ngắn; Part 3: 1 bài đọc 220–300 từ | 12 | 25 phút |
| Writing | Task 1: email 80–100 từ; Task 2: đoạn văn 120–150 từ | 2 đề | 40 phút |
| Speaking | Part 1: giao tiếp xã hội; Part 2: thảo luận giải pháp; Part 3: phát triển chủ đề | 3 đề | 12 phút |

- Cấu trúc trên mô phỏng dạng đề B1 thường gặp (4 kỹ năng, trắc nghiệm A/B/C/D). **Cần đối chiếu với cấu trúc đề chính thức của ĐH Thủy Lợi mà M2 bóc tách** và chỉnh số phần/thời lượng nếu khác. Các đề là đề tự soạn để luyện tập, không phải đề thi thật của trường.
- Audio: `src/assets/audio/m3/<groupId>.m4a` (25 file, ~4,3 MB), sinh từ transcript bằng giọng đọc macOS. Sửa transcript xong chạy lại:

```bash
cd nhom04-65ktpm/src
python3 tool/m3_generate_audio.py --force   # cần macOS (lệnh say) + ffmpeg
```

Khi có file nghe thật của trường, chỉ cần thay file `.m4a` cùng tên.

## 3. Mã bài tập (dùng cho M4)

| Loại | `exerciseId` | Ví dụ |
| --- | --- | --- |
| Luyện Nghe | `ex_listen_<NN>` | `ex_listen_01` |
| Luyện Đọc | `ex_read_<NN>` | `ex_read_03` |
| Luyện Viết | `ex_write_<NN>` | `ex_write_02` |
| Luyện Nói | `ex_speak_<NN>` | `ex_speak_05` |
| Thi thử tổng hợp | `mock_<NN>` | `mock_01` |

`NN` = 01..05. Mã mẫu M4 đang dùng (`ex_listen_01`, `ex_read_01`, `ex_write_01`, `ex_speak_01`) đều mở được. Điều hướng: `context.push(AppRoutes.exerciseDetail('ex_listen_01'))`.

## 4. Kết quả làm bài (hợp đồng dữ liệu với M4/M5)

Mỗi lần nộp bài tạo một `ExerciseAttempt` (`features/assessment/data/models/exercise_attempt.dart`), JSON khớp `users/{uid}/attempts/{attemptId}` trong đề cương 9.6:

```json
{
  "id": "ex_listen_01_1764316800000",
  "exerciseId": "ex_listen_01",
  "setId": "set_01",
  "skill": "listening",
  "scorePercent": 75,
  "durationMinutes": 14,
  "startedAt": "2026-11-28T08:00:00.000Z",
  "completedAt": "2026-11-28T08:13:20.000Z",
  "skillResults": {
    "listening": {"earned": 6, "possible": 8, "scorePercent": 75}
  },
  "answers": {"set_01_l01": 2},
  "responses": {},
  "rubric": {},
  "timedOut": false
}
```

- `skill`: `listening | reading | writing | speaking` (trùng `SkillType.name` của M4); thi thử là `mock`, điểm từng kỹ năng xem trong `skillResults`.
- `scorePercent`: thang 0–100. Nghe/Đọc = câu đúng/tổng câu; Viết/Nói = điểm rubric tự chấm/điểm tối đa; thi thử = trung bình 4 kỹ năng.
- `durationMinutes`: làm tròn lên, tối thiểu 1, để M5 cộng phút học.
- Đọc lịch sử: `context.read<AttemptHistoryProvider>().attempts` (mới nhất trước) hoặc `.summary` (thống kê theo kỹ năng).

Lưu trữ hiện tại: `SharedPreferences` theo `uid` (khóa `m3_attempts_<uid>`, giữ 200 lần gần nhất). Khi M1 chốt bảng Supabase cho attempts, chỉ cần thêm đồng bộ trong `AttemptRepository.save()`.

## 5. Mã nguồn

```text
lib/features/exercises/
├── data/models/exam_models.dart        # ExamSet, ExamSection, QuestionGroup, Question, ProductiveTask
├── data/models/exercise.dart           # Exercise (bài luyện / thi thử)
├── data/repositories/question_bank_repository.dart
├── data/services/audio_controller.dart # interface + just_audio
├── domain/exercise_catalog.dart        # dựng danh mục bài từ ngân hàng đề
└── presentation/
    ├── providers/exercises_provider.dart, exercise_session.dart
    ├── screens/exercises_screen.dart, exercise_detail_screen.dart
    └── widgets/audio_player_bar.dart, question_card.dart, productive_task_view.dart
lib/features/assessment/
├── data/models/exercise_attempt.dart
├── data/repositories/attempt_repository.dart
├── domain/scoring.dart, rubrics.dart, skill_stats.dart
└── presentation/
    ├── providers/attempt_history_provider.dart
    ├── screens/attempt_review_screen.dart
    └── widgets/attempt_result_view.dart, rubric_checklist.dart, skill_stats_panel.dart
```

Thay đổi ngoài thư mục M3 (đã giữ nhỏ): thêm `just_audio` và khai báo assets trong `pubspec.yaml`; đăng ký 2 provider M3 trong `main.dart`; cập nhật `test/widget_test.dart` (thêm provider M3, tab Luyện tập không còn là PlaceholderView).

## 6. Kiểm thử

```bash
cd nhom04-65ktpm/src
flutter test test/features/exercises test/features/assessment
```

40 test, tất cả pass:

- `question_bank_test.dart`: kiểm tra dữ liệu thật — ≥ 5 đề, ≥ 100 câu, id không trùng, đủ 4 phương án khác nhau, có giải thích, file audio tồn tại, mã bài M4 mở được.
- `exam_models_test.dart`, `exercise_catalog_test.dart`, `question_bank_repository_test.dart`: model, mã bài, đọc ngân hàng đề.
- `scoring_test.dart`, `skill_stats_test.dart`: chấm Nghe/Đọc, rubric, đếm từ, JSON attempt, thống kê kỹ năng.
- `attempt_repository_test.dart`: lưu/đọc theo uid, ghi đè, dữ liệu hỏng.
- `exercise_session_test.dart`: luồng làm bài, hết giờ tự nộp, tự đánh giá.
- `exercise_screens_test.dart`: widget test luồng Nghe (audio, đồng hồ, nộp, giải thích), hết giờ, Viết + rubric, màn danh sách.

Lưu ý: trên nhánh nhóm hiện tại `flutter analyze`/`flutter test` toàn dự án còn lỗi có sẵn từ trước ở `learning_path_repository.dart` (M4 vẫn import `cloud_firestore` sau khi M1 chuyển sang Supabase). Phần M3 không có lỗi analyze.
