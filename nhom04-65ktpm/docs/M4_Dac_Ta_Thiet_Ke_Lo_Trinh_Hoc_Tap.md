# Đặc Tả Thiết Kế Module M4 – Lộ Trình Học Tập (TLU B1 Daily)

- **Đề tài:** TLU B1 Daily – Ứng dụng hỗ trợ sinh viên Thủy Lợi ôn luyện tiếng Anh B1 và xây dựng thói quen học tập hằng ngày
- **Module phụ trách:** M4 – Lộ trình học tập (`Issue #4`)
- **Thành viên thực hiện:** Nguyễn Tùng Dương (MSV: `2351170588` – Lớp `65KTPM`)
- **Vị trí mã nguồn dự kiến (sau khi M1 khởi tạo `src/`):**
  - `nhom04-65ktpm/src/lib/features/learning_path/`
  - `nhom04-65ktpm/src/test/features/learning_path/`

---

## 1. Mục Tiêu Và Phạm Vi Module M4

Module M4 chịu trách nhiệm biến dữ liệu đầu vào của sinh viên (ngày thi B1 dự kiến, quỹ thời gian 30/45/60 phút/ngày, kết quả khảo sát đầu vào và điểm luyện tập từ M3) thành lộ trình ôn tập cá nhân hóa theo tuần và theo từng ngày, đồng thời mở rộng phần gợi ý cơ hội thực hành tiếng Anh thực tế.

### 1.1. Lộ trình thực hiện 3 tuần (16/11/2026 – 06/12/2026)

| Giai đoạn | Công việc chính | Kết quả bàn giao |
| :--- | :--- | :--- |
| **Tuần 1** (16/11 – 22/11) | - Thiết kế bài khảo sát đầu vào B1<br>- Thiết kế thuật toán sinh lộ trình tuần/ngày<br>- Thiết kế khung UI lộ trình học tập B1 | Tài liệu đặc tả thiết kế M4; khung màn hình và logic sinh lộ trình sẵn sàng tích hợp vào `src/` của M1 |
| **Tuần 2** (23/11 – 29/11) | - Liên kết nhiệm vụ ngày sang M2 (tài liệu) & M3 (bài tập)<br>- Tự động cập nhật tiến độ/lộ trình theo điểm M3<br>- (Tùy chọn) Danh sách tour dẫn tiếng Anh / CLB giao lưu & lưu quan tâm | Luồng M4 chạy hoàn chỉnh, đồng bộ Firestore & điều hướng liên module |
| **Tuần 3** (30/11 – 06/12) | - Viết unit test cho thuật toán & kiểm thử luồng M4<br>- Làm mượt UX, sửa lỗi liên kết với M2/M3/M5<br>- Viết phần báo cáo M4 & kịch bản demo | Kiểm thử đạt, kịch bản demo và tài liệu báo cáo M4 |

### 1.2. Giới hạn ngoài phạm vi
- Không xây dựng tính năng chat trực tiếp, gọi video hoặc ghép cặp thời gian thực với khách du lịch nước ngoài trong app.
- Phần thực hành tour tiếng Anh giữ ở mức danh sách thông tin sự kiện/tour uy tín tại Hà Nội, mẫu câu giao tiếp dẫn tour gợi ý, lưu quan tâm và đặt nhắc lịch.

---

## 2. Thiết Kế Bài Khảo Sát Đầu Vào B1 (Initial Assessment)

### 2.1. Mục đích
Xác định nhanh điểm xuất phát của sinh viên theo 4 kỹ năng chuẩn đầu ra B1 ĐH Thủy Lợi (`listening`, `reading`, `writing`, `speaking`) để làm đầu vào cho thuật toán phân bổ lộ trình.

