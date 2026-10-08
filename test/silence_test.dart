// اختبار كارت الصمت (Q): صاحب الدور ياخده، واللي يكلّمه ياخده منه ويبقى هو الصامت
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Q passes to whoever talks to the silent player', () async {
    final game = GameController()..sound.enabled = false;
    game.startGame(['A', 'B', 'C']);
    // آخر كارت في الكومة هو اللي بيتسحب الأول
    game.deck = [const PlayingCard('2', '♣'), const PlayingCard('Q', '♠')];

    game.tapCard(); // سحب الـ Q
    expect(game.currentRule!.type, RuleType.silence);
    expect(game.silentIndex, -1); // لسه محدش صامت لحد الضغطة التانية

    await Future.delayed(const Duration(milliseconds: 300)); // بعد منع الضغط المزدوج
    game.tapCard(); // A ياخد الـ Q
    expect(game.silentIndex, 0);
    expect(game.players[0].cards.map((c) => c.label), ['Q♠']);
    expect(game.currentIndex, 1); // الدور اتنقل
    expect(game.canPassSilence, isTrue);

    game.passSilence(0); // مينفعش يدّيها لنفسه
    expect(game.silentIndex, 0);

    game.passSilence(2); // C كلّم A
    expect(game.players[0].cards, isEmpty);
    expect(game.players[2].cards.map((c) => c.label), ['Q♠']);
    expect(game.silentIndex, 2); // C بقى هو الصامت
  });
}
