// =================================================================
// المحفظة: الأرصدة + العمليات + التحويل + التحديات + تعديل الهوست
// -----------------------------------------------------------------
// - الهوست هو اللي بيحسب كل حاجة. موبايل اللاعب بيبعت "طلب" ويستنى الرد
//   (وبيقدر يحوّل أو يتحدى باسم اللاعب اللي ماسكه بس).
// - على موبايل واحد: الهوست بيختار مين اللي بيبعت.
// - الكوينز مالهاش قيمة حقيقية، وبتتمسح أول ما اللعبة تتقفل.
// =================================================================
import 'package:flutter/material.dart';

import '../data/coin_texts.dart';
import '../data/texts.dart';
import '../game/economy.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import 'card_face.dart';
import 'common.dart';

/// أيقونة العملة (من مكتبة الصور، والأدمن بيختارها)
class CoinIcon extends StatelessWidget {
  final GameController game;
  final double size;
  const CoinIcon({super.key, required this.game, this.size = 14});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: imageFromRef(game.economy.config.icon, fit: BoxFit.contain, width: size, height: size));
}

/// رقم كوينز بأيقونتها
class CoinAmount extends StatelessWidget {
  final GameController game;
  final int amount;
  final double size;
  final Color? color;
  final bool signed;
  const CoinAmount({super.key, required this.game, required this.amount, this.size = 13, this.color, this.signed = false});

  @override
  Widget build(BuildContext context) {
    final text = signed && amount > 0 ? '+$amount' : '$amount';
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        CoinIcon(game: game, size: size + 2),
        const SizedBox(width: 3),
        Text(text, textDirection: TextDirection.ltr, style: rankStyle(size: size, color: color)),
      ],
    );
  }
}

Future<void> showWalletSheet(BuildContext context, GameController game) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.ink, width: Brutal.border)),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(height: MediaQuery.of(context).size.height * 0.8, child: WalletPanel(game: game)),
    ),
  );
}

class WalletPanel extends StatefulWidget {
  final GameController game;
  const WalletPanel({super.key, required this.game});

  @override
  State<WalletPanel> createState() => _WalletPanelState();
}

class _WalletPanelState extends State<WalletPanel> {
  GameController get game => widget.game;
  int _tab = 0;
  bool _onlyMine = false;

  // التحويل والتحدي
  int? _from;
  int? _to;
  final _amount = TextEditingController();
  final _stake = TextEditingController();
  bool _busy = false;