### 2.2. Cấu trúc khảo sát 2 bước
1. **Bước 1 – Thiết lập thông tin mục tiêu (kế thừa/đồng bộ từ M1):**
   - Ngày dự kiến thi B1 (`examDate`, mặc định gợi ý 8 tuần kể từ ngày bắt đầu nếu sinh viên chưa có lịch thi cụ thể).
   - Quỹ thời gian cam kết mỗi ngày: `30`, `45`, hoặc `60` phút/ngày (`dailyMinutes`).
   - Tự đánh giá mức tự tin hiện tại ở 4 kỹ năng (Nghe, Đọc, Viết, Nói) theo thang 1–5.
2. **Bước 2 – Kiểm tra nhanh năng lực nền tảng (Mini Diagnostic, ~5–7 phút):**
   - Gồm 10 câu trắc nghiệm rút gọn đại diện cho Nghe & Đọc B1 + 2 câu tự đánh giá năng lực Viết/Nói theo tiêu chí quen thuộc của đề TLU.
   - Hỗ trợ tùy chọn **"Bỏ qua kiểm tra, bắt đầu từ mức nền tảng"** (khi đó dùng mức điểm mặc định từ Bước 1 để sinh lộ trình ngay, tránh cản trở trải nghiệm ban đầu).

### 2.3. Đầu ra chuẩn hóa (`InitialAssessmentResult`)
- Điểm từng kỹ năng quy đổi về thang `0..100`:
  - `listeningScore`, `readingScore`, `writingScore`, `speakingScore`
- Xếp loại sơ bộ theo kỹ năng:
  - `< 45`: **Cần củng cố nền tảng** (ưu tiên cao)
  - `45 – 69`: **Trung bình – cần luyện tập đều** (ưu tiên vừa)
  - `>= 70`: **Khá tốt – duy trì & nâng cao** (ưu tiên ôn tập/thi thử)

---

## 3. Đặc Tả Thuật Toán Sinh Lộ Trình Tuần / Ngày

### 3.1. Đầu vào thuật toán (`LearningPathInput`)
- `uid`: Mã định danh sinh viên (từ M1).
- `startDate`: Ngày bắt đầu lộ trình (`yyyy-MM-dd`).
- `examDate`: Ngày dự kiến thi B1 (tối thiểu cách `startDate` 7 ngày; nếu nhỏ hơn 7 ngày thì sinh chế độ *Ôn tập nước rút 7 ngày*).
- `dailyMinutes`: Quỹ thời gian học mỗi ngày (`30`, `45`, `60`).
- `skillScores`: Bản đồ điểm 4 kỹ năng (`listening`, `reading`, `writing`, `speaking`), khởi tạo từ bài khảo sát đầu vào và được cập nhật liên tục từ kết quả M3.
- `availableMaterials`: Danh sách học liệu từ M2 (`b1_materials`).
- `availableExercises`: Danh sách bài tập/đề thi từ M3 (`b1_exercises`).

### 3.2. Các bước sinh lộ trình

#### Bước 1: Chia giai đoạn theo tổng số ngày ôn tập (`totalDays`)
Tính `totalDays = max(7, examDate - startDate)` và `totalWeeks = ceil(totalDays / 7)`. Chia thành 3 chặng theo tỷ lệ thời gian:
1. **Chặng 1 – Củng cố nền tảng (~40% số tuần đầu):** Từ vựng theo chủ đề trọng tâm B1, ngữ pháp cốt lõi (M2) kết hợp bài tập ngắn Nghe/Đọc cơ bản (M3).
2. **Chặng 2 – Luyện kỹ năng trọng tâm (~40% số tuần giữa):** Tăng cường bài tập chuyên sâu theo từng kỹ năng còn yếu, luyện mẫu câu & dàn ý Viết – Nói (M2/M3).
3. **Chặng 3 – Tổng ôn & Thi thử (~20% số tuần cuối, tối thiểu 1 tuần):** Thi thử tổng hợp theo định dạng đề B1 Thủy Lợi (M3) và rà soát lỗ hổng kiến thức.

