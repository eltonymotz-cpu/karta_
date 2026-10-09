// اختبارات: ساعة كل لاعب، زرار التصفيق (أول/آخر)، كشف الإجابة، الترتيب، ورفع الصور
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';
import 'package:karta/services/storage_service.dart';

/// لعبة جاهزة بـ 3 لاعيبة وكومة متحددة (آخر كارت في القائمة هو اللي بيتسحب الأول)
GameController newGame(List<PlayingCard> deck, {String mode = 'classic'}) {
  final game = GameController()..sound.enabled = false;
  game.setMode(mode);
  game.startGame(['A', 'B', 'C']);
  game.deck = deck;
  return game;
}

Future<void> waitTap() => Future.delayed(const Duration(milliseconds: 300));

/// بنقدّم الساعة من غير ما نستنى فعلاً (كل الأوقات بتتحسب من nowMs)
void advance(GameController game, int ms) => game.clockOffset += ms;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => customModes.clear());

  test('every player has an independent stopwatch that is saved when the turn ends', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♥'), const PlayingCard('K', '♠')]);

    // A يسحب: ساعته بتبدأ من 00:00
    game.tapCard();
    expect(game.activeTurn!.player, 0);
    expect(game.activeTurn!.elapsedMs(game.nowMs), lessThan(200));
    advance(game, 35000);
    await waitTap();
    game.tapCard();
    game.pickNobody(); // الدور خلص
    expect(game.activeTurn, isNull);
    final aTime = game.turns.first.elapsedMs(game.nowMs);
    expect(aTime, inInclusiveRange(35000, 35500));
    expect(game.turns.first.status, TurnStatus.finished);

    // B يسحب: ساعة جديدة من الصفر، ووقت A مابيتغيرش
    await waitTap();
    game.tapCard();
    expect(game.activeTurn!.player, 1);
    expect(game.activeTurn!.elapsedMs(game.nowMs), lessThan(200));
    advance(game, 10000);
    expect(game.turns.first.elapsedMs(game.nowMs), aTime);

    // إيقاف مؤقت: الوقت مابيزيدش، والتكملة بتكمّل من نفس المكان
    game.toggleTurnPause();
    expect(game.activeTurn!.isPaused, isTrue);
    final paused = game.activeTurn!.elapsedMs(game.nowMs);
    advance(game, 20000);
    expect(game.activeTurn!.elapsedMs(game.nowMs), paused);
    game.toggleTurnPause();
    advance(game, 5000);
    expect(game.activeTurn!.elapsedMs(game.nowMs), inInclusiveRange(paused + 5000, paused + 5300));

    // الهوست يسجل إن B ماجاوبش، وبعدين الدور يخلص: الحالة بتفضل
    game.markTurn(TurnStatus.noAnswer);
    await waitTap();
    game.tapCard();
    game.pickLoser(1);
    expect(game.turns[1].status, TurnStatus.noAnswer);
    expect(game.turns[1].isActive, isFalse);

    // نفس اللاعب في دور تاني: دور جديد مايمسحش القديم
    expect(game.playerTotalMs(0), aTime);
    expect(game.turns.length, 2);
  });

  test('only one active turn at a time, the host can skip a player, and players cannot control the clock', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♥')]);
    expect(game.canSkipPlayer, isTrue);
    game.skipPlayer(); // A اتعدّى من غير ما يسحب
    expect(game.currentIndex, 1);
    expect(game.turns.single.status, TurnStatus.skipped);

    game.tapCard(); // B يسحب
    expect(game.turns.where((t) => t.isActive).length, 1);
    expect(game.canSkipPlayer, isFalse); // فيه كارت شغال

    // موبايل لاعب: مايقدرش يوقف الساعة أو يغيّر الحالة أو ينهي الدور
    game.isViewer = true;
    game.toggleTurnPause();
    game.markTurn(TurnStatus.answered);
    game.endTurnNow();
    game.skipPlayer();
    expect(game.activeTurn!.isPaused, isFalse);
    expect(game.activeTurn!.status, TurnStatus.active);
    expect(game.activeTurn, isNotNull);
  });

  test('clap button records first and last from player phones, rejects duplicates and clicks after closing', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('5', '♥')]);
    for (var i = 0; i < 3; i++) {
      game.handleRemoteAction({'type': 'claim', 'player': i, 'device': 'phone-$i'});
    }
    game.tapCard(); // 5 = كارت تصفيق
    expect(game.phase, CardPhase.clapGo);
    expect(game.clapOpen, isTrue);

    game.handleRemoteAction({'type': 'clap', 'player': 2, 'device': 'phone-2'}); // C الأول
    game.handleRemoteAction({'type': 'clap', 'player': 2, 'device': 'phone-2'}); // تكرار: بيتجاهل
    game.handleRemoteAction({'type': 'clap', 'player': 1, 'device': 'phone-0'}); // موبايل مش ماسك B: بيتجاهل
    game.handleRemoteAction({'type': 'clap', 'player': 0, 'device': 'phone-0'});
    game.handleRemoteAction({'type': 'clap', 'player': 1, 'device': 'phone-1'}); // B الأخير
    expect(game.clapTaps.map((t) => t.player), [2, 0, 1]);
    expect(game.clapFirst, 2);
    expect(game.clapLast, isNull); // لسه مفتوح: مانقولش مين الأخير بدري

    // الهوست يدوس على الكارت = يقفل التصفيق
    await waitTap();
    game.tapCard();
    expect(game.clapOpen, isFalse);
    expect(game.phase, CardPhase.choosing);
    expect(game.clapLast, 1);
    expect(game.log.first.ar, contains('آخر واحد: B'));

    // ضغطة بعد القفل: مرفوضة
    expect(game.registerClap(2), isFalse);
    expect(game.clapTaps.length, 3);

    // الهوست يدي الكارت للأخير، والتصفيق بيتصفّر للكارت الجاي
    game.pickLoser(game.clapLast!);
    expect(game.players[1].cards.single.label, '5♥');
    expect(game.clapTaps, isEmpty);
  });

  test('the clap button can be turned on for another card, and off for a clap card', () async {
    final base = builtInModes['classic']!;
    customModes['custom-clap'] = GameMode(
      emoji: '👏',
      name: const LText('تجربة', 'Test'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {
        'K': getRule('classic', 'K').copyWith(clapButton: true, clapStyle: const ClapButtonStyle(shape: 'pill', position: 'bottom')),
        '5': getRule('classic', '5').copyWith(clapButton: false),
      },
    );
    expect(base.rules.isNotEmpty, isTrue);
    final game = newGame([const PlayingCard('5', '♠'), const PlayingCard('K', '♥')], mode: 'custom-clap');

    game.tapCard(); // K عليه الزرار
    expect(game.phase, CardPhase.clapGo);
    expect(game.currentRule!.clapStyle.shape, 'pill');
    await waitTap();
    game.tapCard();
    game.pickNobody();

    await waitTap();
    game.tapCard(); // 5 من غير زرار: بيتصرف زي الكارت العادي
    expect(game.phase, CardPhase.front);
    expect(game.clapOpen, isFalse);
    expect(game.registerClap(0), isFalse);

    // نوع مش مسموح (قنبلة): الزرار مايشتغلش حتى لو اتفعّل بالغلط
    expect(getRule('classic', 'J').copyWith(clapButton: true).usesClap, isFalse);

    // الإعدادات بتتحفظ وترجع زي ما هي
    final json = customModes['custom-clap']!.toJson();
    final back = GameMode.fromJson(json);
    expect(back.rules['K']!.hasClapButton, isTrue);
    expect(back.rules['K']!.clapStyle.position, 'bottom');
    expect(back.rules['5']!.hasClapButton, isFalse);
  });

  test('the answer stays out of the synced state until the host reveals it', () async {
    customModes['answers'] = GameMode(
      emoji: '❓',
      name: const LText('أسئلة', 'As2ela'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {'A': getRule('classic', 'A').copyWith(answer: const LText('القاهرة', 'El Qahera'))},
    );
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('A', '♥')], mode: 'answers');
    game.tapCard();
    expect(game.hasAnswer, isTrue);
    var snapshot = game.snapshotForTest();
    expect((snapshot['rule'] as Map).containsKey('answer'), isFalse);
    expect(snapshot['answerShown'], isFalse);

    // موبايل لاعب مايقدرش يكشفها
    game.isViewer = true;
    game.toggleAnswer();
    expect(game.answerShown, isFalse);
    game.isViewer = false;

    game.toggleAnswer();
    snapshot = game.snapshotForTest();
    expect(snapshot['answerShown'], isTrue);
    expect((snapshot['rule'] as Map)['answer'], {'ar': 'القاهرة', 'fr': 'El Qahera'});

    // موبايل لاعب بيستلم نفس الحالة ويشوف الإجابة
    final viewer = GameController()..sound.enabled = false;
    viewer.isViewer = true;
    viewer.applySnapshotForTest(snapshot);
    expect(viewer.answerShown, isTrue);
    expect(viewer.currentRule!.answer!.ar, 'القاهرة');

    // الكارت الجاي بيبدأ والإجابة مخفية
    await waitTap();
    game.tapCard();
    game.pickNobody();
    expect(game.answerShown, isFalse);
  });

  test('ranking puts the fewest cards first and ties share the same place', () {
    final game = newGame([const PlayingCard('2', '♣')]);
    game.players[0].cards.addAll([const PlayingCard('K', '♥'), const PlayingCard('K', '♠')]);
    game.players[2].cards.add(const PlayingCard('3', '♥'));
    var ranking = game.ranking;
    expect(ranking.map((e) => e.player), [1, 2, 0]);
    expect(ranking.map((e) => e.rank), [1, 2, 3]);

    game.players[1].cards.add(const PlayingCard('4', '♥')); // تعادل B و C
    ranking = game.ranking;
    expect(ranking.map((e) => e.player), [1, 2, 0]);
    expect(ranking.map((e) => e.rank), [1, 1, 3]);
  });

  test('player phones sync turns, clap order and clock offset from the host', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('6', '♥')]);
    game.handleRemoteAction({'type': 'claim', 'player': 1, 'device': 'phone-1'});
    game.tapCard();
    game.handleRemoteAction({'type': 'clap', 'player': 1, 'device': 'phone-1'});

    final viewer = GameController()..sound.enabled = false;
    viewer.isViewer = true;
    viewer.applySnapshotForTest(game.snapshotForTest());
    expect(viewer.activeTurn!.player, 0);
    expect(viewer.clapOpen, isTrue);
    expect(viewer.clapTaps.single.player, 1);
    expect(viewer.clockOffset.abs(), lessThan(1000));
  });

  test('image type is detected from the file content', () {
    expect(StorageService.sniffImageType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0])), 'png');
    expect(StorageService.sniffImageType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'jpg');
    expect(StorageService.sniffImageType(Uint8List.fromList('GIF89a'.codeUnits)), 'gif');
    expect(StorageService.sniffImageType(Uint8List.fromList([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits])), 'webp');
    expect(StorageService.sniffImageType(Uint8List.fromList('%PDF-1.4'.codeUnits)), isNull);
  });
}
