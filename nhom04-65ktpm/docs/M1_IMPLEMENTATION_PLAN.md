# M1 Implementation Plan — TLU B1 Daily

## 1. Scope M1-01 — Supabase Foundation

Trạng thái: **Done** (đã commit trong `a8d9001`).

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

## 4. Scope M1-02 — Auth State Foundation

Trạng thái: **Done** (đã commit trong `a8d9001`).

### Đã làm

- `AuthProvider` đăng ký `Supabase.instance.client.auth.onAuthStateChange` và đọc `currentSession` trong `initialize()`.
- State công khai: `user`, `uid`, `isSignedIn`, `isInitializing`, `isLoading`, `error`.
- `signOut()` gọi `Supabase.instance.client.auth.signOut()`; bỏ hoàn toàn `signInAsGuest`.
- `main.dart` tạo `AuthProvider`, `await initialize()` trước `runApp()`.
- Giữ nguyên GoRouter; chỉ thêm nhánh `isInitializing` để không redirect nhầm lúc session đang được khôi phục.
- `LoginScreen` vô hiệu hóa nút guest, chờ M1-03; không còn auth giả trong UI.
- Thêm scaffold Windows (`windows/`) để chạy thử desktop theo nghiệm thu.

### Ngoài phạm vi M1-02

Không triển khai Login/Register UI, Google OAuth, Forgot Password, schema/RLS, Storage, settings/profile UI.

## 5. Kiểm tra M1-02

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` — 5 tests (bootstrap, khởi tạo provider, stream auth, redirect/login, 5 tab). |
| `flutter run -d windows` với dart-define | Build `tlu_b1_daily.exe` thành công; log `Supabase init completed`; app chạy đến khi tool ngắt phiên. |
| Guest/mock auth | Không còn `signInAsGuest`, không còn uid `'guest'`. |
| Routing/UI | Giữ `AppRoutes`, `GoRouter`, `HomeShell`, `LoginScreen`, `ProfileScreen`; chỉ sửa redirect lúc initializing và nút guest. |
| Secret | Không có URL/key thật trong file tracked. |

## 6. Scope M1-03 — Login/Register email/password

Trạng thái: **Done** (chưa commit).

### Đã làm

- `AuthProvider` thêm `signInWithPassword({email, password})` và `signUp({email, password})`: loading/error/notice, chặn submit lặp, map lỗi Supabase thường gặp.
- `signUp()` phân biệt có session (đăng ký xong vào app) và `session == null` (cần xác nhận email); thông báo qua `notice`.
- Thêm `AuthFormMode` và `AuthForm` dùng chung cho login/register: validate email, mật khẩu >= 6, xác nhận mật khẩu, hiển thị error/notice, vô hiệu hóa nút khi loading.
- `LoginScreen` dùng `AuthForm` thay placeholder; thêm `RegisterScreen`.
- Thêm `AppRoutes.register`; `GoRouter` cho phép `/login` và `/register` khi chưa signed in, redirect cả hai về home khi đã signed in.
- Thêm test form/provider/navigation và test signIn thật với thông tin sai (có dart-define); cập nhật widget test cũ.

### Ngoài phạm vi M1-03

Không triển khai Google OAuth, Forgot Password, Profile/Settings, schema/RLS, Storage.

## 7. Kiểm tra M1-03

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` — 10 tests (bootstrap, signIn thật với sai thông tin, provider, auth form, redirect/navigation, 5 tab). |
| `flutter run -d windows` với dart-define | Build `tlu_b1_daily.exe` thành công; log `Supabase init completed`; app chạy ổn định đến khi tool ngắt phiên. |
| SignIn qua Supabase thật với sai thông tin | `All tests passed!`: trả `false`, có error, không throw. |
| Đăng ký/đăng nhập thành công bằng tài khoản thật | Chưa chạy: không có credentials và không tạo tài khoản thật để tránh side effect; luồng đã gọi `signUp`/`signInWithPassword`, xử lý error/notice. |
| Secret trong source/Git | Không có URL/key thật nào được ghi vào file tracked. |

## 8. Danh sách task M1 (đề xuất, cập nhật theo thực tế)

| Task | Mục tiêu | Trạng thái | Phụ thuộc |
|---|---|---|---|
| M1-01 | Supabase SDK + client bootstrap + env config | **Done** | — |
| M1-02 | Auth state thật trên Supabase Auth; thay guest uid bằng `User?`, loading/error | **Done** | M1-01 |
| M1-03 | Register + Login email/password, route và form | **Done** | M1-02 |
| M1-04 | Session persistence + logout thật qua Supabase | Partial — SDK giữ session và `signOut()` đã dùng Supabase; chưa test flow logout riêng | M1-02 |
| M1-05 | Google OAuth + cấu hình native redirect | Not started | M1-01, M1-02 |
| M1-06 | Forgot password | Not started | M1-03 |
| M1-07 | Profile model + repository Supabase/Postgres (khi có schema) | Not started | M1-02, schema/RLS |
| M1-08 | Profile UI thay placeholder | Partial — placeholder, logout đã gọi Supabase | M1-07 |
| M1-09 | Settings: mục tiêu 30/45/60, giờ nhắc, sáng/tối | Not started | M1-02, M1-07 |
| M1-10 | Shared UI: dùng `LoadingView`/`ErrorView`, thêm button/card/dialog dùng chung | Partial | M1-02 |
| M1-11 | Security Rules/RLS + schema tối thiểu | Not started | Quyết định data model |
| M1-12 | Unit/widget test cho auth, redirect, logout, settings | Partial — có bootstrap/provider/redirect/login/register; chưa có settings | M1-02 trở đi |

## 9. Nguyên tắc khi triển khai tiếp

- Giữ `provider`, `GoRouter`, `AppRoutes`, `HomeShell`, `AppTheme` hiện tại; chỉ mở rộng.
- Mọi truy cập Supabase đi qua `Supabase.instance.client` sau `SupabaseBootstrap.init()`.
- Không khôi phục Firebase dưới bất kỳ hình thức nào (dependency, bootstrap, config, collection name).
- Không gán schema bảng/Storage trong M1-01; chờ task data model riêng.
- Trước khi merge: `flutter analyze`, `flutter test`, kiểm tra `git diff` không chứa publishable key/service role key.
