// =================================================================
// شاشة اللعب
// -----------------------------------------------------------------
// الكارت في النص وواخد أكبر مساحة، واللاعيبة قاعدين حواليه على أطراف الشاشة
// بنفس ترتيب الأدوار مع عقارب الساعة.
// =================================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/big_card.dart';
import '../widgets/common.dart';
import '../widgets/player_seat.dart';
import '../widgets/qr_dialog.dart';

class GameScreen extends StatelessWidget {
  final GameController game;
  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            // على الشاشات العريضة (كمبيوتر/تابلت) نخلي اللعبة بعرض مناسب في النص
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  children: [
                    _TopBar(game: game),
                    // المتفرج اللي لسه مستني صاحب القعدة يبدأ
                    if (game.isViewer && !game.viewerHasState)
                      Expanded(child: _WaitingForHost(game: game))
                    else ...[
                      if (game.isViewer) _viewerBanner(),
                      _StatusChips(game: game),
                      const SizedBox(height: 4),
                      Expanded(child: _Table(game: game)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// شريط صغير بيفكّر المتفرج إنه بيتفرج بس
  Widget _viewerBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: AppColors.ink,
      child: Text(
        game.t(UiText.viewerHint),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.yellow),
      ),
    );
  }
}

// =================================================================
// شاشة انتظار المتفرج: لسه متصلش أو صاحب القعدة لسه في الإعداد
// =================================================================
class _WaitingForHost extends StatelessWidget {
  final GameController game;
  const _WaitingForHost({required this.game});

