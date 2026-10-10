// اختبارات الكوينز: رصيد البداية، الضريبة وحدودها، الرصيد اللي مايكفيش، منع التكرار،
// المكافآت، التحويلات (كلها أو مفيش)، التحديات، التصحيح، والتعديل اليدوي
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/game/economy.dart';

Economy eco([EconomyConfig cfg = const EconomyConfig(), int players = 3]) => Economy()..start(players, cfg, 0);
int total(Economy e) => e.wallets.fold(0, (s, w) => s + w.balance) + e.pot;

void main() {
  test('starting balance and default 5% tax clamped between 10 and 100, burned by default', () {
    final e = eco();
    expect(e.wallets.map((w) => w.balance), [1000, 1000, 1000]);
    // 1000 × 5% = 50
    final changes = e.settleRound('r1', [0], now: 1);
    expect(changes.single.delta, -50);
    expect(e.balanceOf(0), 950);
    expect(e.wallets[0].taxPaid, 50);
    expect(e.burned, 50); // الضريبة بتتحرق (زي ما اتفقنا)
    expect(total(e), 2950);
    // الحدود: رصيد 100 → 5 بس، بس الأقل 10
    expect(e.taxFor(100, null), 10);
    // رصيد 5000 → 250، بس الأقصى 100
    expect(e.taxFor(5000, null), 100);
  });

  test('the same round is never taxed twice (double taps, retries, reconnects)', () {
    final e = eco();
    e.settleRound('r7', [1], now: 1);
    e.settleRound('r7', [1], now: 2);
    e.settleRound('r7', [1, 1], now: 3);
    expect(e.balanceOf(1), 950);
    expect(e.log.where((t) => t.kind == CoinKind.tax).length, 1);
    // جولة جديدة = ضريبة جديدة (على الرصيد الجديد)
    e.settleRound('r8', [1], now: 4);
    expect(e.balanceOf(1), 950 - 48); // 950 × 5% = 47.5 → 48
  });

  test('fixed tax, category overrides, multiple losers and insufficient balances never go negative', () {
    final fixed = eco(const EconomyConfig(taxMethod: 'fixed', taxFixed: 300, startBalance: 250));
    fixed.settleRound('r1', [0, 2], now: 1);
    expect(fixed.balanceOf(0), 0); // ياخد اللي معاه بس
    expect(fixed.balanceOf(2), 0);
    expect(fixed.balanceOf(1), 250);
    fixed.settleRound('r2', [0], now: 2); // رصيده صفر: مفيش حاجة تتخصم
    expect(fixed.balanceOf(0), 0);

    final skip = eco(const EconomyConfig(taxMethod: 'fixed', taxFixed: 300, startBalance: 250, insufficient: 'skip'));
    skip.settleRound('r1', [0], now: 1);
    expect(skip.balanceOf(0), 250); // مابيدفعش لو مش معاه الضريبة كلها

    final byCategory = eco(const EconomyConfig(taxMethod: 'percent', taxPercent: 5, taxByCategory: {'bomb': 20}));
    byCategory.settleRound('r1', [0], category: CardCategory.bomb, now: 1);
    byCategory.settleRound('r2', [1], category: CardCategory.normal, now: 1);
    expect(byCategory.balanceOf(0), 800);
    expect(byCategory.balanceOf(1), 950);
  });

  test('tax destinations: pot paid to the game winner, shared to others, or to the turn player', () {
    final pot = eco(const EconomyConfig(taxDestination: 'pot', rewardGameWin: 0));
    pot.settleRound('r1', [0], now: 1);
    pot.settleRound('r2', [1], now: 1);
    expect(pot.pot, 100);
    pot.endGame([2], 9);
    expect(pot.balanceOf(2), 1100);
    expect(pot.pot, 0);
    expect(total(pot), 3000); // مفيش كوينز اتعملت ولا اتحرقت
    pot.endGame([2], 10); // نهاية اللعبة مرة واحدة بس
    expect(pot.balanceOf(2), 1100);

    final others = eco(const EconomyConfig(taxDestination: 'others'));
    others.settleRound('r1', [0], now: 1);
    expect([others.balanceOf(1), others.balanceOf(2)], [1025, 1025]);

    final turn = eco(const EconomyConfig(taxDestination: 'turnPlayer'));
    turn.settleRound('r1', [2], turnPlayer: 0, now: 1);
    expect(turn.balanceOf(0), 1050);
  });

  test('rewards are paid once, can be revoked, and the game-win reward is split on ties', () {
    final e = eco(const EconomyConfig(rewardAnswered: 25, rewardGameWin: 200));
    expect(e.reward('ans:3', 1, 25, 'answered', 1)!.delta, 25);
    expect(e.reward('ans:3', 1, 25, 'answered', 2), isNull);
    expect(e.balanceOf(1), 1025);
    e.revokeReward('ans:3', 3);
    expect(e.balanceOf(1), 1000);
    e.endGame([0, 2], 9);
    expect([e.balanceOf(0), e.balanceOf(2)], [1100, 1100]);
  });

  test('transfers are all-or-nothing and respect every limit', () {
    final e = eco(const EconomyConfig(transferMax: 100, transferFeePercent: 10, transferCooldownSec: 10, transferMaxPerGame: 2));
    expect(e.transfer('t1', 0, 0, 10, 0), 'self');
    expect(e.transfer('t1', 0, 1, 0, 0), 'limits');
    expect(e.transfer('t1', 0, 1, 101, 0), 'limits');
    expect(e.transfer('t1', 0, 1, 50, 0), isNull);
    expect([e.balanceOf(0), e.balanceOf(1)], [945, 1050]); // 50 + رسوم 5
    expect(e.transfer('t1', 0, 1, 50, 1), isNull); // نفس الطلب اتكرر: مابيتنفذش تاني
    expect(e.balanceOf(0), 945);
    expect(e.transfer('t2', 0, 1, 50, 5000), 'cooldown');
    expect(e.transfer('t2', 0, 1, 50, 20000), isNull);
    expect(e.transfer('t3', 0, 1, 10, 40000), 'tooMany');

    final poor = eco(const EconomyConfig(startBalance: 30));
    expect(poor.transfer('p1', 0, 1, 50, 0), 'balance');
    expect([poor.balanceOf(0), poor.balanceOf(1)], [30, 30]); // ولا حاجة اتغيرت

    final frozen = eco(const EconomyConfig(frozen: true));
    expect(frozen.transfer('f1', 0, 1, 10, 0), 'frozen');
  });

  test('challenges: both accept, first to take a card loses, ties refund, no confiscation', () {
    final e = eco(const EconomyConfig(stakeMin: 10, stakeMax: 100));
    expect(e.invite('c1', 0, 0, 50, 0), 'self');
    expect(e.invite('c1', 0, 1, 500, 0), 'limits');
    expect(e.invite('c1', 0, 1, 50, 0), isNull);
    expect(e.balanceOf(0), 1000); // الرهان مابيتخصمش قبل الموافقة
    expect(e.invite('c2', 1, 0, 50, 0), 'exists');
    expect(e.respond('c1', true, 1000), isNull);
    expect([e.balanceOf(0), e.balanceOf(1)], [950, 950]);
    // B خد كارت → A كسب الرهان كله
    e.onCardTaken(1, 2000);
    expect(e.balanceOf(0), 1050);
    expect(e.challenges.single.winner, 0);
    e.onCardTaken(1, 3000); // مابيتحسبش تاني
    expect(e.balanceOf(0), 1050);

    // تحدي ماخلصش لحد آخر اللعبة: الرهان بيرجع للاتنين
    final tie = eco(const EconomyConfig(rewardGameWin: 0));
    tie.invite('c1', 0, 2, 40, 0);
    tie.respond('c1', true, 1);
    tie.endGame([1], 9);
    expect([tie.balanceOf(0), tie.balanceOf(2)], [1000, 1000]);

    // دعوة اتأخر الرد عليها: انتهت ومحدش خسر حاجة
    final late = eco(const EconomyConfig(inviteTimeoutSec: 60));
    late.invite('c1', 0, 1, 20, 0);
    expect(late.respond('c1', true, 61000), 'expired');
    expect([late.balanceOf(0), late.balanceOf(1)], [1000, 1000]);
    late.invite('c2', 0, 1, 20, 0);
    expect(late.respond('c2', false, 1), isNull);
    expect(late.challenges.last.status, ChallengeStatus.declined);
  });

  test('correction refunds the tax of the removed card once, and manual adjustments need a reason', () {
    final e = eco();
    e.settleRound('r1', [0], card: 'K♥', now: 1);
    expect(e.balanceOf(0), 950);
    expect(e.refundTaxForCard(0, 'K♥', 2)!.delta, 50);
    expect(e.refundTaxForCard(0, 'K♥', 3), isNull);
    expect(e.balanceOf(0), 1000);

    expect(e.adjust('a1', 1, 100, '', 1), 'reason');
    expect(e.adjust('a1', 1, 100, 'bonus for the host', 1), isNull);
    expect(e.adjust('a1', 1, 100, 'bonus for the host', 1), isNull); // مكرر
    expect(e.balanceOf(1), 1100);
    expect(e.adjust('a2', 1, -5000, 'mistake fix', 2), isNull);
    expect(e.balanceOf(1), 0); // مفيش سالب
    expect(e.log.last.note, contains('1100 → 0'));
  });

  test('max balance caps credits, and config limits and validation work', () {
    final e = eco(const EconomyConfig(maxBalance: 1050, rewardAnswered: 100));
    e.reward('x', 0, 100, 'answered', 1);
    expect(e.balanceOf(0), 1050);

    final cfg = EconomyConfig.fromJson({'taxPercent': 900, 'transferMin': 0, 'icon': 'javascript:x', 'taxMethod': 'weird'});
    expect(cfg.taxPercent, 100);
    expect(cfg.transferMin, 1);
    expect(cfg.icon, const EconomyConfig().icon);
    expect(cfg.taxMethod, 'percentClamped');
    expect(const EconomyConfig(taxMin: 200, taxMax: 100).validate(), isNotEmpty);
    expect(EconomyConfig.fromJson(const EconomyConfig().toJson()).toJson(), const EconomyConfig().toJson());
  });

  test('player phones mirror the host state without calculating anything', () {
    final host = eco();
    host.settleRound('r1', [0], now: 1);
    host.invite('c1', 1, 2, 30, 1);
    final phone = Economy()..applyJson(host.toJson());
    expect(phone.balanceOf(0), 950);
    expect(phone.challenges.single.status, ChallengeStatus.pending);
    expect(phone.log.length, host.log.length);
  });
}
