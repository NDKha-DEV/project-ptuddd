import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tlu_b1_daily/core/config/app_env.dart';
import 'package:tlu_b1_daily/core/services/supabase_bootstrap.dart';
import 'package:tlu_b1_daily/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall call) async {
        if (call.method == 'getAll') return <String, Object>{};
        return null;
      },
    );
  });

  test('Supabase client initializes from dart-define config', () async {
    if (!AppEnv.isSupabaseConfigured) {
      return;
    }

    final ready = await SupabaseBootstrap.init();

    expect(ready, isTrue);
    expect(Supabase.instance.client, isNotNull);
  });

  test('SignIn qua Supabase trả lỗi khi thông tin sai', () async {
    if (!AppEnv.isSupabaseConfigured) {
      return;
    }

    await SupabaseBootstrap.init();
    final auth = AuthProvider(supabaseReady: true);
    await auth.initialize();

    final signedIn = await auth.signInWithPassword(
      email: 'invalid-login@example.com',
      password: 'definitely-wrong-password',
    );

    expect(signedIn, isFalse);
    expect(auth.error, isNotNull);
    expect(auth.isLoading, isFalse);
  });
}
