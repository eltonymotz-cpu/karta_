// =================================================================
// شاشة اللعب
// -----------------------------------------------------------------
// الكارت في النص وواخد أكبر مساحة، واللاعيبة قاعدين حواليه على أطراف الشاشة
// بنفس ترتيب الأدوار مع عقارب الساعة.
// - الهوست: بيختار الخسران، وبيعمل سكيب، وبيصحح الكروت (دوس على اسم أي لاعب).
// - موبايل اللاعب: بيختار هو مين، وبيسحب في دوره بس.
// =================================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/big_card.dart';
import '../widgets/card_face.dart';
import '../widgets/chat_panel.dart';
import '../widgets/common.dart';
import '../widgets/game_fx.dart';
import '../widgets/game_panels.dart';
import '../widgets/player_seat.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/wallet_panel.dart';
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
          child: LayoutBuilder(builder: (context, constraints) {
            final playing = !(game.isViewer && !game.viewerHasState);
            // الشاشات العريضة: الترتيب لايف على جنب، والموبايل: شريط صغير فوق الترابيزة
            final wide = constraints.maxWidth >= 860 && playing;
            final table = ConstrainedBox(
              // على الشاشات العريضة (كمبيوتر/تابلت) نخلي اللعبة بعرض مناسب في النص
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  children: [
                    _TopBar(game: game),
                    // موبايل اللاعب اللي لسه مستني صاحب القعدة يبدأ
                    if (!playing)
                      Expanded(child: _WaitingForHost(game: game))
                    else ...[
                      // موبايل اللاعب، أو الهوست في أكتر من موبايل (هو كمان لاعب): إنت مين؟
                      if (game.isViewer || game.room != null) _ViewerBanner(game: game),
                      _StatusChips(game: game),
                      if (!wide) ...[
                        const SizedBox(height: 6),
                        LiveRankingStrip(game: game, onTap: () => showRankingSheet(context, game)),
                      ],
                      const SizedBox(height: 4),
                      Expanded(child: _Table(game: game)),
                      // الهوست: نقل الدور جوه الكارت (وزن وقافية، براندات...) - تحت على اليمين
                      if (game.isHost && game.innerTurn != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr,
                              children: [
                                SquareButton(onTap: () => game.moveInnerTurn(-1), child: Text(game.t(UiText.prevInner))),
                                const SizedBox(width: 8),
                                Pulse(
                                  scale: 1.05,
                                  child: SquareButton(
                                    color: AppColors.orange,
                                    onTap: () => game.moveInnerTurn(1),
                                    child: Text('👉 ${game.t(UiText.nextInner)}', style: pixelStyle(size: 14)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // الأزرار السريعة (إيموجي بيظهر في نص اللعبة عند الكل)
                      ReactionBar(game: game),
                    ],
                  ],
                ),
              ),
            );
            if (!wide) return Center(child: table);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: table),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 60, 12, 12),
                  child: SizedBox(width: 250, child: LiveRankingPanel(game: game)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// =================================================================
// موبايل اللاعب: إنت مين؟ + دورك ولا لأ
// =================================================================
class _ViewerBanner extends StatelessWidget {
  final GameController game;
  const _ViewerBanner({required this.game});

  /// القعدات اللي فتحنا فيها "إنت مين؟" لوحدها (مرة واحدة بس لكل قعدة)
  static final Set<String> _autoAsked = {};

  @override
  Widget build(BuildContext context) {
    final mine = game.myPlayerIndex;
    // أول ما اللاعب يدخل القعدة: نسأله هو مين على طول (عشان يقدر يسحب في دوره)
    final code = game.roomCode;
    if (mine == null && code != null && game.players.isNotEmpty && _autoAsked.add(code)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _pickSeat(context);
      });
    }
    final text = mine == null
        ? game.t(UiText.pickYourSeat)
        : game.isMyTurn
            ? game.t(fillText(UiText.youAreTurn, {'name': game.players[mine].name}))
            : game.t(fillText(UiText.youAre, {'name': game.players[mine].name}));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => _pickSeat(context),
        child: Pulse(
          enabled: mine == null || game.isMyTurn,
          scale: 1.03,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: Brutal.box(
              color: mine == null ? AppColors.yellow : (game.isMyTurn ? AppColors.green : AppColors.paper),
              borderWidth: 2,
              shadowOffset: const Offset(2, 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 18, color: AppColors.ink),
                const SizedBox(width: 6),
                Flexible(child: Text(text, style: pixelStyle(size: 14))),
                const SizedBox(width: 6),
                Icon(Icons.swap_horiz, size: 18, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// اختيار اللاعب اللي الموبايل ده بيمثله
  Future<void> _pickSeat(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: RetroWindow(
          title: game.t(UiText.whoAreYou),
          barColor: AppColors.yellow,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(game.t(UiText.whoAreYouHint), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              for (var i = 0; i < game.players.length; i++) _seatOption(context, i),
              if (game.myPlayerIndex != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, -1),
                  child: Text(game.t(UiText.justWatch), style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    if (picked < 0) {
      game.releaseSeat();
    } else {
      game.claimSeat(picked);
    }
  }

  Widget _seatOption(BuildContext context, int i) {
    final owner = game.claims[i];
    final takenByOther = owner != null && owner != game.deviceId;
    final mine = game.myPlayerIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: takenByOther ? 0.45 : 1,
        child: GestureDetector(
          onTap: takenByOther ? null : () => Navigator.pop(context, i),
          child: Container(
            height: 46,
            clipBehavior: Clip.antiAlias,
            decoration: Brutal.box(color: mine ? AppColors.yellow : AppColors.paper, borderWidth: 2, shadowOffset: const Offset(2, 2)),
            child: Row(
              children: [
                Container(
                  width: 14,
                  decoration: BoxDecoration(
                    color: game.players[i].color,
                    border: BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(game.players[i].name, style: const TextStyle(fontWeight: FontWeight.w800))),
                if (takenByOther)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(game.t(UiText.seatTaken), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                if (mine) const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.check, size: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// شاشة انتظار موبايل اللاعب: لسه متصلش أو صاحب القعدة لسه في الإعداد
// =================================================================
class _WaitingForHost extends StatelessWidget {
  final GameController game;
  const _WaitingForHost({required this.game});

  @override
  Widget build(BuildContext context) {
    final connected = game.room?.connected ?? false;
    // الهوست قفل القعدة أو طلّعني منها
    if (game.roomClosed || game.wasKicked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚪', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Headline(game.t(game.wasKicked ? UiText.kickedOut : UiText.roomClosedMsg), size: 24, align: TextAlign.center),
              const SizedBox(height: 20),
              BrutalButton(label: game.t(UiText.back), onTap: game.goHome),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.all(10),
              child: Image.asset(AppTheme.logo),
            ),
            const SizedBox(height: 28),
            Text(game.t(UiText.roomCode), style: pixelStyle(size: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: Brutal.box(color: AppColors.yellow),
              child: Text(game.roomCode ?? '', textDirection: TextDirection.ltr, style: rankStyle(size: 30)),
            ),
            const SizedBox(height: 24),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 3)),
            const SizedBox(height: 14),
            Headline(game.t(connected ? UiText.waitingHost : UiText.connecting), size: 22, align: TextAlign.center),
            // اسمي في اللعبة (اللي دخل بالـ QR بيكتبه هنا، وأي حد يقدر يعدّله قبل ما اللعب يبدأ)
            if (connected) ...[
              const SizedBox(height: 20),
              _NameBox(game: game),
            ],
            // اللوبي: مين في القعدة + الشات وإحنا مستنيين
            if (connected && game.chatAvailable) ...[
              const SizedBox(height: 20),
              SizedBox(height: 220, width: 360, child: BrutalBox(padding: EdgeInsets.zero, child: LobbyList(game: game))),
              const SizedBox(height: 12),
              BrutalButton(label: '💬 ${game.t(UiText.lobbyChat)}', onTap: () => showChatSheet(context, game), color: AppColors.blue),
            ],
          ],
        ),
      ),
    );
  }
}

/// خانة اسم اللاعب في شاشة الانتظار
class _NameBox extends StatefulWidget {
  final GameController game;
  const _NameBox({required this.game});

  @override
  State<_NameBox> createState() => _NameBoxState();
}

class _NameBoxState extends State<_NameBox> {
  late final _name = TextEditingController(text: widget.game.nickname);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    widget.game.renameMe(_name.text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final saved = game.nickname.isNotEmpty;
    return SizedBox(
      width: 360,
      child: BrutalBox(
        color: saved ? AppColors.paper : AppColors.yellow,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(saved ? game.t(fillText(UiText.willJoinAs, {'name': game.nickname})) : game.t(UiText.nameRequired),
                style: pixelStyle(size: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 24,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(hintText: game.t(UiText.yourNameInGame), counterText: '', isDense: true, filled: true, fillColor: AppColors.paper),
                  ),
                ),
                const SizedBox(width: 8),
                SquareButton(color: AppColors.green, onTap: _save, child: Text(game.t(UiText.nameSaved))),
              ],
            ),
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
    final online = game.room != null; // هوست أو موبايل لاعب
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
              if (!online) ...[const SizedBox(width: 4), Text(game.t(UiText.history))],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SquareButton(
          onTap: game.toggleSound,
          child: Icon(game.sound.enabled ? Icons.volume_up : Icons.volume_off),
        ),
        const SizedBox(width: 8),
        LangToggle(game: game, compact: online),
        const Spacer(),
        // الشات (في القعدات الأونلاين)
        if (game.chatAvailable) ...[ChatButton(game: game), const SizedBox(width: 8)],
        // الهوست: زرار الـ QR فيه كود القعدة
        if (online && !game.isViewer) ...[
          SquareButton(
            color: AppColors.yellow,
            onTap: () => showQrDialog(context, game),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [const Icon(Icons.qr_code_2), if (!game.chatAvailable) ...[const SizedBox(width: 4), Text(game.roomCode ?? '')]],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // موبايل اللاعب: زرار خروج / الهوست: زرار إنهاء اللعبة
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
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.ink, width: Brutal.border),
      ),
      builder: (context) => ListenableBuilder(
        listenable: game,
        builder: (context, _) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WindowBar(title: game.t(UiText.history), color: AppColors.teal),
              Expanded(
                child: game.log.isEmpty
                    ? Center(child: Text(game.t(UiText.noHistory), style: TextStyle(color: AppColors.muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: game.log.length,
                        separatorBuilder: (_, _) => Divider(color: AppColors.line, height: 1),
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
    final yes = await confirmDialog(context, game, game.t(UiText.confirmEnd), game.t(UiText.yes));
    if (yes) game.finishGame();
  }
}

/// نافذة تأكيد صغيرة (بترجع true لو اتأكد)
Future<bool> confirmDialog(BuildContext context, GameController game, String title, String confirmLabel) async {
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
            Headline(title, size: 22),
            const SizedBox(height: 20),
            BrutalButton(label: confirmLabel, onTap: () => Navigator.pop(context, true), color: AppColors.red),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(game.t(UiText.no), style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 16)),
            ),
          ],
        ),
      ),
    ),
  );
  return yes == true;
}

// =================================================================
// شارات الحالة + زرار السكيب للهوست
// =================================================================
class _StatusChips extends StatelessWidget {
  final GameController game;
  const _StatusChips({required this.game});

  @override
  Widget build(BuildContext context) {
    final silentName = game.silentIndex >= 0 ? game.players[game.silentIndex].name : '';
    final chips = <Widget>[
      // الهوست: سكيب الكارت الحالي
      if (game.canSkip)
        GestureDetector(
          onTap: game.skipCard,
          child: _chip('⏭ ${game.t(UiText.skipCard)}', AppColors.orange),
        ),
      // الهوست: يكشف إجابة الكارت للكل (أو يخفيها تاني)
      if (game.isHost && game.hasAnswer && game.currentCard != null)
        GestureDetector(
          onTap: game.toggleAnswer,
          child: _chip(game.t(game.answerShown ? UiText.hideAnswer : UiText.showAnswer), AppColors.green),
        ),
      // الهوست: يحرّك الدور جوه الكارت (وزن وقافية، براندات...)
      // الكوينز: المحفظة (أرصدة، عمليات، تحويل، تحديات)
      if (game.coinsOn)
        GestureDetector(
          onTap: () => showWalletSheet(context, game),
          child: _chip('🪙 ${game.t(game.economy.config.name)}', AppColors.yellow),
        ),
      // الهوست: إيقاف/تكملة اللعبة
      if (game.isHost)
        GestureDetector(
          onTap: game.togglePause,
          child: _chip(game.t(game.paused ? UiText.resumeGame : UiText.pauseGame), game.paused ? AppColors.green : AppColors.paper),
        ),
      // الهوست: يعدّي دور لاعب من غير ما يسحب
      if (game.canSkipPlayer)
        GestureDetector(
          onTap: game.skipPlayer,
          child: _chip('⏭ ${game.t(UiText.skipPlayer)}', AppColors.paper),
        ),
      // الأدوار والأوقات (الكل يشوف، والهوست بس يتحكم)
      GestureDetector(
        onTap: () => showTurnsSheet(context, game),
        child: _chip('⏱ ${game.t(UiText.turns)}', AppColors.blue),
      ),
      if (game.caduActive)
        _chip(game.t(fillText(UiText.caduChip, {'n': game.caduCards.length})), AppColors.yellow),
      if (game.asideCards.isNotEmpty)
        _chip(game.t(fillText(UiText.asideChip, {'n': game.asideCards.length})), AppColors.blue),
      // الصامت: بيظهر بس والكارت مقلوب (وبيختفي طول ما فيه كارت شغال)
      if (game.showSilenceMarker)
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
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
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
                          clipBehavior: Clip.antiAlias,
                          decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  color: game.players[i].color,
                                  border: BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
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
                child: Text(game.t(UiText.cancel), style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
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
// الترابيزة: الكارت في النص واللاعيبة حواليه + طبقة الأنيميشن
// -----------------------------------------------------------------
// - على الموبايل: اللاعيبة في قوسين فوق وتحت الكارت (زي ما يكونوا قاعدين
//   حوالين ترابيزة)، والكارت ياخد عرض الشاشة كله.
// - على الشاشات العريضة (تابلت/كمبيوتر): لو فيه مساحة على الجناب
//   بنقعد لاعيبة يمين وشمال كمان.
// الترتيب دايماً مع عقارب الساعة: تحت (يمين ← شمال) ← شمال ← فوق ← يمين
// =================================================================
class _Table extends StatefulWidget {
  final GameController game;
  const _Table({required this.game});

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
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

  GameController get game => widget.game;

  // ---------------- الأنيميشن ----------------
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _cardKey = GlobalKey();
  final Map<int, GlobalKey> _seatKeys = {};
  final List<Widget> _fx = [];  // الأنيميشن الشغالة دلوقتي
  int _fxCounter = 0;
  int _lastEventId = 0;
  int _lastCoinFx = 0;
  int _lastReaction = 0;

  @override
  void initState() {
    super.initState();
    _lastEventId = game.lastEvent?.id ?? 0; // مانشغلش أنيميشن لحدث قديم
    _lastCoinFx = game.coinFx.isEmpty ? 0 : game.coinFx.last.id;
    _lastReaction = game.reactionFeed.isEmpty ? 0 : game.reactionFeed.last.id;
    game.addListener(_onGameChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // كل صور الكروت (أيقونات وخلفيات) بتتحمل من أول اللعبة، فالقلبة مابتستناش أي صورة
    if (!_precached) {
      _precached = true;
      precacheModeImages(context, game.modeId);
    }
  }

  bool _precached = false;

  @override
  void didUpdateWidget(_Table old) {
    super.didUpdateWidget(old);
    if (old.game != game) {
      old.game.removeListener(_onGameChanged);
      game.addListener(_onGameChanged);
    }
  }

  @override
  void dispose() {
    game.removeListener(_onGameChanged);
    super.dispose();
  }

  GlobalKey _seatKey(int i) => _seatKeys.putIfAbsent(i, () => GlobalKey());

  /// حدث جديد → نشغّل الأنيميشن بتاعته (بعد ما الشاشة تترسم عشان نعرف الأماكن)
  void _onGameChanged() {
    // تغييرات الكوينز: "-50" أحمر أو "+25" أخضر فوق اسم اللاعب
    final newCoins = game.coinFx.where((c) => c.id > _lastCoinFx).toList();
    // الأزرار السريعة: الإيموجي يطلع في نص الترابيزة (بمكان عشوائي شوية عشان مايتغطوش على بعض)
    final newReactions = game.reactionFeed.where((r) => r.id > _lastReaction).toList();
    if (newReactions.isNotEmpty) {
      _lastReaction = newReactions.last.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final center = _centerOf(_cardKey);
        if (!mounted || center == null) return;
        for (final r in newReactions) {
          final jitter = Offset(((r.id * 37) % 120 - 60).toDouble(), ((r.id * 53) % 60 - 30).toDouble());
          _addFx((key, done) => FxReaction(key: key, at: center + jitter, emoji: r.emoji, name: r.name, onDone: done));
        }
      });
    }
    if (newCoins.isNotEmpty) {
      _lastCoinFx = newCoins.last.id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _playCoins(newCoins));
    }
    final event = game.lastEvent;
    if (event == null || event.id == _lastEventId) return;
    _lastEventId = event.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play(event));
  }

  void _playCoins(List<CoinFx> changes) {
    if (!mounted) return;
    for (final c in changes) {
      final seat = _centerOf(_seatKey(c.player));
      if (seat == null) continue;
      _addFx((key, done) => FxFloatingLabel(
            key: key,
            at: seat + const Offset(0, 22),
            text: '${c.delta > 0 ? '+' : ''}${c.delta} 🪙',
            color: c.delta > 0 ? AppColors.green : AppColors.orange,
            delay: const Duration(milliseconds: 450), // بعد أنيميشن الكارت
            onDone: done,
          ));
    }
  }

  Offset? _centerOf(GlobalKey key) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || box == null || !box.attached) return null;
    return stackBox.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void _addFx(Widget Function(Key key, VoidCallback done) build) {
    final key = ValueKey(_fxCounter++);
    late Widget fx;
    void remove() {
      if (mounted && _fx.contains(fx)) setState(() => _fx.remove(fx));
    }

    fx = build(key, remove);
    setState(() => _fx.add(fx));
    // أمان: أي أنيميشن بيتشال بعد 3 ثواني بالكتير حتى لو ماخلصتش لأي سبب
    Future.delayed(const Duration(seconds: 3), remove);
  }

  void _play(GameEvent event) {
    if (!mounted) return;
    final still = MediaQuery.of(context).disableAnimations;
    final player = event.player >= 0 && event.player < game.players.length ? game.players[event.player] : null;
    final seat = player == null ? null : _centerOf(_seatKey(event.player));

    switch (event.kind) {
      case GameEventKind.loss:
        final card = _centerOf(_cardKey);
        // الكارت بيطير لمكان الخسران
        if (!still && card != null && seat != null) {
          _addFx((key, done) => FxFlyingCard(key: key, from: card, to: seat, color: player!.color, onDone: done));
        }
        if (seat != null) {
          _addFx((key, done) => FxFloatingLabel(
                key: key,
                at: seat,
                text: '+${max(1, event.count)} 🃏',
                color: AppColors.red,
                delay: Duration(milliseconds: still ? 0 : 380),
                onDone: done,
              ));
        }
        if (player != null) _toast(game.t(fillText(UiText.fxLost, {'name': player.name})), AppColors.red);
        break;
      case GameEventKind.correction:
        if (seat != null) {
          _addFx((key, done) => FxFloatingLabel(key: key, at: seat, text: '-1 ✔', color: AppColors.green, onDone: done));
        }
        if (player != null) _toast(game.t(fillText(UiText.fxCorrected, {'name': player.name})), AppColors.green);
        break;
      case GameEventKind.nobody:
        _toast(game.t(UiText.fxNobody), AppColors.green);
        break;
      case GameEventKind.skip:
        _toast(game.t(UiText.fxSkipped), AppColors.orange);
        break;
      case GameEventKind.timeout:
        _toast('⏰ ${game.t(UiText.timeUp)}', AppColors.yellow);
        break;
    }
  }

  void _toast(String text, Color color) {
    _addFx((key, done) => Positioned(
          key: key,
          top: 2,
          left: 0,
          right: 0,
          child: Center(child: FxToast(text: text, color: color, onDone: done)),
        ));
  }

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

        return Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Column(
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
                          key: _cardKey,
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
            ),
            // الأنيميشن فوق كل حاجة (IgnorePointer: مابتستقبلش ضغطات أبداً،
            // فمش ممكن تغطي على مقعد لاعب أو على الكارت)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(clipBehavior: Clip.none, children: _fx),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _seat(int index, {required bool vertical}) {
    final Player player = game.players[index];
    return KeyedSubtree(
      key: _seatKey(index),
      child: PlayerSeat(
        player: player,
        isCurrent: index == game.currentIndex,
        // علامة الصمت بتختفي طول ما فيه كارت شغال (وبترجع لما الكارت يخلص)
        isSilent: index == game.silentIndex && game.showSilenceMarker,
        clickable: game.canPickLoser,
        isMe: game.isViewer && game.myPlayerIndex == index,
        // ساعة الدور: بتعد لفوق من أول ما صاحب الدور يسحب
        clock: game.activeTurn?.player == index
            ? StopwatchText(
                turn: game.activeTurn!,
                now: () => game.nowMs,
                style: rankStyle(size: 11, color: game.activeTurn!.isPaused ? AppColors.muted : AppColors.ink),
              )
            : null,
        vertical: vertical,
        turnLabel: game.t(UiText.yourTurn),
        coins: game.coinsOn ? CoinAmount(game: game, amount: game.economy.balanceOf(index), size: 10) : null,
        pointer: game.innerTurn == index,
        // الهوست: وقت الاختيار الدوسة بتختار الخسران، وغير كده بتفتح تصحيح الكروت
        onTap: () {
          if (game.canPickLoser) {
            game.pickLoser(index);
          } else if (game.isHost) {
            _openCorrections(index);
          }
        },
        tappable: game.isHost,
      ),
    );
  }

  /// الهوست: كروت اللاعب + شيل كارت اتدى بالغلط
  void _openCorrections(int playerIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.ink, width: Brutal.border)),
      builder: (sheetContext) => ListenableBuilder(
        listenable: game,
        builder: (sheetContext, _) {
          if (playerIndex >= game.players.length) return const SizedBox.shrink();
          final player = game.players[playerIndex];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WindowBar(title: game.t(fillText(UiText.cardsOf, {'name': player.name})), color: player.color),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(game.t(UiText.correctionHint), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (player.cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(game.t(UiText.noCards), textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < player.cards.length; i++)
                          InputChip(
                            label: Text(player.cards[i].label, style: pixelStyle(size: 15)),
                            backgroundColor: AppColors.paper,
                            side: BorderSide(color: AppColors.ink, width: 2),
                            deleteIcon: Icon(Icons.close, size: 18, color: AppColors.red),
                            onDeleted: () async {
                              final label = player.cards[i].label;
                              final yes = await confirmDialog(
                                sheetContext,
                                game,
                                game.t(fillText(UiText.removeCardConfirm, {'card': label, 'name': player.name})),
                                game.t(UiText.removeCard),
                              );
                              if (yes) game.removeCardFrom(playerIndex, i);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
