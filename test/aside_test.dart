// اختبار "مش عارفين؟ حطّه على جنب": نفس اللاعب يعيد الدور، وأول خسران ياخد الكارتين
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('set-aside clap card goes to the next loser and the turn repeats', () async {
    final game = GameController()..sound.enabled = false;
    game.startGame(['A', 'B', 'C']);
    // الترتيب: الأول 7 (تصفيق)، وبعده K
    game.deck = [const PlayingCard('2', '♣'), const PlayingCard('K', '♥'), const PlayingCard('7', '♠')];

    game.tapCard(); // سحب الـ 7: زرار التصفيق يظهر على طول
    expect(game.phase, CardPhase.clapGo);
    await Future.delayed(const Duration(milliseconds: 300));
    game.tapCard(); // صقّفوا → اختيار الخسران
    expect(game.canSetAside, isTrue);

    game.setAside(); // مش عارفين مين آخر واحد
    expect(game.asideCards.map((c) => c.label), ['7♠']);
    expect(game.currentIndex, 0); // نفس اللاعب يعيد الدور
    expect(game.players.every((p) => p.cards.isEmpty), isTrue);

    await Future.delayed(const Duration(milliseconds: 300));
    game.tapCard(); // سحب الـ K
    await Future.delayed(const Duration(milliseconds: 300));
    game.tapCard(); // اختيار الخسران
    game.pickLoser(1); // B خسر
    expect(game.players[1].cards.map((c) => c.label), ['K♥', '7♠']);
    expect(game.asideCards, isEmpty);
    expect(game.currentIndex, 1);
  });
}
