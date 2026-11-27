import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<bool> init() async {
    if (!AppEnv.isSupabaseConfigured) {
      debugPrint('[Supabase] Thiếu SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabasePublishableKey,
      );
      return true;
    } catch (e) {
      debugPrint('[Supabase] Khởi tạo thất bại: $e');
      return false;
    }
  }
}
