// =================================================================
// الكوينز (عملة جوه اللعبة - مالهاش أي قيمة حقيقية)
// -----------------------------------------------------------------
// - كل لعبة بتبدأ برصيد جديد لكل لاعب، والرصيد والعمليات بيتمسحوا أول ما اللعبة تتقفل
//   (مفيش أي حاجة بتتحفظ - زي ما اتفقنا).
// - الهوست هو اللي بيحسب كل حاجة (موبايلات اللاعيبة بتبعت "طلبات" بس)،
//   فمحدش يقدر يغيّر رصيده من موبايله.
// - كل عملية ليها مفتاح مميز (زي "tax:r12:3")، فلو نفس الحدث اتكرر (ضغطة مزدوجة،
//   إعادة إرسال، نت فصل ورجع) مابيتحسبش مرتين.
// - مفيش رصيد بالسالب أبداً.
// =================================================================
import 'dart:math';

import '../data/game_modes.dart';
import '../data/texts.dart';

// =================================================================
// إعدادات الكوينز (الأدمن بيغيّرها، وفيه نسخة لموبايل واحد ونسخة للأونلاين)
// =================================================================
class EconomyConfig {
  // ---------------- عام ----------------
  final bool enabled;
  final LText name;            // اسم العملة
  final String icon;           // أيقونة العملة (من مكتبة الصور)
  final int startBalance;
  final int maxBalance;
  final bool frozen;           // الأدمن جمّد كل العمليات (تحويلات/تحديات/تعديلات)

  // ---------------- ضريبة الخسارة ----------------
  final bool taxEnabled;
  final String taxMethod;      // fixed / percent / percentClamped
  final int taxFixed;
  final int taxPercent;
  final int taxMin;
  final int taxMax;
  final Map<String, int> taxByCategory; // نسبة خاصة لنوع كارت (normal/action/queen/bomb)
  final String taxDestination; // burn (تتحرق) / pot (حصالة للكسبان) / others (تتوزع على الباقيين) / turnPlayer
  final String insufficient;   // takeAll (ياخد اللي معاه) / skip (مايدفعش)

  // ---------------- المكافآت ----------------
  final int rewardGameWin;     // الكسبان في آخر اللعبة (الأقل كروت)
  final int rewardAnswered;    // الهوست سجّل إن صاحب الدور جاوب
  final int rewardNobodyLost;  // صاحب الدور لما "محدش خسر"
  final int rewardClapFirst;   // أول واحد صقّف

  // ---------------- التحويلات ----------------
  final bool transferEnabled;
  final int transferMin;
  final int transferMax;
  final int transferFeePercent;
  final int transferCooldownSec;
  final int transferMaxPerGame;

  // ---------------- التحديات ----------------
  final bool challengeEnabled;
  final int stakeMin;
  final int stakeMax;
  final int challengeFeePercent;
  final int inviteTimeoutSec;

  const EconomyConfig({
    this.enabled = true,
    this.name = const LText('فلوس', 'Floos'),
    this.icon = 'asset:pixel/money_bill.png',
    this.startBalance = 1000,
    this.maxBalance = 100000,
    this.frozen = false,
    this.taxEnabled = true,
    this.taxMethod = 'percentClamped',
    this.taxFixed = 50,
    this.taxPercent = 5,
    this.taxMin = 10,
    this.taxMax = 100,
    this.taxByCategory = const {},
    this.taxDestination = 'burn',
    this.insufficient = 'takeAll',
    this.rewardGameWin = 200,
    this.rewardAnswered = 0,
    this.rewardNobodyLost = 0,
    this.rewardClapFirst = 0,
    this.transferEnabled = true,
    this.transferMin = 1,
    this.transferMax = 100,
    this.transferFeePercent = 0,
    this.transferCooldownSec = 10,
    this.transferMaxPerGame = 20,
    this.challengeEnabled = true,
    this.stakeMin = 10,
    this.stakeMax = 100,
    this.challengeFeePercent = 0,
    this.inviteTimeoutSec = 60,
  });

