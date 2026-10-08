// اختبار الكروت الزيادة: بتتضاف للكومة بعدد نسخها، وقاعدتها بتتقري صح، وبتتحفظ وترجع
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/game/game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('extra cards are added to the deck and their rules resolve', () {
    const joker = CardRule(
      emoji: '🃏',
      title: LText('جوكر', 'Joker'),
      description: LText('اشرب', 'Eshrab'),
      type: RuleType.self,
    );
    customModes['custom_test'] = GameMode(
      emoji: '🎲',
      name: const LText('تجربة', 'Test'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {for (final r in cardRanks) r: getRule('classic', r)},
      extraCards: const [ExtraCard(label: 'JK', copies: 3, rule: joker)],
      image: 'aGVsbG8=',
    );

    final game = GameController()..sound.enabled = false;
    game.setMode('custom_test');
    game.startGame(['A', 'B', 'C']);

    expect(game.deck.length, 55); // 52 + 3 جوكر
    expect(GameController.deckSize('custom_test'), 55);
    expect(game.deck.where((c) => c.rank == 'JK' && c.suit == extraSuit).length, 3);
    expect(getRule('custom_test', 'JK').title.fr, 'Joker');

    // الحفظ والقراءة من JSON بيحافظوا على الكروت الزيادة والصورة
    final copy = GameMode.fromJson(customModes['custom_test']!.toJson());
    expect(copy.extraCards.single.label, 'JK');
    expect(copy.extraCards.single.copies, 3);
    expect(copy.image, 'aGVsbG8=');

    customModes.remove('custom_test');
  });
}
