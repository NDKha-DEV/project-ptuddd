# nhom04-65ktpm

Thư mục làm việc của nhóm `nhom04-65ktpm` trong học phần Phát Triển Ứng Dụng Di Động (PTUDDD).

## Cấu Trúc Thư Mục

```text
nhom04-65ktpm/
├── danhsachnhom.md   # Thông tin thành viên và phân công (bắt buộc)
├── README.md         # Hướng dẫn cài đặt, chạy ứng dụng của nhóm
├── docs/             # Tài liệu đặc tả, báo cáo đồ án (PDF/DOCX)
└── src/              # Mã nguồn của dự án
```

## Tổng Quan Dự Án

**TLU B1 Daily** - ứng dụng Flutter hỗ trợ sinh viên Thủy Lợi ôn luyện tiếng Anh B1 và xây dựng thói quen học tập hằng ngày.

- Flutter 3 / Dart 3, định tuyến `go_router`, quản lý trạng thái `provider`.
- Supabase Auth/Postgres (nền tảng cấu hình ở M1-01).
- Kiến trúc feature-first, mỗi module một thư mục riêng trong `src/lib/features/`.

### Cấu trúc mã nguồn `src/lib/`

```text
lib/
├── main.dart                 # Khởi tạo Firebase, đăng ký provider
├── app.dart                  # MaterialApp.router + theme
├── core/                     # Dùng chung (M1 quản lý)
│   ├── constants/            # Tên app, tên collection Firestore
│   ├── router/               # app_router.dart, app_routes.dart
│   ├── services/             # firebase_bootstrap.dart
│   ├── theme/
│   └── widgets/              # LoadingView, ErrorView, PlaceholderView
├── shell/home_shell.dart     # Thanh điều hướng 5 tab
└── features/
    ├── auth/, profile/, settings/    # M1 - Nền tảng và tài khoản
    ├── b1_materials/                 # M2 - Tài liệu tiếng Anh B1
    ├── exercises/, assessment/       # M3 - Bài tập và đánh giá
    ├── learning_path/                # M4 - Lộ trình học tập
    └── habit_stats/                  # M5 - Thói quen và thống kê
```

Mỗi feature chia 3 tầng:

```text
features/<ten_feature>/
├── data/models/          # Model + fromJson/toJson
├── data/repositories/    # Đọc/ghi Firestore, SQLite
├── domain/               # Logic thuần (tính điểm, sinh lộ trình, streak...)
└── presentation/
    ├── providers/        # ChangeNotifier
    ├── screens/
    └── widgets/
```

Test đặt tương ứng trong `src/test/features/<ten_feature>/`.

### Phân công thư mục

| Module | Thành viên           | Thư mục                                         | Route                                  |
| ------ | -------------------- | ----------------------------------------------- | -------------------------------------- |
| M1     | Nguyễn Đình Kha      | `core/`, `features/auth`, `profile`, `settings` | `/login`, `/profile`                   |
| M2     | Trịnh Quốc Bảo       | `features/b1_materials`                         | `/materials`, `/materials/:materialId` |
| M3     | Nguyễn Huy Hoàng     | `features/exercises`, `assessment`              | `/exercises`, `/exercises/:exerciseId` |
| M4     | Nguyễn Tùng Dương    | `features/learning_path`                        | `/learning-path`                       |
| M5     | Nguyễn Ngọc Thành An | `features/habit_stats`                          | `/home`                                |

Quy ước để tránh xung đột:

- Chỉ sửa trong thư mục module của mình. Cần sửa `core/`, `main.dart`, `app_router.dart` hoặc `pubspec.yaml` thì báo nhóm, giữ thay đổi nhỏ.
- Điều hướng giữa module dùng `AppRoutes` (ví dụ `context.push(AppRoutes.exerciseDetail(id))`), không gõ chuỗi đường dẫn trực tiếp.
- Tên collection Firestore lấy từ `FirestoreCollections`.
- Màn `PlaceholderView` hiện tại chỉ là tạm, module nào làm xong giao diện thì thay.

## Cài Đặt

Yêu cầu:

- Flutter stable **3.47** trở lên (`flutter --version`, cập nhật bằng `flutter upgrade`).
- Android Studio (Android SDK + máy ảo) hoặc điện thoại Android bật USB debugging.
- Xcode nếu chạy iOS (chỉ macOS).

```bash
cd nhom04-65ktpm/src
flutter pub get
flutter doctor
```

### Supabase

M1-01 đã tích hợp `supabase_flutter`. Truyền cấu hình qua dart-define; không ghi key vào source:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<https://project-ref.supabase.co> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Không dùng service_role key và không commit file cấu hình chứa giá trị thật. Xem chi tiết `docs/M1_IMPLEMENTATION_PLAN.md`.

## Khởi Chạy

```bash
cd nhom04-65ktpm/src
flutter run                # chọn thiết bị Android/iOS
flutter analyze            # kiểm tra lỗi trước khi commit
flutter test               # chạy test
```

## Quy Trình Làm Việc

1. Lấy nhánh nhóm mới nhất: `git checkout nhom04-65ktpm && git pull origin nhom04-65ktpm`.
2. Tạo nhánh module từ nhánh nhóm, ví dụ `feature/nhom04-65ktpm/M3-exercises`.
3. Commit theo mẫu `feat(nhom04-65ktpm): ...`, chỉ `git add nhom04-65ktpm/`.
4. Trước khi mở PR: `flutter analyze` và `flutter test` phải sạch.
5. Mở PR vào nhánh `nhom04-65ktpm`, ghi `Closes #<số issue>` khi hoàn thành module.

## Tài Liệu

- `docs/De_cuong_cuoi_ky_SpeakEnglish_Nhom4.docx` - Đề cương đồ án.
- `docs/M4_Dac_Ta_Thiet_Ke_Lo_Trinh_Hoc_Tap.md` - Đặc tả M4.