  static const taxMethods = ['fixed', 'percent', 'percentClamped'];
  static const destinations = ['burn', 'pot', 'others', 'turnPlayer'];
  static const insufficientModes = ['takeAll', 'skip'];

  /// الحدود المسموحة لكل رقم (الأدمن مايقدرش يحط قيمة برا المدى)
  static const ranges = <String, (int, int)>{
    'startBalance': (0, 1000000),
    'maxBalance': (100, 10000000),
    'taxFixed': (0, 100000),
    'taxPercent': (0, 100),
    'taxMin': (0, 100000),
    'taxMax': (0, 100000),
    'rewardGameWin': (0, 100000),
    'rewardAnswered': (0, 10000),
    'rewardNobodyLost': (0, 10000),
    'rewardClapFirst': (0, 10000),
    'transferMin': (1, 100000),
    'transferMax': (1, 100000),
    'transferFeePercent': (0, 50),
    'transferCooldownSec': (0, 600),
    'transferMaxPerGame': (0, 1000),
    'stakeMin': (1, 100000),
    'stakeMax': (1, 100000),
    'challengeFeePercent': (0, 50),
    'inviteTimeoutSec': (10, 600),
  };

  /// مشاكل في الإعدادات (فاضية = سليمة)
  List<String> validate() => [
        if (taxMin > taxMax) 'taxMin > taxMax',
        if (transferMin > transferMax) 'transferMin > transferMax',
        if (stakeMin > stakeMax) 'stakeMin > stakeMax',
        if (startBalance > maxBalance) 'startBalance > maxBalance',
      ];

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'name': name.toJson(),
        'icon': icon,
        'startBalance': startBalance,
        'maxBalance': maxBalance,
        'frozen': frozen,
        'taxEnabled': taxEnabled,
        'taxMethod': taxMethod,
        'taxFixed': taxFixed,
        'taxPercent': taxPercent,
        'taxMin': taxMin,
        'taxMax': taxMax,
        'taxByCategory': taxByCategory,
        'taxDestination': taxDestination,
        'insufficient': insufficient,
        'rewardGameWin': rewardGameWin,
        'rewardAnswered': rewardAnswered,
        'rewardNobodyLost': rewardNobodyLost,
        'rewardClapFirst': rewardClapFirst,
        'transferEnabled': transferEnabled,
        'transferMin': transferMin,
        'transferMax': transferMax,
        'transferFeePercent': transferFeePercent,
        'transferCooldownSec': transferCooldownSec,
        'transferMaxPerGame': transferMaxPerGame,
        'challengeEnabled': challengeEnabled,
        'stakeMin': stakeMin,
        'stakeMax': stakeMax,
        'challengeFeePercent': challengeFeePercent,
        'inviteTimeoutSec': inviteTimeoutSec,
      };

  factory EconomyConfig.fromJson(Object? raw) {
    const d = EconomyConfig();
    if (raw is! Map) return d;
    final j = Map<String, dynamic>.from(raw);
    bool flag(String k, bool f) => j[k] is bool ? j[k] as bool : f;
    int n(String k, int f) {
      final r = ranges[k]!;
      return ((j[k] as num?)?.toInt() ?? f).clamp(r.$1, r.$2);
    }

    String pick(String k, List<String> allowed, String f) => allowed.contains(j[k]) ? j[k] as String : f;
    final byCat = <String, int>{};
    if (j['taxByCategory'] is Map) {
      (j['taxByCategory'] as Map).forEach((k, v) {
        if (CardCategory.values.any((c) => c.name == k) && v is num) byCat[k as String] = v.toInt().clamp(0, 100);
      });
    }
    final icon = j['icon'];
    return EconomyConfig(
      enabled: flag('enabled', d.enabled),
      name: j['name'] is Map ? LText.fromJson(Map<String, dynamic>.from(j['name'] as Map)) : d.name,
      icon: icon is String && (icon.startsWith('asset:') || icon.startsWith('https://')) ? icon : d.icon,
      startBalance: n('startBalance', d.startBalance),
      maxBalance: n('maxBalance', d.maxBalance),
      frozen: flag('frozen', d.frozen),
      taxEnabled: flag('taxEnabled', d.taxEnabled),
      taxMethod: pick('taxMethod', taxMethods, d.taxMethod),
      taxFixed: n('taxFixed', d.taxFixed),
      taxPercent: n('taxPercent', d.taxPercent),
      taxMin: n('taxMin', d.taxMin),
      taxMax: n('taxMax', d.taxMax),
      taxByCategory: byCat,
      taxDestination: pick('taxDestination', destinations, d.taxDestination),
      insufficient: pick('insufficient', insufficientModes, d.insufficient),
      rewardGameWin: n('rewardGameWin', d.rewardGameWin),
      rewardAnswered: n('rewardAnswered', d.rewardAnswered),
      rewardNobodyLost: n('rewardNobodyLost', d.rewardNobodyLost),
      rewardClapFirst: n('rewardClapFirst', d.rewardClapFirst),
      transferEnabled: flag('transferEnabled', d.transferEnabled),
      transferMin: n('transferMin', d.transferMin),
      transferMax: n('transferMax', d.transferMax),
      transferFeePercent: n('transferFeePercent', d.transferFeePercent),
      transferCooldownSec: n('transferCooldownSec', d.transferCooldownSec),
      transferMaxPerGame: n('transferMaxPerGame', d.transferMaxPerGame),
      challengeEnabled: flag('challengeEnabled', d.challengeEnabled),
      stakeMin: n('stakeMin', d.stakeMin),
      stakeMax: n('stakeMax', d.stakeMax),
      challengeFeePercent: n('challengeFeePercent', d.challengeFeePercent),
      inviteTimeoutSec: n('inviteTimeoutSec', d.inviteTimeoutSec),
    );
  }

  /// نسخة معدّلة (بتعدي على fromJson عشان الحدود تتطبق)
  EconomyConfig copyWith(Map<String, dynamic> changes) => EconomyConfig.fromJson({...toJson(), ...changes});
}