  @override
  Widget build(BuildContext context) {
    final connected = game.room?.connected ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.all(10),
              decoration: Brutal.box(shadowOffset: const Offset(6, 6)),
              child: Image.asset('assets/images/logo.png'),
            ),
            const SizedBox(height: 28),
            Text(game.t(UiText.roomCode).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: Brutal.box(color: AppColors.yellow),
              child: Text(game.roomCode ?? '',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 6)),
            ),
            const SizedBox(height: 24),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 3)),
            const SizedBox(height: 14),
            Headline(game.t(connected ? UiText.waitingHost : UiText.connecting), size: 22, align: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// الشريط العلوي: السجل (أقصى الشمال) + الصوت + اللغة ... QR + إنهاء
// =================================================================
class _TopBar extends StatelessWidget {
  final GameController game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final online = game.room != null; // هوست أو متفرج
    return Row(
      textDirection: TextDirection.ltr, // ترتيب ثابت: السجل دايماً على الشمال
      children: [
        SquareButton(
          onTap: () => _showHistory(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history),
              // لو فيه أزرار زيادة (QR) نخلي السجل أيقونة بس عشان المساحة
              if (!online) ...[const SizedBox(width: 4), Text(game.t(UiText.history).toUpperCase())],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SquareButton(
          onTap: game.toggleSound,
          child: Icon(game.sound.enabled ? Icons.volume_up : Icons.volume_off),
        ),
        const SizedBox(width: 8),
        LangToggle(game: game),
        const Spacer(),
        // الهوست: زرار الـ QR فيه كود القعدة
        if (online && !game.isViewer) ...[
          SquareButton(
            color: AppColors.yellow,
            onTap: () => showQrDialog(context, game),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [const Icon(Icons.qr_code_2), const SizedBox(width: 4), Text(game.roomCode ?? '')],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // المتفرج: زرار خروج / الهوست: زرار إنهاء اللعبة
        SquareButton(
          onTap: game.isViewer ? game.goHome : () => _confirmEnd(context),
          child: Icon(game.isViewer ? Icons.logout : Icons.close),
        ),
      ],
    );
  }

  /// نافذة السجل من تحت
  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.ink, width: Brutal.border),
      ),
      builder: (context) => ListenableBuilder(
        listenable: game,
        builder: (context, _) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ShapesStrip(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Headline(game.t(UiText.history), size: 28),
              ),
              Expanded(
                child: game.log.isEmpty
                    ? Center(child: Text(game.t(UiText.noHistory), style: const TextStyle(color: AppColors.muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: game.log.length,
                        separatorBuilder: (_, _) => const Divider(color: AppColors.line, height: 1),
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            game.t(game.log[i]),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: i == 0 ? FontWeight.w900 : FontWeight.w600,
                              color: i == 0 ? AppColors.ink : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تأكيد إنهاء اللعبة
  Future<void> _confirmEnd(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BrutalBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline(game.t(UiText.confirmEnd), size: 24),
              const SizedBox(height: 20),
              BrutalButton(label: game.t(UiText.yes), onTap: () => Navigator.pop(context, true), color: AppColors.red),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  game.t(UiText.no).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) game.finishGame();
  }
}

// =================================================================
// شارات الحالة: الكادو المستني + اللاعب الصامت
// =================================================================
class _StatusChips extends StatelessWidget {
  final GameController game;
  const _StatusChips({required this.game});

  @override
  Widget build(BuildContext context) {
    final silentName = game.silentIndex >= 0 ? game.players[game.silentIndex].name : '';
    final chips = <Widget>[
      if (game.caduActive)
        _chip(game.t(fillText(UiText.caduChip, {'n': game.caduCards.length})), AppColors.yellow),
      // الصامت: لو معاه كارت Q، الشارة بتبقى زرار ننقل بيه الكارت للي كلّمه
      if (game.silentIndex >= 0)
        game.canPassSilence
            ? Pulse(
                scale: 1.04,
                duration: const Duration(milliseconds: 900),
                child: GestureDetector(
                  onTap: () => _askWhoTalked(context, silentName),
                  child: _chip(game.t(fillText(UiText.silentChipTap, {'name': silentName})), AppColors.paper),
                ),
              )
            : _chip(game.t(fillText(UiText.silentChip, {'name': silentName})), AppColors.paper),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: chips),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: Brutal.box(color: color, borderWidth: 2, shadowOffset: const Offset(2, 2)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
    );
  }

  /// "مين كلّم الصامت؟" → اللي يتختار ياخد الـ Q ويبقى هو الصامت
  Future<void> _askWhoTalked(BuildContext context, String silentName) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BrutalBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline('🤐 ${game.t(fillText(UiText.whoTalked, {'name': silentName}))}', size: 24),
              const SizedBox(height: 4),
              Text(game.t(UiText.whoTalkedHint), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              // زرار لكل لاعب ماعدا الصامت نفسه
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < game.players.length; i++)
                    if (i != game.silentIndex)
                      GestureDetector(
                        onTap: () => Navigator.pop(context, i),
                        child: Container(
                          width: 120,
                          height: 46,
                          decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  color: game.players[i].color,
                                  border: const BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  game.players[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  game.t(UiText.cancel).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) game.passSilence(picked);
  }
}

// =================================================================
// الترابيزة: الكارت في النص واللاعيبة حواليه
// -----------------------------------------------------------------
// - على الموبايل: اللاعيبة في قوسين فوق وتحت الكارت (زي ما يكونوا قاعدين
//   حوالين ترابيزة)، والكارت ياخد عرض الشاشة كله.
// - على الشاشات العريضة (تابلت/كمبيوتر): لو فيه مساحة على الجناب
//   بنقعد لاعيبة يمين وشمال كمان.
// الترتيب دايماً مع عقارب الساعة: تحت (يمين ← شمال) ← شمال ← فوق ← يمين
// =================================================================
class _Table extends StatelessWidget {
  final GameController game;
  const _Table({required this.game});

  // توزيع اللاعيبة لما الجناب متاحة: [تحت، شمال، فوق، يمين]
  static const Map<int, List<int>> _sideLayouts = {
    3: [1, 0, 2, 0],
    4: [1, 1, 1, 1],
    5: [1, 1, 2, 1],
    6: [2, 1, 2, 1],
    7: [2, 1, 3, 1],
    8: [2, 2, 2, 2],
  };

  static const double _sideColumnWidth = 78; // عرض عمود المقاعد الجانبية
  static const double _arcHeight = 16;      // مقدار انحناء القوس

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = game.players.length;

        // توزيع الموبايل: فوق وتحت بس (أقصى 4 في الصف)
        final bottomCount = n ~/ 2;
        final topCount = n - bottomCount;
        final rowsAreTall = topCount >= 3; // 3 مقاعد أو أكتر في الصف → مقاعد رأسية
        final rowHeight = (rowsAreTall ? 100.0 : 60.0) + _arcHeight;

        // نحسب عرض الكارت لو استخدمنا فوق وتحت بس، ونشوف هل فاضل مساحة على الجناب
        final cardHeight = constraints.maxHeight - rowHeight * 2;
        final cardWidth = min(constraints.maxWidth, cardHeight * 5 / 7);
        final sideSpace = (constraints.maxWidth - cardWidth) / 2;
        final useSides = sideSpace >= _sideColumnWidth + 8 && n >= 4;

        final layout = useSides ? _sideLayouts[n]! : [bottomCount, 0, topCount, 0];

        // تقسيم أرقام اللاعيبة على الأربع جهات بالترتيب
        var next = 0;
        List<int> take(int count) {
          final result = [for (var i = 0; i < count; i++) next + i];
          next += count;
          return result;
        }

        final bottom = take(layout[0]);
        final left = take(layout[1]);
        final top = take(layout[2]);
        final right = take(layout[3]);

        return Column(
          children: [
            // فوق: من الشمال لليمين، والقوس نازل ناحية الكارت على الأطراف
            _row(top, TextDirection.ltr, isTop: true),
            Expanded(
              child: Row(
                textDirection: TextDirection.ltr, // عشان الشمال يفضل شمال حتى في العربي
                children: [
                  // الشمال: من تحت لفوق
                  if (left.isNotEmpty) _column(left, VerticalDirection.up),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: BigCard(game: game),
                    ),
                  ),
                  // اليمين: من فوق لتحت
                  if (right.isNotEmpty) _column(right, VerticalDirection.down),
                ],
              ),
            ),
            // تحت: من اليمين للشمال (أول لاعب تحت على اليمين)
            _row(bottom, TextDirection.rtl, isTop: false),
          ],
        );
      },
    );
  }

  Widget _seat(int index, {required bool vertical}) {
    final Player player = game.players[index];
    return PlayerSeat(
      player: player,
      isCurrent: index == game.currentIndex,
      isSilent: index == game.silentIndex,
      clickable: game.canPickLoser,
      vertical: vertical,
      turnLabel: game.t(UiText.yourTurn),
      onTap: () => game.pickLoser(index),
    );
  }

  /// صف مقاعد على شكل قوس: المقاعد اللي على الأطراف أقرب للكارت
  Widget _row(List<int> indexes, TextDirection direction, {required bool isTop}) {
    if (indexes.isEmpty) return const SizedBox.shrink();
    final count = indexes.length;
    final vertical = count >= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        textDirection: direction,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var k = 0; k < count; k++)
            Flexible(
              child: Transform.translate(
                // بعد المقعد عن النص (من 0 لـ 1) → كل ما يبعد ينزل/يطلع ناحية الكارت
                offset: Offset(0, _arcOffset(k, count) * (isTop ? 1 : -1)),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 3,
                    right: 3,
                    top: isTop ? 0 : _arcHeight,
                    bottom: isTop ? _arcHeight : 0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: vertical ? 92 : 170),
                    child: _seat(indexes[k], vertical: vertical),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// مقدار انحناء المقعد رقم k في صف فيه count مقاعد
  double _arcOffset(int k, int count) {
    if (count <= 1) return 0;
    final center = (count - 1) / 2;
    final distance = (k - center).abs() / center; // 0 في النص و 1 على الأطراف
    return distance * distance * _arcHeight;
  }

  Widget _column(List<int> indexes, VerticalDirection direction) {
    return SizedBox(
      width: _sideColumnWidth,
      child: Column(
        verticalDirection: direction,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final i in indexes) _seat(i, vertical: true)],
      ),
    );
  }
}
