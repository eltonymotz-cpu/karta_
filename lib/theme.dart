// =================================================================
// ألوان وأشكال التطبيق
// -----------------------------------------------------------------
// الستايل: "Retro Pixel" → خلفية زرقا فاتحة بمربعات زي الكراسة، شبابيك كمبيوتر
// قديمة (شريط عنوان ملون + _ □ ✕)، ستيكرز بيكسل، وخط بيكسل للعناوين.
// غيّر القيم هنا لتغيير شكل التطبيق كله من مكان واحد.
// =================================================================
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFDCE6FA);       // خلفية التطبيق (أزرق فاتح)
  static const gridLine = Color(0xFFF5F8FF); // خطوط المربعات في الخلفية
  static const paper = Color(0xFFFCEBD5);    // لون الشبابيك والكروت (كريمي)
  static const ink = Color(0xFF3B2A2E);      // البني الغامق: الحدود والنص
  static const yellow = Color(0xFFF2C94C);   // أصفر: الزراير الأساسية
  static const teal = Color(0xFF5DB3A4);     // تركواز: شريط عنوان الشباك
  static const orange = Color(0xFFF08A3C);   // برتقالي
  static const red = Color(0xFFE8585A);      // أحمر: تنبيهات وكروت ♥ ♦
  static const pink = Color(0xFFF29BBE);     // بمبي
  static const blue = Color(0xFF6E8EF0);     // أزرق
  static const green = Color(0xFF6CC468);    // أخضر
  static const purple = Color(0xFFA98BF0);   // موف
  static const muted = Color(0xFF7A6A66);    // نص ثانوي
  static const line = Color(0xFFE2CFB6);     // خطوط خفيفة

  // لون مختلف لكل لاعب (حتى 8 لاعبين)
  static const playerColors = [teal, orange, pink, yellow, blue, green, red, purple];
}

/// مقاسات الستايل
class Brutal {
  static const double border = 2.2;          // سُمك الحدود
  static const double radius = 6;            // استدارة خفيفة زي الشبابيك القديمة
  static const Offset shadow = Offset(4, 4); // إزاحة الظل الصلب

  /// ظل صلب (من غير تمويه)
  static List<BoxShadow> hardShadow({Offset offset = shadow, Color color = AppColors.ink}) =>
      [BoxShadow(color: color, offset: offset, blurRadius: 0)];

  /// شكل صندوق جاهز: كريمي بحدود غامقة وظل صلب
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

/// الستيكرز (صور بيكسل في assets/images/stickers)
enum Sticker {
  cursor, magnifier, sparkle, heart, warning, music, papers,
  envelope, mail, letter, xbutton, check, smiley, oval, speech;

  String get path => 'assets/images/stickers/$name.png';
}

// =================================================================
// شكل كل كارت: لون خاص + ستيكر خاص
// -----------------------------------------------------------------
// كل قيمة كارت (A, K, Q ...) ليها لون شريط عنوان مختلف وستيكر مختلف.
// الكروت الزيادة اللي الأدمن بيضيفها بتاخد شكل من القائمة extraStyles.
// =================================================================
class CardStyle {
  final Color color;      // لون شريط العنوان والزينة
  final Sticker sticker;  // الستيكر الكبير في نص الكارت
  const CardStyle(this.color, this.sticker);

  /// لون فاتح من نفس اللون (لخلفية الكارت)
  Color get tint => Color.lerp(color, AppColors.paper, 0.62)!;
}

const Map<String, CardStyle> cardStyles = {
  'A': CardStyle(AppColors.teal, Sticker.magnifier),     // سؤال تعجيزي
  'K': CardStyle(AppColors.yellow, Sticker.smiley),      // نكتة
  'Q': CardStyle(AppColors.pink, Sticker.speech),        // صمت
  'J': CardStyle(AppColors.orange, Sticker.warning),     // قنبلة
  '10': CardStyle(AppColors.red, Sticker.mail),          // كادو
  '9': CardStyle(AppColors.blue, Sticker.music),         // وزن وقافية
  '8': CardStyle(Color(0xFFE0A458), Sticker.papers),     // براندات
  '7': CardStyle(Color(0xFFFF7F6B), Sticker.sparkle),    // تصفيق
  '6': CardStyle(Color(0xFF4FC1C9), Sticker.heart),      // تصفيق
  '5': CardStyle(AppColors.purple, Sticker.cursor),      // تصفيق
  '4': CardStyle(Color(0xFF8FB85C), Sticker.letter),     // عمري ما
  '3': CardStyle(AppColors.green, Sticker.check),        // حظ سعيد
  '2': CardStyle(Color(0xFF8C7B8F), Sticker.xbutton),    // حظ وحش
};

/// أشكال الكروت الزيادة (بالترتيب حسب اسم الكارت)
const List<CardStyle> extraStyles = [
  CardStyle(Color(0xFFFF6FAE), Sticker.heart),
  CardStyle(Color(0xFF52B6E8), Sticker.sparkle),
  CardStyle(Color(0xFFFFB13D), Sticker.envelope),
  CardStyle(Color(0xFF7BCB6E), Sticker.smiley),
  CardStyle(Color(0xFFB58CFF), Sticker.oval),
  CardStyle(Color(0xFFFF8A5C), Sticker.music),
];

/// شكل كارت معيّن (والكروت الزيادة بتاخد شكل ثابت حسب اسمها)
CardStyle styleFor(String rank) {
  final known = cardStyles[rank];
  if (known != null) return known;
  final code = rank.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return extraStyles[code % extraStyles.length];
}
