// =================================================================
// لوحات شاشة اللعب: ساعة كل لاعب، الترتيب لايف، ولوحة الأدوار
// -----------------------------------------------------------------
// - StopwatchText: ساعة بتعد لفوق من 00:00 (بتتحسب من الأوقات المسجلة،
//   فلو المتصفح اتأخر في الرسم الرقم بيفضل صح). بتعيد رسم نفسها بس.
// - LiveRankingStrip: شريط صغير فوق الترابيزة على الموبايل.
// - LiveRankingPanel: لوحة على جنب الشاشة في الشاشات العريضة.
// - showTurnsSheet: الأدوار والأوقات + تحكم الهوست (إيقاف/تكملة/إنهاء/جاوب/ماجاوبش).
// =================================================================
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import 'common.dart';
import 'wallet_panel.dart';

// =================================================================
// ساعة الإيقاف
// =================================================================
class StopwatchText extends StatefulWidget {
  final TurnRecord turn;
  final int Function() now; // الوقت بساعة الهوست
  final TextStyle style;
  const StopwatchText({super.key, required this.turn, required this.now, required this.style});

  @override
  State<StopwatchText> createState() => _StopwatchTextState();
}

class _StopwatchTextState extends State<StopwatchText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StopwatchText old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// الساعة بتتحدث بس وهي شغالة (لو واقفة أو الدور خلص مفيش أي تحديث)
  void _sync() {
    final running = widget.turn.isActive && !widget.turn.isPaused;
    if (running && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClock(widget.turn.elapsedMs(widget.now())),
      textDirection: TextDirection.ltr,
      style: widget.style,
    );
  }
}

// =================================================================
// الترتيب لايف
// =================================================================
String _medal(int rank) => switch (rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => '$rank.' };

