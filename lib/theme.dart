// =================================================================
// ألوان وأشكال التطبيق
// -----------------------------------------------------------------
// الستايل: "Retro Pixel" → خلفية زرقا فاتحة بمربعات زي الكراسة، شبابيك كمبيوتر
// قديمة (شريط عنوان ملون + _ □ ✕)، ستيكرز بيكسل، وخط بيكسل للعناوين.
// غيّر القيم هنا لتغيير شكل التطبيق كله من مكان واحد.
// =================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الوضع الغامق: true = Dark Mode. بيتحفظ على الجهاز ويرجع لما التطبيق يتفتح تاني.
class AppTheme {
  static final ValueNotifier<bool> dark = ValueNotifier(false);
  static const _key = 'karta_dark_mode';

  /// اللوجو المناسب للوضع الحالي
  static String get logo => dark.value ? 'assets/images/logo_dark.png' : 'assets/images/logo.png';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dark.value = prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint("Theme preference could not be loaded: $e");
    }
  }

  static void toggle() {
    dark.value = !dark.value;
    SharedPreferences.getInstance().then((p) => p.setBool(_key, dark.value)).catchError((Object e) {
      debugPrint("Theme preference could not be saved: $e");
      return false;
    });
  }
}

/// الألوان الأصلية الثابتة (شكل الكروت بيستخدمها عشان كل كارت يفضل بلونه في الوضعين)
class Palette {
  static const teal = Color(0xFF5DB3A4);
  static const orange = Color(0xFFF08A3C);
  static const red = Color(0xFFE8585A);
  static const pink = Color(0xFFF29BBE);
  static const blue = Color(0xFF6E8EF0);
  static const green = Color(0xFF6CC468);
  static const purple = Color(0xFFA98BF0);
  static const yellow = Color(0xFFF2C94C);
}

/// ألوان التطبيق. فيه وضعين: فاتح (الأصلي) وغامق (Dark Mode).
/// AppColors.dark بيتغير من زرار الشمس/القمر، وكل الشاشات بتترسم من جديد بالألوان الجديدة.
class AppColors {
  static bool get dark => AppTheme.dark.value;

  static Color _pick(Color light, Color darkColor) => dark ? darkColor : light;

  static Color get bg => _pick(const Color(0xFFDCE6FA), const Color(0xFF1A140F));       // خلفية التطبيق
  static Color get gridLine => _pick(const Color(0xFFF5F8FF), const Color(0xFF332920)); // خطوط المربعات
  static Color get paper => _pick(const Color(0xFFFCEBD5), const Color(0xFF0F1A33));    // الشبابيك والكروت
  static Color get ink => _pick(const Color(0xFF3B2A2E), const Color(0xFFDDE3E8));      // الحدود والنص
  static Color get yellow => _pick(Palette.yellow, const Color(0xFF2446C8));            // الزراير الأساسية
  static Color get teal => _pick(Palette.teal, const Color(0xFF2E8C7C));                // شريط عنوان الشباك
  static Color get orange => _pick(Palette.orange, const Color(0xFFD0702C));
  static Color get red => _pick(Palette.red, const Color(0xFFB4485A));
  static Color get pink => _pick(Palette.pink, const Color(0xFFC0628A));
  static Color get blue => _pick(Palette.blue, const Color(0xFF2E7FC9));
  static Color get green => _pick(Palette.green, const Color(0xFF2C8059));
  static Color get purple => _pick(Palette.purple, const Color(0xFF7A5EC4));
  static Color get muted => _pick(const Color(0xFF7A6A66), const Color(0xFF9AA4B8));    // نص ثانوي
  static Color get line => _pick(const Color(0xFFE2CFB6), const Color(0xFF2B3757));     // خطوط خفيفة

  // لون مختلف لكل لاعب (حتى 8 لاعبين)
  static List<Color> get playerColors => [teal, orange, pink, yellow, blue, green, red, purple];
}

/// مقاسات الستايل
class Brutal {
  static const double border = 2.2;          // سُمك الحدود
  static const double radius = 6;            // استدارة خفيفة زي الشبابيك القديمة
  static const Offset shadow = Offset(4, 4); // إزاحة الظل الصلب

  /// ظل صلب (من غير تمويه)
  static List<BoxShadow> hardShadow({Offset offset = shadow, Color? color}) =>
      [BoxShadow(color: color ?? AppColors.ink, offset: offset, blurRadius: 0)];

  /// شكل صندوق جاهز: كريمي بحدود غامقة وظل صلب
  static BoxDecoration box({
    Color? color,
    double borderWidth = border,
    Offset shadowOffset = shadow,
    Color? shadowColor,
    double radius = Brutal.radius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.paper,
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
  'A': CardStyle(Palette.teal, Sticker.magnifier),     // سؤال تعجيزي
  'K': CardStyle(Palette.yellow, Sticker.smiley),      // نكتة
  'Q': CardStyle(Palette.pink, Sticker.speech),        // صمت
  'J': CardStyle(Palette.orange, Sticker.warning),     // قنبلة
  '10': CardStyle(Palette.red, Sticker.mail),          // كادو
  '9': CardStyle(Palette.blue, Sticker.music),         // وزن وقافية
  '8': CardStyle(Color(0xFFE0A458), Sticker.papers),     // براندات
  '7': CardStyle(Color(0xFFFF7F6B), Sticker.sparkle),    // تصفيق
  '6': CardStyle(Color(0xFF4FC1C9), Sticker.heart),      // تصفيق
  '5': CardStyle(Palette.purple, Sticker.cursor),      // تصفيق
  '4': CardStyle(Color(0xFF8FB85C), Sticker.letter),     // عمري ما
  '3': CardStyle(Palette.green, Sticker.check),        // حظ سعيد
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