#### Bước 2: Tính trọng số ưu tiên theo kỹ năng yếu
Với mỗi kỹ năng $s \in \{\text{listening}, \text{reading}, \text{writing}, \text{speaking}\}$:
- Mức độ cần bù đắp: $gap_s = \max(10,\ 100 - score_s)$.
- Chuẩn hóa thành tỷ lệ phân bổ slot học trong tuần:
  $$w_s = \frac{gap_s}{\sum_{k} gap_k}$$
- Ràng buộc cân bằng: mỗi tuần (7 ngày) đảm bảo mỗi kỹ năng đều có tối thiểu **1 nhiệm vụ** để tránh học lệch, đồng thời kỹ năng có $score_s$ thấp nhất được ưu tiên nhiều nhiệm vụ hơn.

#### Bước 3: Đóng gói nhiệm vụ từng ngày vừa khít quỹ thời gian (`30 / 45 / 60` phút)
Mỗi ngày gồm danh sách `DailyTask` có tổng `estimatedMinutes` nằm trong khoảng mục tiêu `dailyMinutes`:
- **Mức 30 phút/ngày** (2 nhiệm vụ):
  - Task 1 (15 phút): Học tài liệu / từ vựng / ngữ pháp trọng tâm (liên kết **M2**).
  - Task 2 (15 phút): Bài tập thực hành ngắn theo kỹ năng mục tiêu (liên kết **M3**).
- **Mức 45 phút/ngày** (2–3 nhiệm vụ):
  - Task 1 (15 phút): Ôn tài liệu / cấu trúc bài thi (M2).
  - Task 2 (20 phút): Luyện bài tập Nghe hoặc Đọc (M3).
  - Task 3 (10 phút): Ôn nhanh từ vựng hoặc dàn ý Viết/Nói (M2/M3).
- **Mức 60 phút/ngày** (3 nhiệm vụ):
  - Task 1 (20 phút): Học chuyên đề tài liệu + từ vựng (M2).
  - Task 2 (25 phút): Luyện đề / bài tập theo kỹ năng (M3).
  - Task 3 (15 phút): Thực hành checklist Viết/Nói hoặc ôn lại câu sai (M3).

*(Trong mỗi tuần có 1 ngày ôn tập tổng hợp / thi thử ngắn cuối tuần để đánh giá lại tiến độ).*

### 3.3. Cơ chế cập nhật động theo kết quả M3 & đồng bộ M5
1. **Khi người dùng hoàn thành 1 nhiệm vụ ngày (`DailyTask`):**
   - Đánh dấu `status = 'completed'`, ghi `completedAt` và cập nhật phần trăm hoàn thành của ngày/tuần.
   - Phát thông tin số phút học thực tế sang **M5 (Daily You)** để cộng dồn tiến độ 30–60 phút/ngày và tính streak.
2. **Khi có kết quả làm bài từ M3 (`users/{uid}/attempts/{attemptId}`):**
   - Cập nhật điểm kỹ năng tương ứng theo trung bình trượt (ví dụ: `newScore = 0.4 * oldScore + 0.6 * attemptPercent`) để phản ánh đúng phong độ hiện tại.
   - Nếu điểm kỹ năng giảm xuống dưới `60%` (hoặc thấp hơn ngưỡng mục tiêu), thuật toán **tái phân bổ lại các ngày chưa hoàn thành (`status == 'pending'`)** từ ngày hiện tại trở đi để bổ sung thêm bài luyện cho kỹ năng đó — **không sửa đổi hoặc xóa các ngày đã qua/đã hoàn thành**.
3. **Khi người dùng đổi `dailyMinutes` hoặc `examDate` ở M1:**
   - Gọi hàm tái lập lịch cho phần tương lai, giữ nguyên lịch sử đã học.

---

## 4. Hợp Đồng Dữ Liệu (Data Contract) & Cấu Trúc Firestore

Khớp theo Mục 9.6 của Đề cương:

