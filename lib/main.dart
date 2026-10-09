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
import 'data/game_modes.dart';
import 'data/texts.dart';
import 'game/game_controller.dart';
import 'game/game_settings.dart';
import 'screens/admin_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/results_screen.dart';
import 'screens/setup_screen.dart';
import 'services/app_settings.dart';
import 'services/device_identity.dart';
import 'services/mode_store.dart';
import 'services/sound_service.dart';
import 'theme.dart';
import 'widgets/common.dart';

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

  // تحميل الأنماط اللي الأدمن ضافها + الوضع الغامق/الفاتح المحفوظ
  // + إعدادات الأدمن (الأونلاين والشات) + رقم الموبايل واسمه في الشات
  await Future.wait([ModeStore.load(), AppTheme.load(), AppSettings.load(), DeviceIdentity.load()]);
  AppSettings.listen();

  // تحميل الأصوات في الخلفية (من غير ما نأخر فتح التطبيق)
  SoundService.instance.preload();

  runApp(const KartaApp());
}

/// الثيم بيتعمل مرة واحدة لكل وضع (فاتح/غامق) وبيتخزن (بدل ما يتحسب مع كل تغيير في اللعبة)
final Map<bool, ThemeData> _themes = {};
ThemeData _themeFor(bool dark) => _themes[dark] ??= _buildTheme(dark);

ThemeData _buildTheme(bool dark) => ThemeData(
  brightness: dark ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: dark
      ? ColorScheme.dark(primary: AppColors.ink, secondary: AppColors.yellow, surface: AppColors.paper, onSurface: AppColors.ink)
      : ColorScheme.light(primary: AppColors.ink, secondary: AppColors.yellow, surface: AppColors.paper),
  dialogTheme: DialogThemeData(backgroundColor: AppColors.paper),
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.bg),
  popupMenuTheme: PopupMenuThemeData(color: AppColors.paper),
  inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: AppColors.muted)),
  textSelectionTheme: TextSelectionThemeData(cursorColor: AppColors.ink),
  // انتقالات ناعمة بين الصفحات (زي صفحة تعديل النمط في الأدمن)
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    },
  ),
  // خط Baloo Bhaijaan 2: مدوّر ومرح وبيدعم العربي والإنجليزي
  textTheme: GoogleFonts.balooBhaijaan2TextTheme((dark ? ThemeData.dark() : ThemeData.light()).textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  ),
);

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
    AppTheme.dark.addListener(_themeChanged);
    AppSettings.changes.addListener(_settingsChanged);
    // لو التطبيق اتفتح من رابط الـ QR (فيه ?room=CODE) ندخل القعدة على طول كمتفرج
    final code = kIsWeb ? Uri.base.queryParameters['room'] : null;
    if (code != null && code.isNotEmpty && AppConfig.hasSupabase) game.joinRoom(code);
    // إعدادات اللعبة المحفوظة (مؤقت الأسئلة ومدة القنبلة)
    GameSettings.load().then((settings) {
      game.settings = settings;
      game.modesChanged();
    });
    // أي تعديل من لوحة الأدمن (من أي جهاز) بيوصل لايف
    ModeStore.listen(game.modesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // نحمّل صورة اللوجو والستيكرز من الأول، عشان الكروت تظهر من غير تأخير
    precacheImage(AssetImage(AppTheme.logo), context);
    for (final sticker in Sticker.values) {
      precacheImage(AssetImage(sticker.path), context);
    }
  }

  /// الأدمن غيّر إعدادات الأونلاين/الشات: نعيد رسم الشاشة
  void _settingsChanged() => game.modesChanged();

  /// الوضع الغامق/الفاتح اتغير: نعيد رسم كل الشاشات بالألوان الجديدة
  /// (من غير ما نفقد أي حالة: الأسامي اللي اتكتبت، الكارت الحالي، تعديلات الأدمن...)
  void _themeChanged() {
    precacheImage(AssetImage(AppTheme.logo), context);
    setState(() {});
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }
    (context as Element).visitChildren(rebuild);
  }

  @override
  void dispose() {
    AppTheme.dark.removeListener(_themeChanged);
    AppSettings.changes.removeListener(_settingsChanged);
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الـ MaterialApp بيتبني مرة واحدة، والأجزاء اللي بتتغير بس هي اللي بتسمع للعبة
    return MaterialApp(
      title: 'Karta - كارتة',
      debugShowCheckedModeBanner: false,
      theme: _themeFor(AppColors.dark),
      themeAnimationDuration: Duration.zero, // التبديل فوري
      // اتجاه الكتابة حسب اللغة: العربي يمين، والفرانكو شمال
      builder: (context, child) => ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          PixelFont.arabic = game.lang == AppLang.ar;
          return Directionality(
            textDirection: game.textDirection,
            child: Stack(children: [child!, const _FontWarmup()]),
          );
        },
      ),
      home: _Root(game: game),
    );
  }
}

/// تسخين الخطوط: على الويب، خط الإيموجي بيتحمّل أول مرة الإيموجي يظهر،
/// فكان أول ما كارت جديد يتقلب بيستنى التحميل. هنا بنكتب كل الإيموجي والرموز
/// اللي اللعبة بتستخدمها في ركن الشاشة بشفافية شبه كاملة، فتتحمّل من أول ما التطبيق يفتح.
class _FontWarmup extends StatelessWidget {
  const _FontWarmup();

  @override
  Widget build(BuildContext context) {
    final emojis = <String>{
      for (final mode in allModes.values) ...[
        mode.emoji,
        for (final rule in mode.rules.values) rule.emoji,
      ],
      ...['🃏', '💣', '💥', '👏', '🤐', '🎁', '📱', '📲', '👆', '🙌', '⚠️', '🔒', '🏆', '🤡', '♠', '♥', '♦', '♣'],
    }.join(' ');
    return Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emojis, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800)),
              // خط البيكسل كمان (عشان العناوين تظهر بيه من أول مرة)
              Text('Karta AKQJ 1234567890 ★', style: rankStyle(size: 6)),
            ],
          ),
        ),
      ),
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
        // الخطوط بتتغير حسب اللغة (قبل ما الشاشة تترسم)
        PixelFont.arabic = game.lang == AppLang.ar;
        final Widget screen = switch (game.screen) {
          AppScreen.home => HomeScreen(key: const ValueKey('home'), game: game),
          AppScreen.admin => AdminScreen(key: const ValueKey('admin'), game: game),
          AppScreen.setup => SetupScreen(key: const ValueKey('setup'), game: game),
          AppScreen.game => GameScreen(key: const ValueKey('game'), game: game),
          AppScreen.results => ResultsScreen(key: const ValueKey('results'), game: game),
        };
        // انتقال ناعم: الشاشة الجديدة بتظهر وهي طالعة لفوق شوية
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: screen,
        );
      },
    );
  }
}