  // تعديل الهوست
  int _adjustPlayer = 0;
  final _adjustAmount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _stake.dispose();
    _adjustAmount.dispose();
    _reason.dispose();
    super.dispose();
  }

  /// اللاعب اللي بيدفع: موبايل اللاعب = اللاعب اللي ماسكه، الهوست = يختار
  int? get _payer => game.isViewer ? game.myPlayerIndex : (_from ?? game.currentIndex);

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  Future<void> _result(Future<String?> action) async {
    setState(() => _busy = true);
    final error = await action;
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return _snack(game.t(CoinText.error(error)), error: true);
    _snack(game.t(CoinText.done));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final eco = game.economy;
        final tabs = [
          game.t(CoinText.balances),
          game.t(CoinText.history),
          if (eco.config.transferEnabled) game.t(CoinText.transfer),
          if (eco.config.challengeEnabled) game.t(CoinText.challenges),
          if (game.isHost) game.t(CoinText.adjust),
        ];
        if (_tab >= tabs.length) _tab = 0;
        final title = '${game.t(CoinText.wallet)} • ${game.t(eco.config.name)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WindowBar(title: title, color: AppColors.yellow),
            if (!game.coinsOn)
              Expanded(child: Center(child: Text(game.t(CoinText.off), style: TextStyle(color: AppColors.muted))))
            else ...[
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: Brutal.box(
                              color: _tab == i ? AppColors.yellow : AppColors.paper,
                              borderWidth: 1.8,
                              shadowOffset: _tab == i ? const Offset(2, 2) : Offset.zero,
                            ),
                            child: Text(tabs[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (eco.config.frozen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(game.t(CoinText.frozen), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.blue)),
                ),
              Expanded(
                child: switch (tabs[_tab]) {
                  final t when t == game.t(CoinText.balances) => _balances(),
                  final t when t == game.t(CoinText.history) => _history(),
                  final t when t == game.t(CoinText.transfer) => _transfer(),
                  final t when t == game.t(CoinText.challenges) => _challenges(),
                  _ => _adjust(),
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------------- الأرصدة (وترتيب الكوينز) ----------------
  Widget _balances() {
    final eco = game.economy;
    final order = List.generate(eco.wallets.length, (i) => i)..sort((a, b) => eco.balanceOf(b).compareTo(eco.balanceOf(a)));
    final small = TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(game.t(CoinText.notice), style: small),
        const SizedBox(height: 10),
        Text('🏆 ${game.t(CoinText.coinRanking)}', style: pixelStyle(size: 14)),
        const SizedBox(height: 6),
        for (var k = 0; k < order.length; k++)
          if (order[k] < game.players.length) _walletRow(k + 1, order[k]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (eco.config.taxDestination == 'pot') Text('${game.t(CoinText.pot)}: ${eco.pot}', style: small),
            Text('${game.t(CoinText.created)}: ${eco.created}', style: small),
            Text('${game.t(CoinText.burned)}: ${eco.burned}', style: small),
          ],
        ),
      ],
    );
  }

  Widget _walletRow(int place, int p) {
    final w = game.economy.wallets[p];
    final mine = game.isViewer && game.myPlayerIndex == p;
    final small = TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Brutal.box(color: mine || place == 1 ? AppColors.yellow : AppColors.paper, borderWidth: 1.6, shadowOffset: Offset.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 28, child: Text(place <= 3 ? ['🥇', '🥈', '🥉'][place - 1] : '$place.', style: const TextStyle(fontSize: 16))),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: game.players[p].color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(game.players[p].name, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              CoinAmount(game: game, amount: w.balance, size: 15),
            ],
          ),
          Text(
            '${game.t(CoinText.earned)} ${w.earned} • ${game.t(CoinText.taxPaid)} ${w.taxPaid} • '
            '${game.t(CoinText.received)} ${w.received} • ${game.t(CoinText.sent)} ${w.sent} • ${game.t(CoinText.spent)} ${w.spent}',
            style: small,
          ),
        ],
      ),
    );
  }

  // ---------------- العمليات ----------------
  Widget _history() {
    final mine = game.isViewer ? game.myPlayerIndex : null;
    final list = game.economy.log.reversed.where((t) => !_onlyMine || mine == null || t.from == mine || t.to == mine).toList();
    String name(int? p) => p != null && p < game.players.length ? game.players[p].name : '';
    return Column(
      children: [
        if (mine != null)
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              value: _onlyMine,
              onChanged: (v) => setState(() => _onlyMine = v ?? false),
              title: Text(game.t(CoinText.mine), style: const TextStyle(fontWeight: FontWeight.w800)),
              dense: true,
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(game.t(CoinText.noTx), style: TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final tx = list[i];
                    // مثال: "ضريبة خسارة: سارة -50" أو "تحويل: سارة → عمر 25"
                    final who = switch (tx.kind) {
                      CoinKind.transfer => '${name(tx.from)} → ${name(tx.to)}',
                      _ => name(tx.from ?? tx.to),
                    };
                    final negative = tx.from != null && tx.to == null;
                    final delta = tx.kind == CoinKind.transfer ? tx.amount : (negative ? -tx.amount : tx.amount);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: Brutal.box(borderWidth: 1.2, shadowOffset: Offset.zero),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${game.t(CoinText.txReason(tx.reason))}: $who',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                if (tx.note.isNotEmpty) Text(tx.note, style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          CoinAmount(
                            game: game,
                            amount: delta,
                            signed: true,
                            color: tx.kind == CoinKind.transfer ? null : (delta < 0 ? AppColors.red : AppColors.green),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// اختيار لاعب (زراير بأساميهم)
  Widget _playerPicker(int? value, void Function(int) onPick, {int? exclude}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < game.players.length; i++)
          if (i != exclude)
            GestureDetector(
              onTap: () => setState(() => onPick(i)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: Brutal.box(
                  color: value == i ? AppColors.yellow : AppColors.paper,
                  borderWidth: 1.8,
                  shadowOffset: value == i ? const Offset(2, 2) : Offset.zero,
                ),
                child: Text(game.players[i].name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
            ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Brutal.radius)),
      ),
    );
  }

  Widget _payerSection() {
    final payer = _payer;
    if (game.isViewer) {
      if (payer == null) return Text(game.t(CoinText.pickSeatFirst), style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800));
      return Row(
        children: [
          Text('${game.t(CoinText.from)}: ${game.players[payer].name}  ', style: const TextStyle(fontWeight: FontWeight.w900)),
          CoinAmount(game: game, amount: game.economy.balanceOf(payer)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(game.t(CoinText.from), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        _playerPicker(payer, (i) {
          _from = i;
          if (_to == i) _to = null;
        }),
      ],
    );
  }

  // ---------------- التحويل ----------------
  Widget _transfer() {
    final cfg = game.economy.config;
    final payer = _payer;
    final amount = int.tryParse(_amount.text.trim());
    final fee = amount == null ? 0 : (amount * cfg.transferFeePercent / 100).ceil();
    final ready = payer != null && _to != null && amount != null && !_busy;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _payerSection(),
        const SizedBox(height: 10),
        Text(game.t(CoinText.to), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        _playerPicker(_to, (i) => _to = i, exclude: payer),
        const SizedBox(height: 10),
        _numberField(_amount, '${game.t(CoinText.amount)} (${game.t(fillText(CoinText.limits, {'min': cfg.transferMin, 'max': cfg.transferMax}))})'),
        if (fee > 0) Text('${game.t(CoinText.fee)}: $fee', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 12),
        // معاينة قبل التأكيد
        if (ready)
          Text(
            game.t(fillText(CoinText.confirmTransfer, {'from': game.players[payer].name, 'to': game.players[_to!].name, 'amount': amount})),
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
        const SizedBox(height: 8),
        BrutalButton(
          label: game.t(CoinText.send),
          color: ready ? AppColors.yellow : AppColors.paper,
          onTap: ready
              ? () async {
                  await _result(game.transferCoins(payer, _to!, amount));
                  _amount.clear();
                }
              : () {},
        ),
      ],
    );
  }

  // ---------------- التحديات ----------------
  Widget _challenges() {
    final eco = game.economy;
    final payer = _payer;
    final stake = int.tryParse(_stake.text.trim());
    final ready = payer != null && _to != null && stake != null && !_busy;
    final me = game.isViewer ? game.myPlayerIndex : null;
    String name(int p) => p < game.players.length ? game.players[p].name : '?';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(game.t(CoinText.challengeRule), style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _payerSection(),
        const SizedBox(height: 10),
        Text(game.t(CoinText.opponent), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        _playerPicker(_to, (i) => _to = i, exclude: payer),
        const SizedBox(height: 10),
        _numberField(_stake, '${game.t(CoinText.stake)} (${game.t(fillText(CoinText.limits, {'min': eco.config.stakeMin, 'max': eco.config.stakeMax}))})'),
        const SizedBox(height: 10),
        BrutalButton(
          label: game.t(CoinText.sendChallenge),
          color: ready ? AppColors.orange : AppColors.paper,
          onTap: ready ? () => _result(game.inviteChallenge(payer, _to!, stake)) : () {},
        ),
        const SizedBox(height: 16),
        if (eco.challenges.isEmpty) Center(child: Text(game.t(CoinText.noChallenges), style: TextStyle(color: AppColors.muted))),
        for (final c in eco.challenges.reversed)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: Brutal.box(color: c.open ? AppColors.paper : AppColors.bg, borderWidth: 1.6, shadowOffset: Offset.zero),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('⚔ ${name(c.from)} × ${name(c.to)}', style: const TextStyle(fontWeight: FontWeight.w900))),
                    CoinAmount(game: game, amount: c.stake),
                  ],
                ),
                Text(
                  game.t(switch (c.status) {
                    ChallengeStatus.pending => CoinText.statusPending,
                    ChallengeStatus.active => CoinText.statusActive,
                    ChallengeStatus.won => fillText(CoinText.statusWon, {'name': name(c.winner ?? 0)}),
                    ChallengeStatus.declined => CoinText.statusDeclined,
                    ChallengeStatus.cancelled => CoinText.statusCancelled,
                    ChallengeStatus.expired => CoinText.statusExpired,
                    ChallengeStatus.refunded => CoinText.statusRefunded,
                  }),
                  style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
                if (c.status == ChallengeStatus.pending)
                  Wrap(
                    spacing: 6,
                    children: [
                      // اللي اتبعتله الدعوة يرد (الهوست يرد عن أي حد على موبايل واحد)
                      if (game.isHost || me == c.to) ...[
                        TextButton(onPressed: _busy ? null : () => _result(game.replyChallenge(c.id, true)), child: Text(game.t(CoinText.accept))),
                        TextButton(onPressed: _busy ? null : () => _result(game.replyChallenge(c.id, false)), child: Text(game.t(CoinText.decline))),
                      ],
                      if (game.isHost || me == c.from)
                        TextButton(onPressed: _busy ? null : () => _result(game.cancelChallenge(c.id)), child: Text(game.t(CoinText.cancel))),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------- تعديل الهوست (بسبب إجباري) ----------------
  Widget _adjust() {
    final amount = int.tryParse(_adjustAmount.text.trim());
    final ready = amount != null && amount > 0 && _reason.text.trim().length >= 3;
    void run(int sign) {
      final error = game.adjustCoins(_adjustPlayer, sign * amount!, _reason.text);
      if (error != null) return _snack(game.t(CoinText.error(error)), error: true);
      _snack(game.t(CoinText.done));
      _adjustAmount.clear();
      _reason.clear();
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(game.t(CoinText.player), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        _playerPicker(_adjustPlayer, (i) => _adjustPlayer = i),
        const SizedBox(height: 10),
        _numberField(_adjustAmount, game.t(CoinText.amount)),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          maxLength: 80,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: game.t(CoinText.reason),
            isDense: true,
            filled: true,
            fillColor: AppColors.paper,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Brutal.radius)),
          ),
        ),
        Row(
          children: [
            Expanded(child: BrutalButton(label: '+ ${game.t(CoinText.add)}', color: ready ? AppColors.green : AppColors.paper, showArrow: false, onTap: ready ? () => run(1) : () {})),
            const SizedBox(width: 10),
            Expanded(child: BrutalButton(label: '− ${game.t(CoinText.subtract)}', color: ready ? AppColors.red : AppColors.paper, showArrow: false, onTap: ready ? () => run(-1) : () {})),
          ],
        ),
      ],
    );
  }
}
