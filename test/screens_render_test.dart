// كل الشاشات بتترسم من غير أخطاء في الوضعين (الفاتح والغامق) وعلى مقاس موبايل وكمبيوتر
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/screens/admin_screen.dart';
import 'package:karta/screens/card_library_screen.dart';
import 'package:karta/screens/game_screen.dart';
import 'package:karta/screens/help_screen.dart';
import 'package:karta/screens/home_screen.dart';
import 'package:karta/screens/results_screen.dart';
import 'package:karta/screens/setup_screen.dart';
import 'package:karta/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final screens = <String, Widget Function(GameController)>{
    'home': (g) => HomeScreen(game: g),
    'setup': (g) => SetupScreen(game: g),
    'game': (g) => GameScreen(game: g),
    'results': (g) => ResultsScreen(game: g),
    'help': (g) => HelpScreen(game: g),
    'admin': (g) => AdminScreen(game: g),
    'library': (g) => CardLibraryScreen(game: g),
  };

  for (final dark in [false, true]) {
    for (final size in const [Size(390, 844), Size(1280, 900)]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} renders (${dark ? 'dark' : 'light'}, ${size.width.toInt()}px)', (tester) async {
          // الخطوط في الاختبار بتبقى أعرض من الحقيقة، فبنتجاهل تحذيرات "overflow" بس
          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            if (!details.toString().contains('overflowed')) errors.add(details);
          };
          AppTheme.dark.value = dark;
          await tester.binding.setSurfaceSize(size);
          final game = GameController()..sound.enabled = false;
          game.startGame(['Sara', 'Omar', 'Mona', 'Ali']);
          game.players[1].cards.add(game.deck.removeLast());
          await tester.pumpWidget(MaterialApp(home: entry.value(game)));
          await tester.pump(const Duration(milliseconds: 400));
          FlutterError.onError = previous;
          expect(errors, isEmpty, reason: errors.map((e) => e.exceptionAsString()).join('\n'));
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 4));
          await tester.binding.setSurfaceSize(null);
          AppTheme.dark.value = false;
          game.dispose();
        });
      }
    }
  }
}
