// الهوست يدوس على مقعد لاعب معاه كروت → شيت التصحيح يفتح ويشيل الكارت
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';
import 'package:karta/screens/game_screen.dart';
import 'package:karta/widgets/player_seat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('host opens the corrections sheet for a player with cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    final game = GameController()..sound.enabled = false;
    game.setMode('classic');
    game.startGame(['A', 'B', 'C']);
    game.players[1].cards.add(const PlayingCard('5', '♦'));

    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    await tester.tap(find.widgetWithText(PlayerSeat, 'B').first);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(InputChip), findsOneWidget);
    expect(find.text('5♦'), findsWidgets);
    expect(game.removeCardFrom(1, 0), isTrue);
    await tester.pump();
    expect(find.byType(InputChip), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // الأنيميشن تخلص
    await tester.binding.setSurfaceSize(null);
    game.dispose();
  });
}
