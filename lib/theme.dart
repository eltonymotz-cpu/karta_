// =================================================================
// ألوان وأشكال التطبيق
// -----------------------------------------------------------------
// الستايل: "Playful Geometric" → خلفية كريمي فيها نقط، صناديق مدوّرة بحدود
// سودا وظل صلب، زراير صفرا مدوّرة، وأشكال هندسية ملونة (مثلثات ودواير ومربعات).
// غيّر القيم هنا لتغيير شكل التطبيق كله من مكان واحد.
// =================================================================
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFFBF3E6);       // خلفية التطبيق (كريمي دافي)
  static const paper = Color(0xFFFFFAF2);    // لون الصناديق والكروت
  static const ink = Color(0xFF1B1B1F);      // الأسود: الحدود والنص الأساسي
  static const yellow = Color(0xFFFFDB1F);   // الأصفر: الزراير الأساسية
  static const red = Color(0xFFF25C5C);      // أحمر مرجاني: تنبيهات وكروت ♥ ♦
  static const sky = Color(0xFF7FD0E0);      // أزرق سماوي: شارة النقط (السكور)
  static const green = Color(0xFF6BBE45);    // أخضر
  static const violet = Color(0xFF6E7FF3);   // بنفسجي مزرق
  static const muted = Color(0xFF6E6A63);    // نص ثانوي
  static const line = Color(0xFFE4DACB);     // خطوط خفيفة

  // لون مختلف لكل لاعب (حتى 8 لاعبين)
  static const playerColors = [
    Color(0xFFFFDB1F),
    Color(0xFF7FD0E0),
    Color(0xFFF25C5C),
    Color(0xFF6BBE45),
    Color(0xFF6E7FF3),
    Color(0xFFFF9F45),
    Color(0xFFFF8FB8),
    Color(0xFF2EC4B6),
  ];
}

/// مقاسات الستايل
class Brutal {
  static const double border = 2.2;          // سُمك الحدود
  static const double radius = 18;           // استدارة الزوايا
  static const Offset shadow = Offset(4, 4); // إزاحة الظل الصلب

  /// ظل صلب (من غير تمويه)
  static List<BoxShadow> hardShadow({Offset offset = shadow, Color color = AppColors.ink}) =>
      [BoxShadow(color: color, offset: offset, blurRadius: 0)];

  /// شكل صندوق جاهز: فاتح بحدود سودا وظل صلب
  static BoxDecoration box({
    Color color = AppColors.paper,
    double borderWidth = border,
    Offset shadowOffset = shadow,
    Color shadowColor = AppColors.ink,
    double radius = Brutal.radius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.ink, width: borderWidth),
      boxShadow: shadowOffset == Offset.zero ? null : hardShadow(offset: shadowOffset, color: shadowColor),
    );
  }
}

// =================================================================
// شكل كل كارت: لون خاص + رسمة هندسية خاصة
// -----------------------------------------------------------------
// كل قيمة كارت (A, K, Q ...) ليها لون مختلف ونقشة مختلفة، فمفيش كارتين شبه بعض.
// =================================================================

/// أنواع النقشات الهندسية اللي بتترسم على وش الكارت (شوف widgets/card_decor.dart)
enum CardPattern { triangles, circles, grid, burst, confetti, waves, squares, halfMoon, crosses, stripes }

/// شكل كارت واحد
class CardStyle {
  final Color color;          // اللون الأساسي للكارت
  final CardPattern pattern;  // النقشة
  const CardStyle(this.color, this.pattern);

  /// لون فاتح من نفس اللون (لخلفية الكارت)
  Color get tint => Color.lerp(color, AppColors.paper, 0.78)!;
}

/// شكل كل قيمة كارت
const Map<String, CardStyle> cardStyles = {
  'A': CardStyle(Color(0xFFF25C5C), CardPattern.triangles),  // مرجاني
  'K': CardStyle(Color(0xFFFFC21F), CardPattern.circles),    // أصفر غامق
  'Q': CardStyle(Color(0xFF6E7FF3), CardPattern.grid),       // بنفسجي
  'J': CardStyle(Color(0xFFFF7A3D), CardPattern.burst),      // برتقالي (القنبلة)
  '10': CardStyle(Color(0xFFFF8FB8), CardPattern.confetti),  // بمبي (الكادو)
  '9': CardStyle(Color(0xFF5BC3D9), CardPattern.waves),      // سماوي
  '8': CardStyle(Color(0xFF6BBE45), CardPattern.squares),    // أخضر
  '7': CardStyle(Color(0xFFFF9F45), CardPattern.halfMoon),   // برتقالي فاتح
  '6': CardStyle(Color(0xFF2EC4B6), CardPattern.triangles),  // تركواز
  '5': CardStyle(Color(0xFF4F8BFF), CardPattern.circles),    // أزرق
  '4': CardStyle(Color(0xFFB57CFF), CardPattern.stripes),    // موف
  '3': CardStyle(Color(0xFF3DBE7A), CardPattern.confetti),   // أخضر نعناعي (حظ سعيد)
  '2': CardStyle(Color(0xFF7A7287), CardPattern.crosses),    // رمادي (حظ وحش)
};

/// شكل كارت معيّن (ولو مش موجود ناخد شكل A)
CardStyle styleFor(String rank) => cardStyles[rank] ?? cardStyles['A']!;