// =================================================================
// العمليات والمحافظ
// =================================================================
enum CoinKind { start, tax, reward, transfer, fee, stake, payout, refund, adjust, burn }

class CoinTx {
  final String id;
  final CoinKind kind;
  final int? from;   // اللاعب اللي اتخصم منه (null = البنك/الحصالة)
  final int? to;     // اللاعب اللي اتضافله (null = اتحرقت/الحصالة)
  final int amount;
  final String reason; // كود السبب (بيتترجم في الواجهة)
  final String note;   // تفاصيل (اسم الكارت، سبب التعديل...)
  final int at;

  const CoinTx({required this.id, required this.kind, this.from, this.to, required this.amount, required this.reason, this.note = '', required this.at});

  Map<String, dynamic> toJson() => {
        'id': id,
        'k': kind.name,
        if (from != null) 'f': from,
        if (to != null) 't': to,
        'a': amount,
        'r': reason,
        if (note.isNotEmpty) 'n': note,
        'at': at,
      };

  static CoinTx fromJson(Map j) => CoinTx(
        id: j['id'] as String,
        kind: CoinKind.values.firstWhere((k) => k.name == j['k'], orElse: () => CoinKind.adjust),
        from: (j['f'] as num?)?.toInt(),
        to: (j['t'] as num?)?.toInt(),
        amount: (j['a'] as num).toInt(),
        reason: j['r'] as String? ?? '',
        note: j['n'] as String? ?? '',
        at: (j['at'] as num?)?.toInt() ?? 0,
      );
}

class Wallet {
  int balance;
  int earned = 0;    // مكافآت + جوايز تحديات
  int spent = 0;     // رسوم + رهانات
  int taxPaid = 0;
  int received = 0;  // تحويلات جاتله
  int sent = 0;      // تحويلات بعتها
  Wallet(this.balance);

  Map<String, dynamic> toJson() => {'b': balance, 'e': earned, 's': spent, 'x': taxPaid, 'rc': received, 'sn': sent};

