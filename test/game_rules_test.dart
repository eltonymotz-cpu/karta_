// اختبارات المزايا الجديدة: السكيب، التصحيح، الصلاحيات، المؤقتات، الكروت المقفولة، علامة الصمت
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

/// لعبة جاهزة بـ 3 لاعيبة وكومة متحددة (آخر كارت في القائمة هو اللي بيتسحب الأول)
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

  test('host skip discards the card without giving it to anyone and moves the turn', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('10', '♠'), const PlayingCard('K', '♥')]);
    game.tapCard(); // K
    expect(game.canSkip, isTrue);
    expect(game.skipCard(), isTrue);
    expect(game.currentCard, isNull);
    expect(game.currentIndex, 1);
    expect(game.players.every((p) => p.cards.isEmpty), isTrue);
    expect(game.lastEvent!.kind, GameEventKind.skip);
    expect(game.skipCard(), isFalse); // مفيش كارت: مينفعش سكيب تاني

    // سكيب لكادو اتفعّل لما اتقلب: الكادو بيتشال
    await waitTap();
    game.tapCard(); // 10 (كادو)
    expect(game.caduActive, isTrue);
    game.skipCard();
    expect(game.caduActive, isFalse);
  });

  test('a player phone cannot skip, pick a loser or correct cards', () {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♥')]);
    game.tapCard();
    game.isViewer = true; // نفس اللعبة لكن من موبايل لاعب
    expect(game.canSkip, isFalse);
    expect(game.skipCard(), isFalse);
    game.pickLoser(0);
    expect(game.players[0].cards, isEmpty);
    expect(game.removeCardFrom(0, 0), isFalse);
    expect(game.currentCard!.label, 'K♥');
  });

  test('host ignores unauthorized remote requests and only draws for the seat owner on their turn', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('3', '♦'), const PlayingCard('K', '♥')]);

    // طلب سكيب من موبايل لاعب: بيتجاهل
    game.handleRemoteAction({'type': 'skip', 'device': 'phone-1'});
    // سحب من غير ما يمسك اللاعب: بيتجاهل
    game.handleRemoteAction({'type': 'draw', 'player': 0, 'device': 'phone-1'});
    expect(game.currentCard, isNull);

    // phone-1 يمسك اللاعب 1 (B) ويحاول يسحب في دور اللاعب 0: بيتجاهل
    game.handleRemoteAction({'type': 'claim', 'player': 1, 'device': 'phone-1'});
    expect(game.claims[1], 'phone-1');
    game.handleRemoteAction({'type': 'draw', 'player': 0, 'device': 'phone-1'});
    expect(game.currentCard, isNull);

    // موبايل تاني يحاول يمسك نفس اللاعب: مرفوض
    game.handleRemoteAction({'type': 'claim', 'player': 1, 'device': 'phone-2'});
    expect(game.claims[1], 'phone-1');

    // phone-2 يمسك اللاعب 0 (صاحب الدور) ويسحب: مسموح
    game.handleRemoteAction({'type': 'claim', 'player': 0, 'device': 'phone-2'});
    game.handleRemoteAction({'type': 'draw', 'player': 0, 'device': 'phone-2'});
    expect(game.currentCard!.label, 'K♥');
    // طلب سحب تاني والكارت لسه مقلوب: بيتجاهل (مفيش سحب مزدوج)
    await waitTap();
    game.handleRemoteAction({'type': 'draw', 'player': 0, 'device': 'phone-2'});
    expect(game.deck.length, 2);

    // الهوست يختار الخسران → الدور للاعب 1 → phone-1 يقدر يسحب
    game.tapCard();
    game.pickLoser(2);
    expect(game.currentIndex, 1);
    await waitTap();
    game.handleRemoteAction({'type': 'draw', 'player': 1, 'device': 'phone-1'});
    expect(game.currentCard!.label, '3♦');
  });

  test('host can remove a wrongly awarded card, and removing the held Q ends the silence', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('Q', '♠'), const PlayingCard('K', '♥')]);
    game.tapCard();
    await waitTap();
    game.tapCard();
    game.pickLoser(2); // C خد K بالغلط
    expect(game.players[2].cards.length, 1);
    expect(game.lastEvent!.kind, GameEventKind.loss);
    expect(game.removeCardFrom(2, 0), isTrue);
    expect(game.players[2].cards, isEmpty);
    expect(game.lastEvent!.kind, GameEventKind.correction);
    expect(game.log.first.ar, contains('تصحيح'));

    // Q: B ياخدها ويبقى صامت، وشيلها بالتصحيح بيخلّص الصمت
    await waitTap();
    game.tapCard();
    await waitTap();
    game.tapCard();
    expect(game.silentIndex, 1);
    expect(game.removeCardFrom(1, 0), isTrue);
    expect(game.silentIndex, -1);
    expect(game.removeCardFrom(1, 0), isFalse); // مفيش كروت: مينفعش
  });

  test('the Q marker hides while a card is active and comes back after, without changing the silence', () async {
    final game = newGame([
      const PlayingCard('2', '♣'),
      const PlayingCard('K', '♥'),
      const PlayingCard('Q', '♠'),
    ]);
    game.tapCard();
    await waitTap();
    game.tapCard(); // A ياخد Q
    expect(game.showSilenceMarker, isTrue);
    await waitTap();
    game.tapCard(); // كارت جديد شغال
    expect(game.showSilenceMarker, isFalse);
    expect(game.silentIndex, 0); // الصمت نفسه لسه شغال
    await waitTap();
    game.tapCard();
    game.pickNobody();
    expect(game.showSilenceMarker, isTrue);
    expect(game.silentIndex, 0);
  });

  test('bomb picks a hidden random duration inside the configured range', () async {
    for (final max in [30, 40]) {
      final seen = <int>{};
      for (var i = 0; i < 12; i++) {
        final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('J', '♠')]);
        game.settings.bombMaxSeconds = max;
        game.tapCard();
        await waitTap();
        game.tapCard(); // تشغيل القنبلة
        expect(game.phase, CardPhase.bombTicking);
        final seconds = game.bombEndsAt!.difference(DateTime.now()).inMilliseconds / 1000;
        expect(seconds, inInclusiveRange(9.5, max + 0.5));
        seen.add(seconds.round());
        game.skipCard(); // السكيب بيوقف القنبلة
        expect(game.bombEndsAt, isNull);
        game.dispose();
      }
      expect(seen.length, greaterThan(2)); // الوقت بيتغير من مرة للتانية
    }
  });

  test('question timer starts on timed cards, stops when the turn moves on, and times out once', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('9', '♠'), const PlayingCard('9', '♥')]);
    game.settings.questionSeconds = 20;
    game.tapCard(); // 9 = وزن وقافية (بمؤقت)
    expect(game.questionEndsAt, isNotNull);
    await waitTap();
    game.tapCard(); // الدور خلص قبل الوقت
    expect(game.questionEndsAt, isNull);
    expect(game.phase, CardPhase.choosing);
    game.pickNobody();

    // كارت بمؤقت ثانية واحدة: بيخلص لوحده ويفتح اختيار الخسران من غير عقوبة
    customModes['fast'] = GameMode(
      emoji: '⏱',
      name: const LText('سريع', 'Fast'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {
        for (final r in cardRanks) r: r == 'A' ? getRule('classic', 'A').copyWith(timed: true, timerSeconds: 1) : getRule('classic', r),
      },
    );
    final fast = newGame([const PlayingCard('2', '♣'), const PlayingCard('A', '♠')], mode: 'fast');
    fast.tapCard();
    expect(fast.questionEndsAt, isNotNull);
    await Future.delayed(const Duration(milliseconds: 1300));
    expect(fast.timedOut, isTrue);
    expect(fast.phase, CardPhase.choosing);
    expect(fast.lastEvent!.kind, GameEventKind.timeout);
    expect(fast.players.every((p) => p.cards.isEmpty), isTrue); // مفيش عقوبة تلقائية
    final eventId = fast.lastEvent!.id;
    await Future.delayed(const Duration(milliseconds: 300));
    expect(fast.lastEvent!.id, eventId); // الانتهاء حصل مرة واحدة بس
  });

  test('disabled cards are left out of the deck', () {
    customModes['nok'] = GameMode(
      emoji: '🚫',
      name: const LText('من غير K', 'No K'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {for (final r in cardRanks) r: r == 'K' ? getRule('classic', 'K').copyWith(enabled: false) : getRule('classic', r)},
    );
    final game = GameController()..sound.enabled = false;
    game.setMode('nok');
    game.startGame(['A', 'B', 'C']);
    expect(game.deck.length, 48);
    expect(game.deck.any((c) => c.rank == 'K'), isFalse);
    expect(GameController.deckSize('nok'), 48);
  });

  test('card design and settings survive JSON round trips and modeWithCard edits', () {
    final rule = getRule('classic', 'A').copyWith(
      subtitle: const LText('سطر', 'Satr'),
      timed: true,
      timerSeconds: 30,
      enabled: false,
      design: const CardDesign(bg: 0xFF112233, sticker: 'heart', iconScale: 1.3, pattern: 'dots', back: 0xFF445566, titleOnBack: true),
    );
    final copy = CardRule.fromJson(rule.toJson());
    expect(copy.subtitle!.fr, 'Satr');
    expect(copy.timerSeconds, 30);
    expect(copy.enabled, isFalse);
    expect(copy.design.bg, 0xFF112233);
    expect(copy.design.sticker, 'heart');
    expect(copy.design.iconScale, 1.3);
    expect(copy.design.titleOnBack, isTrue);
    expect(copy.category, CardCategory.normal);
    expect(getRule('classic', 'J').category, CardCategory.bomb);
    expect(getRule('classic', 'Q').isAction, isTrue);

    // تعديل كارت من الـ 13 + إضافة كارت زيادة + مسحه
    customModes['classic'] = modeWithCard('classic', oldLabel: 'A', label: 'A', newRule: rule);
    expect(getRule('classic', 'A').design.pattern, 'dots');
    customModes['classic'] = modeWithCard('classic', oldLabel: null, label: 'JK', newRule: rule, copies: 3);
    expect(cardsOf('classic').where((c) => c.isExtra).single.copies, 3);
    customModes['classic'] = modeWithCard('classic', oldLabel: 'JK', label: 'JK', newRule: null);
    expect(cardsOf('classic').where((c) => c.isExtra), isEmpty);
    expect(getRule('classic', 'A').design.pattern, 'dots'); // التعديل الأول لسه موجود
  });
}
