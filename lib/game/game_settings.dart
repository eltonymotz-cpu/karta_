// =================================================================
// إعدادات اللعبة اللي صاحب القعدة بيختارها في شاشة الإعداد
// -----------------------------------------------------------------
// - مؤقت كروت الأسئلة (زي وزن وقافية والبراندات): مقفول / 10 / 20 / 30 / 45 ثانية
// - أقصى وقت للقنبلة: من 10 لـ 30 أو من 10 لـ 40 ثانية
// بتتحفظ على الجهاز (SharedPreferences) فبترجع زي ما هي كل مرة تفتح التطبيق.
// =================================================================
import 'package:shared_preferences/shared_preferences.dart';

class GameSettings {
  /// اختيارات مؤقت الأسئلة (0 = مقفول)
  static const questionOptions = [0, 10, 20, 30, 45];

  /// اختيارات أقصى وقت للقنبلة
  static const bombMaxOptions = [30, 40];

  /// أقل وقت للقنبلة (ثابت)
  static const bombMinSeconds = 10;

  int questionSeconds; // مدة الإجابة على كروت الأسئلة
  int bombMaxSeconds;  // أقصى وقت للقنبلة

  GameSettings({this.questionSeconds = 20, this.bombMaxSeconds = 30});

  static const _questionKey = 'settings_question_seconds';
  static const _bombKey = 'settings_bomb_max';

  /// تحميل الإعدادات المحفوظة (ولو مفيش، القيم الافتراضية)
  static Future<GameSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = prefs.getInt(_questionKey);
      final b = prefs.getInt(_bombKey);
      return GameSettings(
        questionSeconds: questionOptions.contains(q) ? q! : 20,
        bombMaxSeconds: bombMaxOptions.contains(b) ? b! : 30,
      );
    } catch (_) {
      return GameSettings();
    }
  }

  /// حفظ الإعدادات
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_questionKey, questionSeconds);
      await prefs.setInt(_bombKey, bombMaxSeconds);
    } catch (_) {
      // لو الحفظ فشل الإعدادات بتفضل شغالة في الجلسة دي
    }
  }

  Map<String, dynamic> toJson() => {'q': questionSeconds, 'bomb': bombMaxSeconds};
}