### 4.1. Collection `users/{uid}/learning_paths/{planId}`
```json
{
  "planId": "active_plan",
  "startDate": "2026-11-20",
  "examDate": "2027-01-15",
  "dailyMinutes": 45,
  "initialScores": {
    "listening": 50,
    "reading": 60,
    "writing": 45,
    "speaking": 40
  },
  "currentScores": {
    "listening": 55,
    "reading": 62,
    "writing": 45,
    "speaking": 40
  },
  "currentWeek": 1,
  "totalWeeks": 8,
  "completionRate": 0.12,
  "updatedAt": "2026-11-20T09:00:00Z",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "Tuần 1: Củng cố nền tảng Nghe – Đọc & Từ vựng cơ bản",
      "phase": "foundation",
      "days": [
        {
          "dayIndex": 1,
          "date": "2026-11-20",
          "focusSkill": "speaking",
          "totalMinutes": 45,
          "tasks": [
            {
              "taskId": "w1_d1_t1",
              "title": "Từ vựng chủ đề Sinh hoạt & Học tập B1",
              "skill": "vocabulary",
              "targetModule": "M2",
              "targetResourceId": "mat_vocab_01",
              "estimatedMinutes": 15,
              "status": "pending"
            },
            {
              "taskId": "w1_d1_t2",
              "title": "Luyện Nghe Part 1 – Hội thoại ngắn",
              "skill": "listening",
              "targetModule": "M3",
              "targetResourceId": "ex_listen_01",
              "estimatedMinutes": 30,
              "status": "pending"
            }
          ]
        }
      ]
    }
  ]
}
```

### 4.2. Collection `english_tours/{tourId}` (Tính năng mở rộng Tuần 2)
```json
{
  "tourId": "tour_hanoi_free_walking_01",
  "title": "Hanoi Free Walking Tour – Khu phố cổ & Hồ Hoàn Kiếm",
  "organizer": "Hanoi Kids / CLB Hướng dẫn viên tình nguyện",
  "scheduleText": "Thứ Bảy & Chủ Nhật hằng tuần, 08:30 – 11:30",
  "location": "Tượng đài Lý Thái Tổ, Hoàn Kiếm, Hà Nội",
  "levelRecommended": "A2–B1",
  "samplePhrases": [
    "Welcome to Hanoi! Let me introduce a bit about this historic area...",
    "Would you like me to explain the story behind Ngoc Son Temple?"
  ],
  "sourceUrl": "https://example.org",
  "lastVerifiedAt": "2026-11-18"
}
```
- Trạng thái sinh viên lưu quan tâm tour được lưu theo `uid` (ví dụ `users/{uid}/saved_tours/{tourId}` hoặc trường `savedTourIds` trong `users/{uid}/learning_paths/active_plan`), kèm tùy chọn đặt nhắc lịch cục bộ trước giờ sự kiện.

### 4.3. Giao diện liên kết giữa các Module
- **Nhận từ M1:** `uid`, `examDate`, `dailyMinutes` (`30 | 45 | 60`), route config trong `go_router`, trạng thái quản lý state (Provider/Riverpod theo chốt của M1).
- **Điều hướng sang M2:** Mở màn hình chi tiết tài liệu theo `targetResourceId` (`materialId`) và nhận callback khi người dùng đánh dấu đã đọc/học xong tài liệu.
- **Điều hướng sang M3:** Mở màn hình bài tập/đề thi theo `targetResourceId` (`exerciseId`) và đọc kết quả `attempt` trả về (`scorePercent`, `skill`, `durationMinutes`).
- **Gửi sang M5:** Thông báo hoàn thành nhiệm vụ + thời lượng thực học (`durationMinutes`) để M5 cập nhật tiến độ mục tiêu ngày & streak.

---

## 5. Thiết Kế Giao Diện & Luồng Màn Hình M4

1. **`OnboardingSurveyScreen` (Khảo sát đầu vào B1):**
   - Thanh tiến trình 2 bước, thẻ chọn mức tự tin 4 kỹ năng, mini-quiz 10 câu rút gọn, nút **"Bỏ qua & tạo lộ trình nền tảng"**, nút **"Tạo lộ trình của tôi"**.
