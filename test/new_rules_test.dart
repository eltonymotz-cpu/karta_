// نقط أو فلوس + تمن الكارت، كارت السؤال، الدور جوه الكارت، ترتيب التصفيق على الضهر، والأزرار السريعة
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

GameController newGame(List<PlayingCard> deck, {String mode = 'classic'}) {
  final game = GameController()..sound.enabled = false;
  game.setMode(mode);
  game.startGame(['A', 'B', 'C']);
  game.deck = deck;
  return game;
}

Future<void> waitTap() => Future.delayed(const Duration(milliseconds: 300));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => customModes.clear());

  test('modes play with points by default; money modes charge each card its own cost', () async {
    final points = newGame([const PlayingCard('K', '♥')]);
    expect(points.coinsOn, isFalse); // الكلاسيك بالنقط (عدد الكروت)

    final classic = completeMode('classic');
    customModes['cash'] = classic.copyWith(
      money: true,
      rules: {...classic.rules, 'K': classic.rules['K']!.copyWith(cost: 120)},
    );
    final cash = newGame([const PlayingCard('2', '♣'), const PlayingCard('A', '♠'), const PlayingCard('K', '♥')], mode: 'cash');
    expect(cash.coinsOn, isTrue);
    cash.tapCard();
    await waitTap();
    cash.tapCard();
    cash.pickLoser(1);
    expect(cash.economy.balanceOf(1), 1000 - 120); // تمن الـ K
    await waitTap();
    cash.tapCard();
    await waitTap();
    cash.tapCard();
    cash.pickLoser(2); // A مالوش تمن: بيتحسب من الضريبة العامة (5% = 50)
    expect(cash.economy.balanceOf(2), 950);
    expect(GameMode.fromJson(customModes['cash']!.toJson()).money, isTrue);
    expect(GameMode.fromJson(customModes['cash']!.toJson()).rules['K']!.cost, 120);
  });

  test('question card: flips to the question, a tap reveals the answer to all, then the host picks the loser', () async {
    final classic = completeMode('classic');
    customModes['quiz'] = classic.copyWith(rules: {
      ...classic.rules,
      'A': classic.rules['A']!.copyWith(answer: const LText('القاهرة', 'El Qahera')),
    });
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('A', '♥')], mode: 'quiz');
    game.tapCard();
    expect(game.phase, CardPhase.front);
    expect(game.answerShown, isFalse);
    expect((game.snapshotForTest()['rule'] as Map).containsKey('answer'), isFalse);
    await waitTap();
    game.tapCard(); // الكشف
    expect(game.answerShown, isTrue);
    expect(game.phase, CardPhase.front);
    expect((game.snapshotForTest()['rule'] as Map)['answer'], {'ar': 'القاهرة', 'fr': 'El Qahera'});
    await waitTap();
    game.tapCard(); // اختيار الخسران
    expect(game.phase, CardPhase.choosing);
    game.pickLoser(2);
    expect(game.players[2].cards.single.label, 'A♥');
  });

  test('turn inside the card: the arrow starts at the card owner, the host moves it, phones cannot', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('9', '♥')]); // 9 = وزن وقافية
    game.tapCard();
    expect(game.innerTurn, 0);
    game.moveInnerTurn(1);
    expect(game.innerTurn, 1);
    expect(game.questionEndsAt, isNotNull); // المؤقت بيبدأ من الأول مع كل لاعب
    game.moveInnerTurn(1);
    game.moveInnerTurn(1);
    expect(game.innerTurn, 0); // بيلف
    game.moveInnerTurn(-1);
    expect(game.innerTurn, 2);
    expect(game.snapshotForTest()['inner'], 2);
    game.isViewer = true;
    game.moveInnerTurn(1);
    expect(game.innerTurn, 2);
    game.isViewer = false;
    await waitTap();
    game.tapCard();
    game.pickNobody();
    expect(game.innerTurn, isNull);
    // كارت عادي مالوش سهم
    expect(getRule('classic', 'K').hasPassAround, isFalse);
    expect(getRule('classic', '8').hasPassAround, isTrue);
  });

  test('clap order is recorded in arrival order and stays on the card back until the next card', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♠'), const PlayingCard('5', '♥')]);
    for (var i = 0; i < 3; i++) {
      game.handleRemoteAction({'type': 'claim', 'player': i, 'device': 'p$i'});
    }
    game.tapCard();
    for (final p in [1, 2, 0]) {
      game.handleRemoteAction({'type': 'clap', 'player': p, 'device': 'p$p'});
    }
    await waitTap();
    game.tapCard(); // الهوست قفل التصفيق
    game.pickLoser(game.clapLast!);
    expect(game.currentCard, isNull);
    expect(game.lastClapOrder, ['B', 'C', 'A']); // الأول B والأخير A
    expect(game.players[0].cards.single.label, '5♥');
    expect(game.snapshotForTest()['clapOrder'], ['B', 'C', 'A']);
    await waitTap();
    game.tapCard(); // الكارت الجاي
    expect(game.lastClapOrder, isEmpty);
  });

  test('quick reactions: only real emojis, rate limited per phone, muted phones blocked', () async {
    expect(GameController.isValidReaction('😂'), isTrue);
    expect(GameController.isValidReaction('❤️'), isTrue);
    expect(GameController.isValidReaction('hello'), isFalse);
    expect(GameController.isValidReaction('يلا'), isFalse);
    expect(GameController.isValidReaction('😂😂😂😂😂😂😂😂😂'), isFalse);
    final game = newGame([const PlayingCard('2', '♣')]);
    expect(game.acceptReactionForTest('🔥', 'Omar', 'p1'), isTrue);
    expect(game.acceptReactionForTest('🔥', 'Omar', 'p1'), isFalse); // بسرعة أوي
    expect(game.acceptReactionForTest('😂', 'Mona', 'p2'), isTrue);
    expect(game.reactionFeed.map((r) => r.emoji), ['🔥', '😂']);
    game.toggleMute('p3');
    expect(game.acceptReactionForTest('👀', 'X', 'p3'), isFalse);
    game.setReactionButton(0, '🍿');
    expect(game.reactionButtons.first, '🍿');
    game.setReactionButton(1, 'abc');
    expect(game.reactionButtons[1], '👏');
    game.goHome();
    expect(game.reactionFeed, isEmpty);
    expect(game.reactionButtons, GameController.defaultReactions);
  });
}
