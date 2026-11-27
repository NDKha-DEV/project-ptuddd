# M1 Implementation Plan — TLU B1 Daily

## 1. Scope M1-01 — Supabase Foundation

Trạng thái: **Done** (chưa commit).

Mục tiêu: thay nền tảng Firebase tạm bằng Supabase Flutter SDK, khởi tạo `SupabaseClient` từ cấu hình môi trường, giữ nguyên Provider, GoRouter, theme và UI hiện tại.

### Đã làm

- Thêm `supabase_flutter: ^2.18.3`; gỡ `firebase_core`, `firebase_auth`, `cloud_firestore`.
- Xóa `lib/core/services/firebase_bootstrap.dart`; thay bằng `lib/core/services/supabase_bootstrap.dart`.
- Đọc cấu hình qua `String.fromEnvironment` trong `lib/core/config/app_env.dart`:
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`
- `main.dart` gọi `SupabaseBootstrap.init()` trước `runApp()`.
- `AuthProvider` đổi tham số `firebaseReady` → `supabaseReady`; routing/UI giữ nguyên.
- Bỏ class `FirestoreCollections` không còn dùng; không thay bằng schema Supabase.
- Thêm test khởi tạo client: `test/core/services/supabase_bootstrap_test.dart`.

### Ngoài phạm vi M1-01

Không triển khai: Auth flows (login/register), Google OAuth, database schema/RLS, Storage, upload file, profile data, settings UI, reminder, dark-mode toggle.

## 2. Cấu hình môi trường

Không lưu key trong source. Truyền khi chạy/build:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<https://project-ref.supabase.co> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Có thể dùng file local bị gitignore, ví dụ `.env.json`:

```json
{
  "SUPABASE_URL": "<https://project-ref.supabase.co>",
  "SUPABASE_PUBLISHABLE_KEY": "<publishable-key>"
}
```

sau đó:

```bash
flutter run --dart-define-from-file=.env.json
```

Chỉ dùng **publishable key**. Không dùng service_role key/secret key và không commit file cấu hình chứa giá trị thật.

## 3. Kiểm tra M1-01

| Kiểm tra | Kết quả |
|---|---|
| `flutter pub get` | Thành công; lock có `supabase_flutter 2.18.3`; không còn entry Firebase. |
| `flutter analyze` | `No issues found!` |
| `flutter test` với dart-define | `All tests passed!` (3 tests, gồm test khởi tạo Supabase). |
| `GET /auth/v1/settings` với publishable key | `HTTP 200` — project reachable và key hợp lệ. |
| `GET /rest/v1/` | `HTTP 401` — không có bảng/schema nào được triển khai; nằm ngoài M1-01. |
| `flutter build apk --debug` | Chưa chạy được: máy hiện tại không có Android SDK (`ANDROID_HOME`). |
| Secret trong source/Git | Không có URL/key thật nào được ghi vào file tracked. |

## 4. Danh sách task M1 (đề xuất, cập nhật theo thực tế)

| Task | Mục tiêu | Trạng thái | Phụ thuộc |
|---|---|---|---|
| M1-01 | Supabase SDK + client bootstrap + env config | **Done** | — |
| M1-02 | Auth state thật trên Supabase Auth; thay guest uid bằng `User?`, loading/error | Not started | M1-01 |
| M1-03 | Register + Login email/password, route và form | Not started | M1-02 |
| M1-04 | Session persistence + logout thật qua Supabase | Not started | M1-02 |
| M1-05 | Google OAuth + cấu hình native redirect | Not started | M1-01, M1-02 |
| M1-06 | Forgot password | Not started | M1-03 |
| M1-07 | Profile model + repository Supabase/Postgres (khi có schema) | Not started | M1-02, schema/RLS |
| M1-08 | Profile UI thay placeholder | Partial — hiện chỉ placeholder + logout tạm | M1-07 |
| M1-09 | Settings: mục tiêu 30/45/60, giờ nhắc, sáng/tối | Not started | M1-02, M1-07 |
| M1-10 | Shared UI: dùng `LoadingView`/`ErrorView`, thêm button/card/dialog dùng chung | Partial | M1-02 |
| M1-11 | Security Rules/RLS + schema tối thiểu | Not started | Quyết định data model |
| M1-12 | Unit/widget test cho auth, redirect, logout, settings | Partial | M1-02 trở đi |

## 5. Nguyên tắc khi triển khai tiếp

- Giữ `provider`, `GoRouter`, `AppRoutes`, `HomeShell`, `AppTheme` hiện tại; chỉ mở rộng.
- Mọi truy cập Supabase đi qua `Supabase.instance.client` sau `SupabaseBootstrap.init()`.
- Không khôi phục Firebase dưới bất kỳ hình thức nào (dependency, bootstrap, config, collection name).
- Không gán schema bảng/Storage trong M1-01; chờ task data model riêng.
- Trước khi merge: `flutter analyze`, `flutter test`, kiểm tra `git diff` không chứa publishable key/service role key.
