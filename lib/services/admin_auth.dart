// =================================================================
// تسجيل دخول الأدمن (Supabase Auth)
// -----------------------------------------------------------------
// الأدمن بيدخل بإيميل وباسورد معمولين في Supabase → Authentication → Users،
// والإيميل لازم يكون متسجل في جدول karta_admins (شوف supabase/migrations).
// الحفظ والرفع محميين في Supabase نفسه، فحتى لو حد فتح لوحة الأدمن بطريقة ما،
// مش هيقدر يحفظ أو يرفع حاجة من غير ما يكون أدمن فعلاً.
// =================================================================
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class AdminAuth {
  /// هل تسجيل الدخول متاح (Supabase متظبط)؟
  static bool get available => AppConfig.hasSupabase;

  /// الإيميل اللي داخل بيه دلوقتي (null = مش داخل)
  static String? get email => available ? Supabase.instance.client.auth.currentUser?.email : null;

  static bool get isLoggedIn => email != null;

  /// تسجيل الدخول. بترجع null لو نجح، أو رسالة الخطأ
  static Future<String?> signIn(String email, String password) async {
    if (!available) return 'Supabase not configured';
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email.trim(), password: password);
      // نتأكد إن الحساب ده أدمن فعلاً (موجود في karta_admins)
      final isAdmin = await checkIsAdmin();
      if (!isAdmin) {
        await signOut();
        return 'This account is not an admin';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// هل الحساب الحالي متسجل كأدمن؟ (الجدول نفسه محمي: كل واحد يشوف صفّه بس)
  static Future<bool> checkIsAdmin() async {
    final current = email;
    if (current == null) return false;
    try {
      final rows = await Supabase.instance.client.from('karta_admins').select('email').eq('email', current.toLowerCase());
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    if (!available) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}