  static Wallet fromJson(Map j) => Wallet((j['b'] as num).toInt())
    ..earned = (j['e'] as num?)?.toInt() ?? 0
    ..spent = (j['s'] as num?)?.toInt() ?? 0
    ..taxPaid = (j['x'] as num?)?.toInt() ?? 0
    ..received = (j['rc'] as num?)?.toInt() ?? 0
    ..sent = (j['sn'] as num?)?.toInt() ?? 0;
}

/// تحدي بين لاعبين: "أول واحد ياخد كارت يخسر الرهان" (بيستخدم نظام الخسارة الموجود في اللعبة)
enum ChallengeStatus { pending, active, won, declined, cancelled, expired, refunded }

class Challenge {
  final String id;
  final int from;
  final int to;
  final int stake;
  final int createdAt;
  ChallengeStatus status;
  int? winner;

  Challenge({required this.id, required this.from, required this.to, required this.stake, required this.createdAt, this.status = ChallengeStatus.pending, this.winner});

  bool get open => status == ChallengeStatus.pending || status == ChallengeStatus.active;

  Map<String, dynamic> toJson() => {'id': id, 'f': from, 't': to, 's': stake, 'at': createdAt, 'st': status.name, if (winner != null) 'w': winner};

  static Challenge fromJson(Map j) => Challenge(
        id: j['id'] as String,
        from: (j['f'] as num).toInt(),
        to: (j['t'] as num).toInt(),
        stake: (j['s'] as num).toInt(),
        createdAt: (j['at'] as num).toInt(),
        status: ChallengeStatus.values.firstWhere((s) => s.name == j['st'], orElse: () => ChallengeStatus.cancelled),
        winner: (j['w'] as num?)?.toInt(),
      );
}

/// تغيير في رصيد لاعب (للأنيميشن: "-50 🪙" فوق اسمه)
class CoinChange {
  final int player;
  final int delta;
  const CoinChange(this.player, this.delta);
}

// =================================================================
// محرك الكوينز (عند الهوست بس)
// =================================================================
class Economy {
  static const historySize = 150;

  EconomyConfig config = const EconomyConfig();
  List<Wallet> wallets = [];
  final List<CoinTx> log = [];
  final List<Challenge> challenges = [];
  int pot = 0;                       // الحصالة (لو الضريبة بتروح للكسبان في الآخر)
  int burned = 0;                    // كوينز اتحرقت (خرجت من اللعبة)
  int created = 0;                   // كوينز اتعملت (رصيد البداية + مكافآت + تعديلات)
  final Set<String> _settled = {};   // مفاتيح العمليات اللي اتنفذت (لمنع التكرار)
  final Map<int, int> _lastTransferAt = {};
  final Map<int, int> _transferCount = {};
  int _seq = 0;

  bool get active => config.enabled && wallets.isNotEmpty;

  /// بداية لعبة جديدة: رصيد البداية لكل لاعب
  void start(int players, EconomyConfig cfg, int now) {
    config = cfg;
    wallets = [for (var i = 0; i < players; i++) Wallet(cfg.enabled ? cfg.startBalance : 0)];
    log.clear();
    challenges.clear();
    pot = 0;
    burned = 0;
    created = cfg.enabled ? cfg.startBalance * players : 0;
    _settled.clear();
    _lastTransferAt.clear();
    _transferCount.clear();
    if (cfg.enabled && cfg.startBalance > 0) {
      for (var i = 0; i < players; i++) {
        _add(CoinTx(id: 'start:$i', kind: CoinKind.start, to: i, amount: cfg.startBalance, reason: 'start', at: now));
      }
    }
  }

  /// مسح كل حاجة (اللعبة اتقفلت)
  void clear() {
    wallets = [];
    log.clear();
    challenges.clear();
    pot = 0;
    burned = 0;
    created = 0;
    _settled.clear();
    _lastTransferAt.clear();
    _transferCount.clear();
  }

  int balanceOf(int p) => p >= 0 && p < wallets.length ? wallets[p].balance : 0;

  void _add(CoinTx tx) {
    log.add(tx);
    if (log.length > historySize) log.removeRange(0, log.length - historySize);
  }

  String _id(String prefix) => '$prefix:${_seq++}';

