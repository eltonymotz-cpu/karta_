// المحفظة: كل التابات بتفتح، والتحويل من الواجهة بيوصل للرصيد فعلاً
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karta/data/coin_texts.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/widgets/wallet_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('every wallet tab opens and a transfer from the UI moves real coins', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) errors.add(d.exceptionAsString());
    };
    customModes['money'] = completeMode('classic').copyWith(money: true);
    final game = GameController()..sound.enabled = false;
    game.setMode('money');
    game.startGame(['Sara', 'Omar', 'Mona']);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WalletPanel(game: game))));
    await tester.pump();

    for (final tab in [CoinText.history, CoinText.challenges, CoinText.adjust, CoinText.transfer]) {
      await tester.tap(find.text(tab.ar).first);
      await tester.pump();
    }
    // تحويل: من سارة (صاحبة الدور) لعمر 40
    await tester.tap(find.text('Omar').last);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '40');
    await tester.pump();
    await tester.tap(find.text(CoinText.send.ar));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.economy.balanceOf(0), 960);
    expect(game.economy.balanceOf(1), 1040);

    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: errors.join('\n'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await tester.binding.setSurfaceSize(null);
    game.dispose();
  });
}
