// =================================================================
// إعدادات التطبيق
// -----------------------------------------------------------------
// 1) Supabase: من لوحة Supabase → Project Settings → API Keys
//    انسخ "Project URL" و "Publishable key" (أو الـ anon key القديم) وحطهم هنا.
//    ⚠️ متحطش الـ secret / service_role key هنا أبداً.
//    لو سبتهم فاضيين: اللعب على جهاز واحد يشتغل عادي،
//    بس وضع "أكتر من جهاز" وحفظ الأنماط أونلاين مش هيشتغلوا.
//
// 2) joinBaseUrl: رابط نسخة الويب بعد ما ترفعها على النت
//    (مثلاً https://karta.netlify.app). ده اللي بيتحط في الـ QR.
//    لو سبته فاضي ونسخة الويب هي اللي شغالة، بيستخدم رابطها الحالي تلقائياً.
//
// 3) adminPin: الرقم السري للوحة الأدمن
//    (توصلها بإنك تدوس على اللوجو في أول شاشة 5 مرات ورا بعض)
// =================================================================
class AppConfig {
  static const supabaseUrl = 'https://mimonvumevwapgtyhikg.supabase.co';
  static const supabaseKey = 'sb_publishable_TwMofqSyfIoqatfPsyUOUw_8fPOyhxm';
  static const joinBaseUrl = '';
  static const adminPin = '2468';

  /// هل Supabase متظبط؟
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