  /// يضيف للاعب (من غير ما يعدي أقصى رصيد - الزيادة بتتحرق)
  int _credit(int player, int amount) {
    final w = wallets[player];
    final room = max(0, config.maxBalance - w.balance);
    final given = min(room, amount);
    w.balance += given;
    if (amount > given) burned += amount - given;
    return given;
  }

  // ---------------- الضريبة ----------------

  /// الضريبة المحسوبة على رصيد معيّن (قبل ما نشوف الرصيد يكفي ولا لأ)
  int taxFor(int balance, CardCategory? category) {
    if (!config.taxEnabled) return 0;
    final override = category == null ? null : config.taxByCategory[category.name];
    final percent = override ?? config.taxPercent;
    return switch (config.taxMethod) {
      'fixed' => config.taxFixed,
      'percent' => (balance * percent / 100).round(),
      _ => (balance * percent / 100).round().clamp(config.taxMin, max(config.taxMin, config.taxMax)),
    };
  }

  /// ضريبة الخسارة على الخسرانين في جولة. roundKey لازم يكون مميز للجولة،
  /// فلو اتنادت تاني بنفس المفتاح مابتعملش حاجة.
  /// amount: تمن الكارت (لو الأدمن حاطط تمن للكارت ده)، وإلا بتتحسب من إعدادات الضريبة
  List<CoinChange> settleRound(String roundKey, List<int> losers, {CardCategory? category, int? turnPlayer, String card = '', int? amount, required int now}) {
    final changes = <CoinChange>[];
    if (!active || (!config.taxEnabled && amount == null)) return changes;
    var collected = 0;
    for (final p in losers.toSet()) {
      if (p < 0 || p >= wallets.length) continue;
      final key = 'tax:$roundKey:$p';
      if (!_settled.add(key)) continue; // اتدفعت قبل كده
      final w = wallets[p];
      var tax = amount ?? taxFor(w.balance, category);
      if (tax <= 0) continue;
      if (tax > w.balance) {
        if (config.insufficient == 'skip') continue;
        tax = w.balance; // ياخد اللي معاه بس (مفيش سالب)
      }
      if (tax <= 0) continue;
      w.balance -= tax;
      w.taxPaid += tax;
      collected += tax;
      changes.add(CoinChange(p, -tax));
      _add(CoinTx(id: key, kind: CoinKind.tax, from: p, amount: tax, reason: 'tax', note: card, at: now));
    }
    if (collected == 0) return changes;
    // الضريبة رايحة فين؟
    switch (config.taxDestination) {
      case 'pot':
        pot += collected;
      case 'others':
        final others = [for (var i = 0; i < wallets.length; i++) if (!losers.contains(i)) i];
        if (others.isEmpty) {
          burned += collected;
          break;
        }
        final share = collected ~/ others.length;
        burned += collected - share * others.length; // الباقي من القسمة بيتحرق
        for (final o in others) {
          if (share == 0) break;
          final given = _credit(o, share);
          wallets[o].earned += given;
          changes.add(CoinChange(o, given));
          _add(CoinTx(id: _id('taxshare:$roundKey'), kind: CoinKind.reward, to: o, amount: given, reason: 'taxShare', at: now));
        }
      case 'turnPlayer':
        if (turnPlayer != null && turnPlayer >= 0 && turnPlayer < wallets.length && !losers.contains(turnPlayer)) {
          final given = _credit(turnPlayer, collected);
          wallets[turnPlayer].earned += given;
          changes.add(CoinChange(turnPlayer, given));
          _add(CoinTx(id: _id('taxshare:$roundKey'), kind: CoinKind.reward, to: turnPlayer, amount: given, reason: 'taxShare', at: now));
        } else {
          burned += collected;
        }
      default:
        burned += collected; // بتتحرق (خرجت من اللعبة)
    }
    return changes;
  }

