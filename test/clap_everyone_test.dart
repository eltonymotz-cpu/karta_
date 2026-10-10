// التصفيق في أكتر من موبايل: الهوست لاعب زي الباقيين، والكارت مابيتقفلش من أي حد
// غير لما الكل يصقّف، وبعدها بيظهر الأول والأخير (والأخير ممكن يكون الهوست نفسه)
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/models.dart';

GameController onlineGame(List<PlayingCard> deck) {
  final game = GameController()..sound.enabled = false;
  game.onlineForTest = true;
  game.startGame(['Host', 'B', 'C']);
  game.deck = deck;
  game.claimSeat(0); // الهوست اختار إنه "Host"
  game.handleRemoteAction({'type': 'claim', 'player': 1, 'device': 'pb'});
  game.handleRemoteAction({'type': 'claim', 'player': 2, 'device': 'pc'});
  return game;
}

Future<void> waitTap() => Future.delayed(const Duration(milliseconds: 300));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => customModes.clear());

  test('nobody can close the clap card early; it closes by itself when everyone (host included) clapped', () async {
    final game = onlineGame([const PlayingCard('2', '♣'), const PlayingCard('5', '♥')]);
    expect(game.claims[0], game.deviceId);
    game.tapCard(); // الكارت اتقلب: تصفيق
    expect(game.phase, CardPhase.clapGo);
    expect(game.clapPlayers, {0, 1, 2});

    game.handleRemoteAction({'type': 'clap', 'player': 2, 'device': 'pc'});
    await waitTap();
    game.tapCard(); // دوسة الهوست = تصفيق الهوست، مش قفل
    expect(game.clapTaps.map((t) => t.player), [2, 0]);
    expect(game.phase, CardPhase.clapGo); // لسه B ماصقّفش
    expect(game.clapWaitingFor, {1});
    await waitTap();
    game.tapCard(); // الهوست يدوس تاني: مفيش حاجة (صقّف خلاص) والكارت مابيتقفلش
    expect(game.phase, CardPhase.clapGo);
    expect(game.clapLast, isNull); // مانقولش مين الأخير قبل ما الكل يخلص

    game.handleRemoteAction({'type': 'clap', 'player': 1, 'device': 'pb'}); // آخر واحد
    expect(game.phase, CardPhase.choosing); // اتقفل لوحده
    expect(game.clapFirst, 2);
    expect(game.clapLast, 1);
  });

  test('the host can be the last clapper and lose like anyone else', () async {
    final game = onlineGame([const PlayingCard('2', '♣'), const PlayingCard('6', '♥')]);
    game.tapCard();
    game.handleRemoteAction({'type': 'clap', 'player': 1, 'device': 'pb'});
    game.handleRemoteAction({'type': 'clap', 'player': 2, 'device': 'pc'});
    await waitTap();
    game.tapCard(); // الهوست آخر واحد
    expect(game.clapLast, 0);
    game.pickLoser(game.clapLast!);
    expect(game.players[0].cards.single.label, '6♥');
    expect(game.lastClapOrder, ['B', 'C', 'Host']);
  });

  test('admin fines per card are saved with the mode and charged in money modes', () async {
    final classic = completeMode('classic');
    customModes['fines'] = classic.copyWith(money: true, rules: {...classic.rules, '5': classic.rules['5']!.copyWith(cost: 300)});
    final back = GameMode.fromJson(customModes['fines']!.toJson());
    expect(back.money, isTrue);
    expect(back.rules['5']!.cost, 300);

    final game = GameController()..sound.enabled = false;
    game.setMode('fines');
    game.startGame(['A', 'B', 'C']);
    game.deck = [const PlayingCard('2', '♣'), const PlayingCard('5', '♥')];
    game.tapCard();
    await waitTap();
    game.tapCard(); // موبايل واحد: الدوسة بتفتح اختيار الخسران
    game.pickLoser(2);
    expect(game.economy.balanceOf(2), 700);
  });
}
