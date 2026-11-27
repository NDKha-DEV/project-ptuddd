import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tlu_b1_daily/core/config/app_env.dart';
import 'package:tlu_b1_daily/core/services/supabase_bootstrap.dart';

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
}