  /// تصحيح: الكارت اتشال من اللاعب، فالضريبة بتاعته بترجعله (مرة واحدة)
  CoinChange? refundTaxForCard(int player, String card, int now) {
    if (!active) return null;
    for (final tx in log.reversed) {
      if (tx.kind != CoinKind.tax || tx.from != player || tx.note != card) continue;
      if (!_settled.add('refund:${tx.id}')) return null;
      final given = _credit(player, tx.amount);
      wallets[player].taxPaid = max(0, wallets[player].taxPaid - tx.amount);
      if (config.taxDestination == 'pot') {
        pot = max(0, pot - tx.amount);
      } else {
        created += given; // كانت اتحرقت أو اتوزعت، فبنعمل كوينز جديدة للرد
      }
      _add(CoinTx(id: 'refund:${tx.id}', kind: CoinKind.refund, to: player, amount: given, reason: 'taxRefund', note: card, at: now));
      return CoinChange(player, given);
    }
    return null;
  }

  // ---------------- المكافآت ----------------

  /// مكافأة (مرة واحدة لكل مفتاح)
  CoinChange? reward(String key, int player, int amount, String reason, int now) {
    if (!active || amount <= 0 || player < 0 || player >= wallets.length) return null;
    if (!_settled.add('reward:$key')) return null;
    final given = _credit(player, amount);
    if (given <= 0) return null;
    wallets[player].earned += given;
    created += given;
    _add(CoinTx(id: 'reward:$key', kind: CoinKind.reward, to: player, amount: given, reason: reason, at: now));
    return CoinChange(player, given);
  }

  /// إلغاء مكافأة اتدت (مثلاً الهوست غيّر "جاوب" لـ "ماجاوبش")
  CoinChange? revokeReward(String key, int now) {
    final tx = log.where((t) => t.id == 'reward:$key').firstOrNull;
    if (tx == null || tx.to == null || !_settled.add('revoke:$key')) return null;
    final p = tx.to!;
    final take = min(tx.amount, wallets[p].balance);
    wallets[p].balance -= take;
    wallets[p].earned = max(0, wallets[p].earned - take);
    burned += take;
    _add(CoinTx(id: 'revoke:$key', kind: CoinKind.burn, from: p, amount: take, reason: 'rewardRevoked', at: now));
    _settled.remove('reward:$key'); // ينفع ياخدها تاني لو الهوست رجع "جاوب"
    _settled.remove('revoke:$key');
    return CoinChange(p, -take);
  }

  // ---------------- التحويلات ----------------

  /// تحويل بين لاعبين. بيرجع كود الخطأ أو null لو تم (كله أو مفيش حاجة).
  String? transfer(String id, int from, int to, int amount, int now) {
    if (!active) return 'disabled';
    if (config.frozen) return 'frozen';
    if (!config.transferEnabled) return 'disabled';
    if (_settled.contains('transfer:$id')) return null; // اتنفذ قبل كده (طلب مكرر)
    if (from < 0 || to < 0 || from >= wallets.length || to >= wallets.length) return 'invalid';
    if (from == to) return 'self';
    if (amount < config.transferMin || amount > config.transferMax) return 'limits';
    final fee = (amount * config.transferFeePercent / 100).ceil();
    if (wallets[from].balance < amount + fee) return 'balance';
    final last = _lastTransferAt[from];
    if (last != null && now - last < config.transferCooldownSec * 1000) return 'cooldown';
    if ((_transferCount[from] ?? 0) >= config.transferMaxPerGame) return 'tooMany';
    // التنفيذ (كله مع بعض)
    _settled.add('transfer:$id');
    wallets[from].balance -= amount + fee;
    wallets[from].sent += amount;
    wallets[from].spent += fee;
    final given = _credit(to, amount);
    wallets[to].received += given;
    burned += fee;
    _lastTransferAt[from] = now;
    _transferCount[from] = (_transferCount[from] ?? 0) + 1;
    _add(CoinTx(id: 'transfer:$id', kind: CoinKind.transfer, from: from, to: to, amount: amount, reason: 'transfer', at: now));
    if (fee > 0) _add(CoinTx(id: 'fee:$id', kind: CoinKind.fee, from: from, amount: fee, reason: 'transferFee', at: now));
    return null;
  }

  // ---------------- التحديات ----------------

