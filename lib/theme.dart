// =================================================================
// ألوان وأشكال التطبيق
// -----------------------------------------------------------------
// الستايل: "Neo-Brutalism" → خلفية كريمي، حدود سودا تقيلة، أصفر قوي،
// وظلال صلبة من غير تمويه (بتدي إحساس إن العناصر بارزة زي الكروت).
// غيّر القيم هنا لتغيير شكل التطبيق كله من مكان واحد.
// =================================================================
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF6F4EE);       // خلفية التطبيق (كريمي)
  static const paper = Color(0xFFFFFFFF);    // لون الصناديق والكروت
  static const ink = Color(0xFF111111);      // الأسود: الحدود والنص الأساسي
  static const yellow = Color(0xFFFFC21A);   // الأصفر: اللون الأساسي
  static const red = Color(0xFFE5482E);      // أحمر/برتقالي: تنبيهات وكروت ♥ ♦
  static const muted = Color(0xFF6B6B6B);    // نص ثانوي رمادي
  static const line = Color(0xFFDAD6CC);     // خطوط خفيفة

  // لون مختلف لكل لاعب (حتى 8 لاعبين) - ألوان مسطحة قوية
  static const playerColors = [
    Color(0xFFFFC21A),
    Color(0xFF2EC4B6),
    Color(0xFFE5482E),
    Color(0xFF7B61FF),
    Color(0xFF3DBE5B),
    Color(0xFFFF7AB6),
    Color(0xFF3A86FF),
    Color(0xFFFF9F1C),
  ];
}

/// مقاسات الستايل
class Brutal {
  static const double border = 2.5;         // سُمك الحدود
  static const double radius = 4;           // استدارة بسيطة جداً
  static const Offset shadow = Offset(4, 4); // إزاحة الظل الصلب

  /// ظل صلب (من غير تمويه)
  static List<BoxShadow> hardShadow({Offset offset = shadow, Color color = AppColors.ink}) =>
      [BoxShadow(color: color, offset: offset, blurRadius: 0)];

  /// شكل صندوق جاهز: أبيض بحدود سودا وظل صلب
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
