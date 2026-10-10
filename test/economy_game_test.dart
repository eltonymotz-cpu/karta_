// الكوينز جوه اللعبة نفسها: ضريبة لما حد ياخد كارت، رجوعها مع التصحيح، صلاحيات موبايلات اللاعيبة،
// الإيقاف المؤقت، ونهاية اللعبة
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/game/economy.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

/// نمط بالفلوس (نسخة من الكلاسيك والأدمن فاتح فيه "بالفلوس")
GameController newGame(List<PlayingCard> deck) {
  customModes['money'] = completeMode('classic').copyWith(money: true);
  final game = GameController()..sound.enabled = false;
  game.setMode('money');
  game.startGame(['A', 'B', 'C']);
  game.deck = deck;
  return game;
}

Future<void> waitTap() => Future.delayed(const Duration(milliseconds: 300));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => customModes.clear());

  test('taking a card charges the round tax once, a correction refunds it, and nobody-lost does not tax', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♠'), const PlayingCard('K', '♥')]);
    expect(game.coinsOn, isTrue);
    expect(game.economy.balanceOf(1), 1000);
    game.tapCard();
    await waitTap();
    game.tapCard();
    game.pickLoser(1);
    game.pickLoser(1); // ضغطة مزدوجة: الكارت خلاص اتدى، مفيش ضريبة تانية
    expect(game.economy.balanceOf(1), 950);
    expect(game.coinFx.last.delta, -50);

    game.removeCardFrom(1, 0); // اتدى بالغلط
    expect(game.economy.balanceOf(1), 1000);

    await waitTap();
    game.tapCard();
    await waitTap();
    game.tapCard();
    game.pickNobody();
    expect(game.economy.wallets.every((w) => w.balance == 1000), isTrue);
    game.dispose();
  });

  test('player phones can only move coins for the seat they hold', () {
    final game = newGame([const PlayingCard('2', '♣')]);
    game.handleRemoteAction({'type': 'claim', 'player': 0, 'device': 'phone-a'});
    // phone-a يحاول يحوّل من لاعب مش بتاعه
    game.handleRemoteAction({'type': 'coinTransfer', 'id': 't1', 'from': 1, 'to': 0, 'amount': 50, 'device': 'phone-a'});
    expect(game.economy.balanceOf(1), 1000);
    // من لاعبه: مسموح
    game.handleRemoteAction({'type': 'coinTransfer', 'id': 't2', 'from': 0, 'to': 2, 'amount': 50, 'device': 'phone-a'});
    expect([game.economy.balanceOf(0), game.economy.balanceOf(2)], [950, 1050]);
    // نفس الطلب اتبعت تاني: مابيتنفذش تاني
    game.handleRemoteAction({'type': 'coinTransfer', 'id': 't2', 'from': 0, 'to': 2, 'amount': 50, 'device': 'phone-a'});
    expect(game.economy.balanceOf(0), 950);

    // التحدي: الدعوة من صاحب اللاعب، والرد من صاحب اللاعب التاني بس
    game.handleRemoteAction({'type': 'challenge', 'id': 'c1', 'from': 0, 'to': 1, 'stake': 20, 'device': 'phone-a'});
    final challenge = game.economy.challenges.single;
    game.handleRemoteAction({'type': 'challengeReply', 'id': 'r1', 'challenge': challenge.id, 'accept': true, 'device': 'phone-a'});
    expect(challenge.status, ChallengeStatus.pending);
    game.handleRemoteAction({'type': 'claim', 'player': 1, 'device': 'phone-b'});
    game.handleRemoteAction({'type': 'challengeReply', 'id': 'r2', 'challenge': challenge.id, 'accept': true, 'device': 'phone-b'});
    expect(challenge.status, ChallengeStatus.active);
    game.dispose();
  });

  test('host transfers, challenges and manual adjustments work on a single phone', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('K', '♥')]);
    expect(await game.transferCoins(0, 1, 30), isNull);
    expect(await game.transferCoins(0, 0, 30), 'self');
    expect(await game.inviteChallenge(1, 2, 40), isNull);
    final id = game.economy.challenges.single.id;
    expect(await game.replyChallenge(id, true), isNull);
    expect(game.adjustCoins(2, 10, ''), 'reason');
    expect(game.adjustCoins(2, 10, 'prize'), isNull);
    // C بياخد كارت → B يكسب التحدي
    game.tapCard();
    await waitTap();
    game.tapCard();
    game.pickLoser(2);
    expect(game.economy.challenges.single.winner, 1);
    game.dispose();
  });

  test('pause blocks draws and freezes the question timer, resume continues it', () async {
    final game = newGame([const PlayingCard('2', '♣'), const PlayingCard('9', '♥'), const PlayingCard('K', '♥')]);
    game.togglePause();
    game.tapCard();
    expect(game.currentCard, isNull); // واقفة: مفيش سحب
    game.handleRemoteAction({'type': 'claim', 'player': 0, 'device': 'p'});
    game.handleRemoteAction({'type': 'draw', 'player': 0, 'device': 'p'});
    expect(game.currentCard, isNull);
    game.togglePause();
    game.tapCard();
    expect(game.currentCard!.label, 'K♥');
    await waitTap();
    game.tapCard();
    game.pickNobody();
    await waitTap();
    game.tapCard(); // 9 = كارت بمؤقت
    expect(game.questionEndsAt, isNotNull);
    game.togglePause();
    expect(game.questionEndsAt, isNull);
    expect(game.activeTurn!.isPaused, isTrue);
    game.togglePause();
    expect(game.questionEndsAt, isNotNull);
    expect(game.activeTurn!.isPaused, isFalse);
    game.dispose();
  });

  test('closing the game wipes every balance and transaction', () {
    final game = newGame([const PlayingCard('2', '♣')]);
    game.adjustCoins(0, 5, 'test');
    game.goHome();
    expect(game.economy.wallets, isEmpty);
    expect(game.economy.log, isEmpty);
    expect(game.coinFx, isEmpty);
    game.dispose();
  });
}