  /// دعوة تحدي (الرهان مابيتخصمش غير لما الاتنين يوافقوا)
  String? invite(String id, int from, int to, int stake, int now) {
    if (!active) return 'disabled';
    if (config.frozen) return 'frozen';
    if (!config.challengeEnabled) return 'disabled';
    if (challenges.any((c) => c.id == id)) return null;
    if (from < 0 || to < 0 || from >= wallets.length || to >= wallets.length) return 'invalid';
    if (from == to) return 'self';
    if (stake < config.stakeMin || stake > config.stakeMax) return 'limits';
    if (wallets[from].balance < stake) return 'balance';
    // تحدي واحد مفتوح بين نفس الاتنين
    if (challenges.any((c) => c.open && {c.from, c.to}.containsAll({from, to}))) return 'exists';
    challenges.add(Challenge(id: id, from: from, to: to, stake: stake, createdAt: now));
    return null;
  }

  /// الرد على الدعوة: لو وافق، الرهان بيتخصم من الاتنين ويتحط في الوسط
  String? respond(String id, bool accept, int now) {
    final c = challenges.where((c) => c.id == id).firstOrNull;
    if (c == null) return 'invalid';
    if (c.status != ChallengeStatus.pending) return null; // اتردّ عليه قبل كده
    if (!accept) {
      c.status = ChallengeStatus.declined;
      return null;
    }
    if (config.frozen) return 'frozen';
    if (now - c.createdAt > config.inviteTimeoutSec * 1000) {
      c.status = ChallengeStatus.expired;
      return 'expired';
    }
    if (wallets[c.from].balance < c.stake || wallets[c.to].balance < c.stake) return 'balance';
    for (final p in [c.from, c.to]) {
      wallets[p].balance -= c.stake;
      wallets[p].spent += c.stake;
      _add(CoinTx(id: 'stake:${c.id}:$p', kind: CoinKind.stake, from: p, amount: c.stake, reason: 'stake', at: now));
    }
    c.status = ChallengeStatus.active;
    return null;
  }

  /// صاحب التحدي يلغيه قبل ما يتقبل
  bool cancelInvite(String id, int by) {
    final c = challenges.where((c) => c.id == id).firstOrNull;
    if (c == null || c.status != ChallengeStatus.pending || c.from != by) return false;
    c.status = ChallengeStatus.cancelled;
    return true;
  }

  /// الدعوات القديمة بتنتهي
  void expireInvites(int now) {
    for (final c in challenges) {
      if (c.status == ChallengeStatus.pending && now - c.createdAt > config.inviteTimeoutSec * 1000) c.status = ChallengeStatus.expired;
    }
  }

  /// لاعب خد كارت: أي تحدي شغال هو فيه، هو اللي خسره
  List<CoinChange> onCardTaken(int player, int now) {
    final changes = <CoinChange>[];
    for (final c in challenges) {
      if (c.status != ChallengeStatus.active || (c.from != player && c.to != player)) continue;
      final winner = c.from == player ? c.to : c.from;
      final total = c.stake * 2;
      final fee = (total * config.challengeFeePercent / 100).floor();
      final given = _credit(winner, total - fee);
      wallets[winner].earned += given;
      burned += fee;
      c.status = ChallengeStatus.won;
      c.winner = winner;
      changes.add(CoinChange(winner, given));
      _add(CoinTx(id: 'payout:${c.id}', kind: CoinKind.payout, to: winner, amount: given, reason: 'challengeWon', at: now));
    }
    return changes;
  }

