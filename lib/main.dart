// =================================================================
// كارتة KARTA - نقطة بداية التطبيق
// -----------------------------------------------------------------
// تنظيم الملفات:
//   lib/theme.dart                 → الألوان
//   lib/data/texts.dart            → كل النصوص (عربي + فرانكو)
//   lib/data/game_modes.dart       → أنماط اللعب وقواعد الكروت
//   lib/models.dart                → الكارت واللاعب
//   lib/game/game_controller.dart  → منطق اللعبة كله
//   lib/services/sound_service.dart→ الأصوات
//   lib/screens/                   → الشاشات (إعداد، لعب، نتائج)
//   lib/widgets/                   → عناصر الواجهة (الكارت، المقاعد...)
// =================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'game/game_controller.dart';
import 'screens/admin_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/results_screen.dart';
import 'screens/setup_screen.dart';
import 'services/mode_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // اللعبة بتشتغل بالطول بس على الموبايل
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // الاتصال بـ Supabase (لو متظبط في config.dart)
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseKey);
    } catch (_) {
      // لو فشل نكمّل عادي: اللعب على موبايل واحد مش محتاج نت
    }
  }

  // تحميل الأنماط اللي الأدمن ضافها
  await ModeStore.load();

  runApp(const KartaApp());
}

class KartaApp extends StatefulWidget {
  const KartaApp({super.key});

  @override
  State<KartaApp> createState() => _KartaAppState();
}

class _KartaAppState extends State<KartaApp> {
  // عقل اللعبة: نسخة واحدة للتطبيق كله
  final game = GameController();

  @override
  void initState() {
    super.initState();
    // لو التطبيق اتفتح من رابط الـ QR (فيه ?room=CODE) ندخل القعدة على طول كمتفرج
    final code = kIsWeb ? Uri.base.queryParameters['room'] : null;
    if (code != null && code.isNotEmpty && AppConfig.hasSupabase) game.joinRoom(code);
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder: يعيد بناء الواجهة كل ما حالة اللعبة تتغير
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        return MaterialApp(
          title: 'Karta - كارتة',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: const ColorScheme.light(
              primary: AppColors.ink,
              secondary: AppColors.yellow,
              surface: AppColors.paper,
            ),
            textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.ink),
            // خط Cairo بيدعم العربي والإنجليزي
            textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).apply(
              bodyColor: AppColors.ink,
              displayColor: AppColors.ink,
            ),
          ),
          // اتجاه الكتابة حسب اللغة: العربي يمين، والفرانكو شمال
          builder: (context, child) => Directionality(textDirection: game.textDirection, child: child!),
          home: _Root(game: game),
        );
      },
    );
  }
}

/// يختار الشاشة الظاهرة حسب حالة اللعبة (مع انتقال ناعم)
class _Root extends StatelessWidget {
  final GameController game;
  const _Root({required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final Widget screen = switch (game.screen) {
          AppScreen.home => HomeScreen(key: const ValueKey('home'), game: game),
          AppScreen.admin => AdminScreen(key: const ValueKey('admin'), game: game),
          AppScreen.setup => SetupScreen(key: const ValueKey('setup'), game: game),
          AppScreen.game => GameScreen(key: const ValueKey('game'), game: game),
          AppScreen.results => ResultsScreen(key: const ValueKey('results'), game: game),
        };
        return AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: screen);
      },
    );
  }
}
