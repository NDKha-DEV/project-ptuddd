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
| Session persistence/logout | Implementation có từ M1-02; đã xác minh thực tế tại M1-04. |

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
| Đăng ký thành công bằng tài khoản thật | Chưa chạy: không tạo tài khoản thật để tránh side effect; luồng `signUp` đã được kiểm tra ở mức gọi API/xử lý error/notice. Đăng nhập thành công đã xác minh thực tế tại M1-04. |
| Secret trong source/Git | Không có URL/key thật nào được ghi vào file tracked. |

## 8. Scope M1-04 — Session Persistence & Logout

Trạng thái: **Done** — implementation hoàn thành từ M1-02; M1-04 không cần bổ sung code.

### Đã làm

- Session persistence dùng implementation của M1-02: `SupabaseBootstrap.init()`, `currentSession` và `onAuthStateChange` trong `AuthProvider`.
- Logout dùng `AuthProvider.signOut()` từ M1-02, gọi `Supabase.instance.client.auth.signOut()`.
- Không phát sinh code mới trong M1-04; chỉ kiểm thử thực tế trên ứng dụng.

### Ngoài phạm vi M1-04

Không thay đổi Login/Register, Google OAuth, Forgot Password, Profile/Settings, schema/RLS, Storage.

## 9. Kiểm tra M1-04

| Kiểm tra | Kết quả |
|---|---|
| Đăng nhập thành công | Đã xác minh trên ứng dụng: đăng nhập bằng tài khoản Supabase thành công. |
| Duy trì session sau khi mở lại app | Đã xác minh: đóng app hoàn toàn rồi mở lại, session vẫn được duy trì. |
| Logout thành công | Đã xác minh: `signOut()` đăng xuất thành công. |
| Điều hướng sau logout | Đã xác minh: app điều hướng về màn Login. |
| Không tự khôi phục sau logout | Đã xác minh: đóng/mở app lại sau logout, không tự khôi phục phiên đăng nhập. |

Tổng kết: M1-04 Done; implementation có từ M1-02, không bổ sung code, đã xác minh hành vi thực tế trên ứng dụng.

## 10. Scope M1-05 — Google OAuth + Native Redirect

Trạng thái: **Triển khai xong ở mức code/UI** — chưa xác minh native callback trên thiết bị/emulator Android.

### Đã làm

- `AuthProvider.signInWithGoogle()` gọi `Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: AppConstants.oauthRedirectTo)`.
- Dùng lại `onAuthStateChange` hiện tại; không tạo session manager hay routing architecture mới. `isGoogleSignInPending` chặn OAuth request lặp; timeout 2 phút chỉ giải phóng pending UI, không hủy browser OAuth và notice nêu rõ phiên vẫn có thể cập nhật khi quay lại; lỗi callback đi qua `_handleAuthError`.
- `SupabaseBootstrap.init()` khai báo rõ `FlutterAuthClientOptions(detectSessionInUri: true, authFlowType: AuthFlowType.pkce)` để SDK xử lý deep link callback.
- `LoginScreen`/`AuthForm` thêm divider `OR` và nút `Continue with Google` chỉ ở chế độ login; `RegisterScreen` giữ nguyên.
- Android manifest thêm custom scheme `vn.edu.tlu.nhom04.tlu-b1-daily://login-callback` và tắt Flutter deep linking để `app_links` của Supabase xử lý callback.
- Không thêm dependency OAuth, không dùng Firebase, không lưu Client Secret trong Flutter/Git/docs.

### Ngoài phạm vi M1-05

Không triển khai Profile, Forgot Password, Settings, database schema/RLS hoặc module M2-M5.

## 11. Cấu hình cần thao tác thủ công

### Google Cloud Console

1. Tạo/chọn OAuth client loại **Web application** cho project dùng làm backend Supabase.
2. Trong **Authorized redirect URIs**, thêm `https://<PROJECT_REF>.supabase.co/auth/v1/callback` (thay `<PROJECT_REF>` bằng project ref của Supabase).
3. Cấu hình OAuth consent screen theo policy của project.
4. Lấy `Client ID` và `Client secret`; chỉ dán vào Supabase Dashboard, không ghi vào Flutter/Git/docs.