/// شريط صغير (للموبايل): كل اللاعيبة بالترتيب في سطر واحد
class LiveRankingStrip extends StatelessWidget {
  final GameController game;
  final VoidCallback onTap;
  const LiveRankingStrip({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ranking = game.ranking;
    if (ranking.isEmpty) return const SizedBox.shrink();
    // المفتاح بيتغير لما الترتيب يتغير → حركة خفيفة
    final signature = ranking.map((e) => '${e.player}:${e.cards}').join(',');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
        child: Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 14, color: AppColors.ink)),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(signature),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in ranking) ...[
                        _StripEntry(game: game, entry: e),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Icon(Icons.unfold_more, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _StripEntry extends StatelessWidget {
  final GameController game;
  final RankEntry entry;
  const _StripEntry({required this.game, required this.entry});

  @override
  Widget build(BuildContext context) {
    final player = game.players[entry.player];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_medal(entry.rank), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(width: 3),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: player.color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(
          player.name,
          style: TextStyle(fontSize: 12, fontWeight: entry.rank == 1 ? FontWeight.w900 : FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(width: 3),
        // عدد الكروت في مربع صغير لوحده (عشان مايتلزقش في الاسم)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border.all(color: AppColors.ink, width: 1.2), borderRadius: BorderRadius.circular(3)),
          child: Text('${entry.cards}', textDirection: TextDirection.ltr, style: rankStyle(size: 11)),
        ),
      ],
    );
  }
}

/// لوحة الترتيب الكاملة (على جنب الشاشة في الشاشات العريضة، أو في نافذة على الموبايل)
class LiveRankingPanel extends StatelessWidget {
  final GameController game;
  const LiveRankingPanel({super.key, required this.game});

  static const rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final ranking = game.ranking;
    return RetroWindow(
      title: '🏆 ${game.t(UiText.liveRanking)}',
      barColor: AppColors.yellow,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(game.t(UiText.rankingHint), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 8),
          // كل صف بيتحرك لمكانه الجديد بنعومة لما الترتيب يتغير
          SizedBox(
            height: ranking.length * rowHeight,
            child: Stack(
              children: [
                for (var i = 0; i < ranking.length; i++)
                  AnimatedPositioned(
                    key: ValueKey('rank-${ranking[i].player}'),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    top: i * rowHeight,
                    left: 0,
                    right: 0,
                    height: rowHeight - 6,
                    child: _PanelRow(game: game, entry: ranking[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  final GameController game;
  final RankEntry entry;
  const _PanelRow({required this.game, required this.entry});

  @override
  Widget build(BuildContext context) {
    final player = game.players[entry.player];
    final first = entry.rank == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: Brutal.box(
        color: first ? AppColors.yellow : AppColors.paper,
        borderWidth: first ? 2.4 : 1.6,
        shadowOffset: first ? const Offset(3, 3) : Offset.zero,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(_medal(entry.rank), textAlign: TextAlign.center, style: TextStyle(fontSize: entry.rank <= 3 ? 18 : 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsetsDirectional.only(end: 6),
            decoration: BoxDecoration(color: player.color, shape: BoxShape.circle, border: Border.all(color: AppColors.ink, width: 1.4)),
          ),
          Expanded(
            child: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          Text(
            game.t(fillText(UiText.cardsShort, {'n': entry.cards})),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          // الكوينز (منفصلة عن ترتيب الكروت)
          if (game.coinsOn) ...[
            const SizedBox(width: 8),
            CoinAmount(game: game, amount: game.economy.balanceOf(entry.player), size: 11),
          ],
        ],
      ),
    );
  }
}

/// نافذة الترتيب (من الشريط الصغير على الموبايل)
void showRankingSheet(BuildContext context, GameController game) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (context) => ListenableBuilder(
      listenable: game,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LiveRankingPanel(game: game),
        ),
      ),
    ),
  );
}

// =================================================================
// الأدوار والأوقات
// =================================================================
String turnStatusLabel(GameController game, TurnRecord turn) {
  if (turn.isPaused) return game.t(UiText.turnPaused);
  return game.t(switch (turn.status) {
    TurnStatus.active => UiText.turnActive,
    TurnStatus.answered => UiText.turnAnswered,
    TurnStatus.noAnswer => UiText.turnNoAnswer,
    TurnStatus.finished => UiText.turnFinished,
    TurnStatus.skipped => UiText.turnSkipped,
  });
}

Color turnStatusColor(TurnRecord turn) {
  if (turn.isPaused) return AppColors.blue;
  return switch (turn.status) {
    TurnStatus.active => AppColors.yellow,
    TurnStatus.answered => AppColors.green,
    TurnStatus.noAnswer => AppColors.red,
    TurnStatus.finished => AppColors.paper,
    TurnStatus.skipped => AppColors.orange,
  };
}

void showTurnsSheet(BuildContext context, GameController game) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.ink, width: Brutal.border)),
    builder: (context) => ListenableBuilder(
      listenable: game,
      builder: (context, _) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: _TurnsView(game: game),
      ),
    ),
  );
}

class _TurnsView extends StatelessWidget {
  final GameController game;
  const _TurnsView({required this.game});