2. **`LearningPathScreen` (Màn hình chính Tab Lộ trình):**
   - **Thẻ tổng quan trên cùng:** Số ngày còn lại tới kỳ thi B1, thanh tiến độ lộ trình tổng thể, nút xem phân tích 4 kỹ năng & nút **"Khảo sát lại / Điều chỉnh lộ trình"**.
   - **Bộ chọn Tuần (Week Selector):** Thanh cuộn ngang `Tuần 1`, `Tuần 2`, ..., hiển thị trạng thái hoàn thành từng tuần.
   - **Danh sách Nhiệm vụ theo Ngày:** Mở rộng ngày hôm nay mặc định; mỗi `DailyTask` hiển thị badge kỹ năng (Nghe/Đọc/Viết/Nói/Từ vựng), thời lượng ước tính (`15p`, `20p`, `30p`), nút hành động **"Học ngay"** (điều hướng sang M2/M3) và trạng thái hoàn thành.
   - **Banner/Mục tùy chọn (Tuần 2):** Thẻ **"Thực hành giao tiếp thực tế – Tour dẫn tiếng Anh & CLB"** dẫn tới `EnglishToursScreen`.
3. **`EnglishToursScreen` & `TourDetailScreen` (Tuần 2 – Tùy chọn):**
   - Danh sách tour dẫn tiếng Anh / CLB giao lưu tại Hà Nội, lọc theo ngày cuối tuần/trình độ, xem chi tiết địa điểm, mẫu câu giao tiếp dẫn tour gợi ý, nút **"Quan tâm / Lưu"** và **"Đặt nhắc lịch"**.

---

## 6. Kế Hoạch Kiểm Thử (Tuần 3 & Song Song Khi Code)

- **Unit Tests (`test/features/learning_path/`):**
  - Sinh lộ trình hợp lệ cho các mốc quỹ thời gian `30`, `45`, `60` phút/ngày (tổng phút mỗi ngày khớp mục tiêu).
  - Xử lý biên `examDate`: sát ngày thi (`< 7 ngày`), trung hạn (`4 tuần`), dài hạn (`12 tuần`).
  - Phân bổ ưu tiên kỹ năng có điểm khảo sát thấp nhất nhận nhiều slot luyện tập hơn.
  - Cập nhật lại lộ trình khi có điểm mới từ M3 nhưng vẫn bảo toàn các ngày đã `completed`.
- **Widget Tests:**
  - Luồng hoàn thành/bỏ qua `OnboardingSurveyScreen`.
  - Hiển thị danh sách tuần/ngày, chuyển tuần và đánh dấu hoàn thành nhiệm vụ trên `LearningPathScreen`.

---

## 7. Bước Tiếp Theo Khi M1 Đẩy Khung Dự Án `src/`

Ngay khi M1 hoàn tất khởi tạo `nhom04-65ktpm/src/` và chốt thư viện quản lý trạng thái (`Provider` hoặc `Riverpod`), module M4 sẽ triển khai code theo cấu trúc:
```text
nhom04-65ktpm/src/
├── lib/features/learning_path/
│   ├── data/
│   │   ├── models/           # LearningPath, WeekPlan, DayPlan, DailyTask, AssessmentResult, EnglishTour
│   │   └── repositories/     # LearningPathRepository (Firestore + fallback offline)
│   ├── domain/
│   │   └── services/         # LearningPathGenerator (thuật toán sinh & tái cân bằng lộ trình)
│   └── presentation/
│       ├── providers/        # State management cho khảo sát, lộ trình & tour
│       ├── screens/          # OnboardingSurveyScreen, LearningPathScreen, EnglishToursScreen, TourDetailScreen
│       └── widgets/          # WeekSelector, DayTaskCard, SkillRadar/BarSummary
└── test/features/learning_path/
    └── learning_path_generator_test.dart
```