### Supabase Dashboard

1. Authentication → Providers → Google: bật provider và dán Client ID/Client Secret từ Google Cloud.
2. Authentication → URL Configuration → Additional Redirect URLs: thêm `vn.edu.tlu.nhom04.tlu-b1-daily://login-callback`.
3. Không dùng service_role key cho Flutter; ứng dụng chỉ dùng publishable key.

### Flutter/Android

- Scheme/host trong `android/app/src/main/AndroidManifest.xml` phải khớp `AppConstants.oauthRedirectTo`.
- Không cần dart-define mới cho redirect URI; đây là callback public, không phải secret.
- Windows chạy luồng OAuth qua browser; native callback chỉ được cấu hình cho Android và chưa thử trên thiết bị/emulator.

## 12. Kiểm tra M1-05

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` — 14 tests (bootstrap, signIn thật với sai thông tin, provider/Google guard, OAuth pending/timeout/auth state, auth form/Google button, redirect/navigation, 5 tab). OAuth pending/timeout chỉ chạy thật khi có dart-define Supabase; không có config vẫn pass nhưng skip nội bộ. |
| `flutter run -d windows` với dart-define | Build `tlu_b1_daily.exe` thành công; log `Supabase init completed`; app chạy đến khi tool ngắt phiên. |
| Google OAuth end-to-end | Chưa chạy: cần Google Cloud/Supabase provider được cấu hình và thiết bị Android để xác minh callback. |
| Android native redirect | Chưa xác minh trên thiết bị/emulator; chỉ khai báo manifest và redirect URL trong code/config. |
| build APK | Không chạy theo yêu cầu; môi trường hiện tại cũng không có Android SDK. |

## 13. Danh sách task M1 (đề xuất, cập nhật theo thực tế)

| Task | Mục tiêu | Trạng thái | Phụ thuộc |
|---|---|---|---|
| M1-01 | Supabase SDK + client bootstrap + env config | **Done** | — |
| M1-02 | Auth state thật trên Supabase Auth; thay guest uid bằng `User?`, loading/error | **Done** | M1-01 |
| M1-03 | Register + Login email/password, route và form | **Done** | M1-02 |
| M1-04 | Session persistence + logout thật qua Supabase | **Done** — Session persistence và logout dùng implementation từ M1-02, đã kiểm thử thực tế thành công. | M1-02 |
| M1-05 | Google OAuth + cấu hình native redirect | **Done (code/UI)** — tích hợp Supabase OAuth, UI và Android redirect; chưa xác minh callback trên Android device | M1-01, M1-02 |
| M1-06 | Forgot password | Not started | M1-03 |
| M1-07 | Profile model + repository Supabase/Postgres (khi có schema) | Not started | M1-02, schema/RLS |
| M1-08 | Profile UI thay placeholder | Partial — placeholder, logout đã gọi Supabase | M1-07 |
| M1-09 | Settings: mục tiêu 30/45/60, giờ nhắc, sáng/tối | Not started | M1-02, M1-07 |
| M1-10 | Shared UI: dùng `LoadingView`/`ErrorView`, thêm button/card/dialog dùng chung | Partial | M1-02 |
| M1-11 | Security Rules/RLS + schema tối thiểu | Not started | Quyết định data model |
| M1-12 | Unit/widget test cho auth, redirect, logout, settings | Partial — có bootstrap/provider/redirect/login/register/Google UI; session persistence/logout đã xác minh thực tế tại M1-04; chưa có settings | M1-02 trở đi |

## 14. Nguyên tắc khi triển khai tiếp

- Giữ `provider`, `GoRouter`, `AppRoutes`, `HomeShell`, `AppTheme` hiện tại; chỉ mở rộng.
- Mọi truy cập Supabase đi qua `Supabase.instance.client` sau `SupabaseBootstrap.init()`.
- Không khôi phục Firebase dưới bất kỳ hình thức nào (dependency, bootstrap, config, collection name).
- Không gán schema bảng/Storage trong M1-01; chờ task data model riêng.
- Trước khi merge: `flutter analyze`, `flutter test`, kiểm tra `git diff` không chứa publishable key/service role key.