  @override
  Widget build(BuildContext context) {
    final active = game.activeTurn;
    final last = game.lastTurn;
    final small = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted);
    final clockStyle = rankStyle(size: 22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WindowBar(title: '⏱ ${game.t(UiText.turns)}', color: AppColors.blue),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            children: [
              Text(game.t(UiText.turnsHint), style: small),
              const SizedBox(height: 10),
              // الدور الشغال + تحكم الهوست
              if (active != null && active.player < game.players.length)
                BrutalBox(
                  color: AppColors.yellow,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.t(fillText(UiText.turnOf, {'name': game.players[active.player].name})),
                              style: pixelStyle(size: 16),
                            ),
                          ),
                          StopwatchText(turn: active, now: () => game.nowMs, style: clockStyle),
                        ],
                      ),
                      Text(turnStatusLabel(game, active), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      if (game.isHost) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _action(active.isPaused ? '▶ ${game.t(UiText.resume)}' : '⏸ ${game.t(UiText.pause)}', AppColors.paper, game.toggleTurnPause),
                            _action('⏹ ${game.t(UiText.endTurn)}', AppColors.paper, game.endTurnNow),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              // جاوب / ماجاوبش (على الدور الشغال أو آخر دور خلص)
              if (game.isHost && last != null && last.status != TurnStatus.skipped && last.player < game.players.length) ...[
                const SizedBox(height: 10),
                Text(game.t(fillText(UiText.turnOf, {'name': game.players[last.player].name})), style: small),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _action(game.t(UiText.markAnswered), last.status == TurnStatus.answered ? AppColors.green : AppColors.paper,
                        () => game.markTurn(TurnStatus.answered)),
                    _action(game.t(UiText.markNoAnswer), last.status == TurnStatus.noAnswer ? AppColors.red : AppColors.paper,
                        () => game.markTurn(TurnStatus.noAnswer)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // الوقت الكلي لكل لاعب
              Text(game.t(UiText.totalTime), style: pixelStyle(size: 15)),
              const SizedBox(height: 6),
              for (var i = 0; i < game.players.length; i++) _playerRow(i, active),
              const SizedBox(height: 16),
              // كل الأدوار اللي خلصت (الأحدث فوق)
              Text(game.t(UiText.history), style: pixelStyle(size: 15)),
              const SizedBox(height: 6),
              if (game.turns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(game.t(UiText.noTurns), textAlign: TextAlign.center, style: small),
                )
              else
                for (final turn in game.turns.reversed.take(60))
                  if (turn.player < game.players.length) _turnRow(turn),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action(String label, Color color, VoidCallback onTap) {
    return SquareButton(color: color, onTap: onTap, child: Text(label));
  }

  Widget _playerRow(int i, TurnRecord? active) {
    final player = game.players[i];
    final isActive = active != null && active.player == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: Brutal.box(color: isActive ? AppColors.yellow : AppColors.paper, borderWidth: 1.6, shadowOffset: Offset.zero),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: player.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(player.name, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
            Text(
              isActive ? game.t(UiText.turnActive) : game.t(UiText.turnWaiting),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(width: 10),
            // الوقت الكلي (بيتحدث لوحده لو دوره شغال)
            isActive
                ? _LiveTotal(game: game, player: i)
                : Text(formatClock(game.playerTotalMs(i)), textDirection: TextDirection.ltr, style: rankStyle(size: 15)),
          ],
        ),
      ),
    );
  }

  Widget _turnRow(TurnRecord turn) {
    final player = game.players[turn.player];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Brutal.box(borderWidth: 1.4, shadowOffset: Offset.zero),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: player.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${player.name}${turn.card == null ? '' : '  •  ${turn.card}'}',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: Brutal.box(color: turnStatusColor(turn), borderWidth: 1.4, shadowOffset: Offset.zero),
            child: Text(turnStatusLabel(game, turn), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          const SizedBox(width: 8),
          turn.isActive
              ? StopwatchText(turn: turn, now: () => game.nowMs, style: rankStyle(size: 14))
              : Text(formatClock(turn.elapsedMs(game.nowMs)), textDirection: TextDirection.ltr, style: rankStyle(size: 14)),
        ],
      ),
    );
  }
}

/// الوقت الكلي للاعب اللي دوره شغال (بيتحدث كل نص ثانية)
class _LiveTotal extends StatefulWidget {
  final GameController game;
  final int player;
  const _LiveTotal({required this.game, required this.player});

  @override
  State<_LiveTotal> createState() => _LiveTotalState();
}

class _LiveTotalState extends State<_LiveTotal> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatClock(widget.game.playerTotalMs(widget.player)), textDirection: TextDirection.ltr, style: rankStyle(size: 15));
  }
}