  /// آخر اللعبة: التحديات اللي لسه شغالة الرهان بيرجع (مفيش حد خسر)،
  /// والحصالة ومكافأة الكسبان بيتوزعوا على الكسبانين
  List<CoinChange> endGame(List<int> winners, int now) {
    final changes = <CoinChange>[];
    if (!active || !_settled.add('endGame')) return changes;
    for (final c in challenges) {
      if (c.status == ChallengeStatus.pending) c.status = ChallengeStatus.expired;
      if (c.status != ChallengeStatus.active) continue;
      for (final p in [c.from, c.to]) {
        final given = _credit(p, c.stake);
        changes.add(CoinChange(p, given));
        _add(CoinTx(id: 'refund:${c.id}:$p', kind: CoinKind.refund, to: p, amount: given, reason: 'challengeTie', at: now));
      }
      c.status = ChallengeStatus.refunded;
    }
    final valid = [for (final w in winners) if (w >= 0 && w < wallets.length) w];
    if (valid.isEmpty) return changes;
    if (pot > 0) {
      final share = pot ~/ valid.length;
      burned += pot - share * valid.length;
      for (final w in valid) {
        final given = _credit(w, share);
        wallets[w].earned += given;
        changes.add(CoinChange(w, given));
        _add(CoinTx(id: 'pot:$w', kind: CoinKind.payout, to: w, amount: given, reason: 'potWon', at: now));
      }
      pot = 0;
    }
    if (config.rewardGameWin > 0) {
      final share = config.rewardGameWin ~/ valid.length;
      for (final w in valid) {
        final c = reward('gameWin:$w', w, share, 'gameWin', now);
        if (c != null) changes.add(c);
      }
    }
    return changes;
  }

  // ---------------- تعديل يدوي (الهوست، بسبب إجباري) ----------------
  String? adjust(String id, int player, int delta, String reason, int now) {
    if (!active) return 'disabled';
    if (config.frozen) return 'frozen';
    if (reason.trim().length < 3) return 'reason';
    if (player < 0 || player >= wallets.length || delta == 0) return 'invalid';
    if (!_settled.add('adjust:$id')) return null;
    final before = wallets[player].balance;
    if (delta > 0) {
      _credit(player, delta);
      created += wallets[player].balance - before;
    } else {
      final take = min(-delta, before);
      wallets[player].balance -= take;
      burned += take;
    }
    final after = wallets[player].balance;
    _add(CoinTx(
      id: 'adjust:$id',
      kind: CoinKind.adjust,
      from: delta < 0 ? player : null,
      to: delta > 0 ? player : null,
      amount: (after - before).abs(),
      reason: 'adjust',
      note: '${reason.trim()} ($before → $after)',
      at: now,
    ));
    return null;
  }

  // ---------------- المزامنة ----------------
  Map<String, dynamic> toJson() => {
        'on': config.enabled,
        'name': config.name.toJson(),
        'icon': config.icon,
        'frozen': config.frozen,
        'tr': config.transferEnabled,
        'ch': config.challengeEnabled,
        'trMin': config.transferMin,
        'trMax': config.transferMax,
        'stMin': config.stakeMin,
        'stMax': config.stakeMax,
        'w': [for (final w in wallets) w.toJson()],
        'log': [for (final t in log.length > 60 ? log.sublist(log.length - 60) : log) t.toJson()],
        'chal': [for (final c in challenges.where((c) => c.open || challenges.indexOf(c) >= challenges.length - 10)) c.toJson()],
        'pot': pot,
        'burned': burned,
        'created': created,
      };

  /// موبايل اللاعب: بيعرض اللي الهوست بعته (مابيحسبش حاجة بنفسه)
  void applyJson(Map j) {
    config = EconomyConfig.fromJson({
      'enabled': j['on'],
      'name': j['name'],
      'icon': j['icon'],
      'frozen': j['frozen'],
      'transferEnabled': j['tr'],
      'challengeEnabled': j['ch'],
      'transferMin': j['trMin'],
      'transferMax': j['trMax'],
      'stakeMin': j['stMin'],
      'stakeMax': j['stMax'],
    });
    wallets = [for (final w in (j['w'] as List? ?? [])) Wallet.fromJson(w as Map)];
    log
      ..clear()
      ..addAll([for (final t in (j['log'] as List? ?? [])) CoinTx.fromJson(t as Map)]);
    challenges
      ..clear()
      ..addAll([for (final c in (j['chal'] as List? ?? [])) Challenge.fromJson(c as Map)]);
    pot = (j['pot'] as num?)?.toInt() ?? 0;
    burned = (j['burned'] as num?)?.toInt() ?? 0;
    created = (j['created'] as num?)?.toInt() ?? 0;
  }
}
