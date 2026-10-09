// =================================================================
// الكارت الكبير: أهم عنصر في اللعبة
// -----------------------------------------------------------------
// - ضهر الكارت: لوجو كارتة + شريط "Loading" فيه الكروت الباقية
//   (كروت الأكشن ليها ضهر مختلف من غير ما يتكشف هي أنهي كارت)
// - وش الكارت: شباك كمبيوتر قديم بلون وستيكر الكارت (شوف card_face.dart)
// - كل الضغطات في اللعبة بتكون على الكارت ده (شوف game_controller.dart)
// - مقاس الكارت بيتحسب تلقائياً عشان ياخد أكبر مساحة ممكنة (نسبة 5:7)
// =================================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../models.dart';
import '../theme.dart';
import 'card_face.dart';
import 'common.dart';

class BigCard extends StatelessWidget {
  final GameController game;
  const BigCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // نسيب مكان للظل الصلب تحت ويمين الكارت
        const shadow = 6.0;
        // أكبر مقاس يدخل في المساحة المتاحة مع الحفاظ على نسبة الكارت 5:7
        final w = min(constraints.maxWidth - shadow, (constraints.maxHeight - shadow) * 5 / 7);
        final h = w * 7 / 5;

        final card = game.currentCard;
        // مفتاح الوش: لما يتغير، الكارت بيتقلب
        final faceKey = card == null ? 'back' : 'front-${card.label}';

        return Center(
          child: SizedBox(
            width: w + shadow,
            height: h + shadow,
            child: Stack(
              children: [
                // RepaintBoundary: حركة الكارت بترسم الكارت بس، مش الشاشة كلها (أنعم)
                RepaintBoundary(
                  child: GestureDetector(
                    onTap: game.tapCard, // كل الضغطات على الكارت
                    child: AnimatedSwitcher(
                      // مدة القلبة كلها ربع ثانية (أسرع قلبة وفضلت ناعمة)
                      duration: const Duration(milliseconds: 250),
                      // الوش القديم يلف في أول نص الوقت، والجديد في النص التاني
                      switchInCurve: const Interval(0.5, 1, curve: Curves.easeOutQuad),
                      switchOutCurve: const Interval(0.5, 1, curve: Curves.easeInQuad),
                      transitionBuilder: (child, animation) => _flipTransition(child, animation, faceKey),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topLeft,
                        // ?current = ضيفه للقائمة بس لو مش null
                        children: [...previous, ?current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(faceKey),
                        // كل وش بيترسم مرة واحدة كصورة، وأثناء القلبة بنلف الصورة بس
                        child: RepaintBoundary(
                          child: card == null
                              ? _back(w, h)
                              : _CardFront(width: w, height: h, card: card, rule: game.currentRule!, phase: game.phase, game: game),
                        ),
                      ),
                    ),
                  ),
                ),
                // عداد مؤقت السؤال (فوق الكارت، بيتحدث لوحده من غير ما يعيد رسم الكارت)
                if (card != null && game.questionEndsAt != null && game.phase == CardPhase.front)
                  Positioned(
                    top: w * 0.15,
                    left: w * 0.05,
                    child: CountdownBadge(endsAt: game.questionEndsAt!, size: w * 0.15),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ضهر الكارت (ونص الزرار حسب مين اللي ينفع يسحب)
  Widget _back(double w, double h) {
    String tap;
    if (!game.isViewer) {
      tap = game.t(UiText.tapToDraw);
    } else if (game.myPlayerIndex == null) {
      tap = game.t(UiText.pickYourSeatShort);
    } else if (game.isMyTurn) {
      tap = game.drawPending ? '...' : game.t(UiText.yourTurnDraw);
    } else {
      tap = game.t(fillText(UiText.turnOf, {'name': game.currentPlayer.name}));
    }
    final title = game.nextTitleOnBack;
    return CardBackFace(
      width: w,
      height: h,
      deckLeft: game.deck.length,
      deckTotal: game.deckTotal,
      category: game.nextCategory,
      backColor: game.nextBackColor,
      backPattern: game.nextBackPattern,
      titleOnBack: title == null ? null : game.t(title),
      cardsLeftLabel: game.t(UiText.cardsLeft),
      tapLabel: tap,
      actionLabel: game.t(UiText.actionCard),
    );
  }

  /// حركة القلب ثلاثية الأبعاد حوالين المحور الرأسي
  Widget _flipTransition(Widget child, Animation<double> animation, String currentKey) {
    final isIncoming = child.key == ValueKey(currentKey);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // الجديد بيدخل من -90 درجة لـ 0، والقديم بيخرج من 0 لـ 90 درجة
        final angle = (1 - animation.value) * (pi / 2) * (isIncoming ? -1 : 1);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // عمق (perspective)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }
}

// =================================================================
// وش الكارت حسب المرحلة
// =================================================================
class _CardFront extends StatelessWidget {
  final double width, height;
  final PlayingCard card;
  final CardRule rule;
  final CardPhase phase;
  final GameController game;

  const _CardFront({
    required this.width,
    required this.height,
    required this.card,
    required this.rule,
    required this.phase,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return CardFrontFace(
      width: width,
      height: height,
      rank: card.rank,
      suit: card.suit,
      rule: rule,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(anim), child: child),
        ),
        child: KeyedSubtree(key: ValueKey(phase), child: _content(width)),
      ),
    );
  }

  /// المحتوى حسب المرحلة
  Widget _content(double w) {
    switch (phase) {
      case CardPhase.choosing:
        // موبايل اللاعب مش بيختار الخسران: بيشوف إن الهوست بيختار
        return game.isViewer ? _waitingHost(w) : _choosePanel(w);
      case CardPhase.bombTicking:
        return _bigMessage(
          w,
          hero: BombWarning(
            endsAt: game.bombEndsAt,
            child: StickerImage(Sticker.warning, size: w * 0.32),
          ),
          title: '💣 ${game.t(UiText.passPhone)}',
          subtitle: game.t(UiText.anyMoment),
        );
      case CardPhase.bombExploded:
        return _bigMessage(
          w,
          hero: Text('💥', style: TextStyle(fontSize: w * 0.26)),
          title: game.t(UiText.boom),
          titleColor: AppColors.red,
          hint: game.isViewer ? null : game.t(UiText.tapToPickLoser),
        );
      case CardPhase.clapGo:
        return _clapButton(w);
      case CardPhase.front:
      case CardPhase.back:
        return _ruleView(w);
    }
  }

  /// عرض القاعدة
  Widget _ruleView(double w) {
    final description = fillText(rule.description, {'player': game.currentPlayer.name});
    final hint = game.isViewer
        ? UiText.hostDecides
        : switch (rule.type) {
            RuleType.assign => UiText.tapToChoose,
            RuleType.free => UiText.tapToGive,
            RuleType.self => UiText.tapToTake,
            RuleType.cadu => UiText.tapNext,
            RuleType.bomb => UiText.tapStartBomb,
            RuleType.clap => UiText.tapToPickLoser,
            RuleType.silence => UiText.silenceHint,
          };
    return RuleBody(
      width: w,
      rank: card.rank,
      rule: rule,
      title: game.t(rule.title),
      subtitle: rule.subtitle == null ? null : game.t(rule.subtitle!),
      description: game.t(description),
      hint: game.t(hint),
    );
  }

  /// موبايل اللاعب وقت اختيار الخسران
  Widget _waitingHost(double w) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (game.timedOut) _timeUp(w),
          StickerImage(Sticker.magnifier, size: w * 0.24),
          SizedBox(height: w * 0.04),
          Text(game.t(UiText.hostPicking), textAlign: TextAlign.center, style: pixelStyle(size: w * 0.07)),
        ],
      ),
    );
  }

  Widget _timeUp(double w) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.012),
        decoration: Brutal.box(color: AppColors.red, borderWidth: 2, shadowOffset: const Offset(2, 2)),
        child: Text('⏰ ${game.t(UiText.timeUp)}', style: pixelStyle(size: w * 0.05, color: AppColors.paper)),
      ),
    );
  }

  /// لوحة اختيار الخسران جوه الكارت (الهوست بس)
  Widget _choosePanel(double w) {
    final prompt = rule.prompt ?? UiText.tapToPickLoser;
    final gap = w * 0.03;

    // LayoutBuilder بيدينا العرض الحقيقي المتاح، فنقسمه على عمودين بالظبط
    return LayoutBuilder(builder: (context, constraints) {
      final fullWidth = constraints.maxWidth - 4; // نسيب مكان للظل
      final buttonWidth = (fullWidth - gap) / 2 - 1;
      return SingleChildScrollView(
        child: Column(
          children: [
            if (game.timedOut) _timeUp(w),
            Headline(game.t(prompt), size: w * 0.07, align: TextAlign.center),
            // تحذير الكادو
            if (game.caduActive) _warning(w, game.t(fillText(UiText.caduWarn, {'n': game.caduCards.length}))),
            // تحذير الكروت اللي على جنب
            if (game.asideCards.isNotEmpty)
              _warning(w, game.t(fillText(UiText.asideWarn, {'n': game.asideCards.length}))),
            SizedBox(height: w * 0.04),
            // زرار لكل لاعب
            Wrap(
              spacing: gap,
              runSpacing: gap,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < game.players.length; i++) _playerButton(w, i, buttonWidth),
              ],
            ),
            // زرار "محدش خسر"
            if (game.allowNobody) ...[
              SizedBox(height: w * 0.04),
              SizedBox(
                width: fullWidth,
                child: BrutalButton(
                  label: game.t(UiText.nobody),
                  onTap: game.pickNobody,
                  showArrow: false,
                  height: w * 0.13,
                  fontSize: w * 0.048,
                ),
              ),
            ],
            // زرار "مش عارفين؟ حطّه على جنب" (في التصفيق)
            if (game.canSetAside) ...[
              SizedBox(height: w * 0.04),
              SizedBox(
                width: fullWidth,
                child: BrutalButton(
                  label: game.t(UiText.setAside),
                  onTap: game.setAside,
                  color: AppColors.paper,
                  showArrow: false,
                  height: w * 0.13,
                  fontSize: w * 0.044,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _warning(double w, String text) {
    return Padding(
      padding: EdgeInsets.only(top: w * 0.015),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: AppColors.red),
      ),
    );
  }

  /// زرار باسم لاعب: مربع بلونه + الاسم
  Widget _playerButton(double w, int index, double width) {
    final player = game.players[index];
    final initial = player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase();
    return GestureDetector(
      onTap: () => game.pickLoser(index),
      child: Container(
        width: width,
        height: w * 0.13,
        clipBehavior: Clip.antiAlias,
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
        child: Row(
          children: [
            Container(
              width: w * 0.1,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: player.color,
                border: const BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
              ),
              child: Text(initial, style: pixelStyle(size: w * 0.045)),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.015),
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w * 0.047, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// رسالة كبيرة في نص الكارت (للقنبلة)
  Widget _bigMessage(double w,
      {required Widget hero, required String title, String? subtitle, String? hint, Color titleColor = AppColors.ink}) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: w * 0.86,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hero,
                    SizedBox(height: w * 0.05),
                    Text(title, textAlign: TextAlign.center, style: pixelStyle(size: w * 0.08, color: titleColor)),
                    if (subtitle != null) ...[
                      SizedBox(height: w * 0.02),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: w * 0.05, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hint != null) OkButton(w: w, text: hint),
      ],
    );
  }

  /// زرار التصفيق الضخم: بيظهر أول ما الكارت يتقلب (الكارت كله بيستقبل الضغطة)
  Widget _clapButton(double w) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Pulse(
              scale: 1.06,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: w * 0.64,
                height: w * 0.64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow,
                  border: Border.all(color: AppColors.ink, width: 3),
                  boxShadow: Brutal.hardShadow(offset: const Offset(6, 6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👏', style: TextStyle(fontSize: w * 0.18)),
                    Text(game.t(UiText.clapNow), style: pixelStyle(size: w * 0.09)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          game.t(UiText.lastClapLoses),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }
}

// =================================================================
// عداد مؤقت السؤال: بيتحدث لوحده (من غير ما يعيد رسم باقي الشاشة)
// =================================================================
class CountdownBadge extends StatefulWidget {
  final DateTime endsAt;
  final double size;
  const CountdownBadge({super.key, required this.endsAt, required this.size});

  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // بنحدّث 4 مرات في الثانية عشان الرقم يتغير في وقته بالظبط
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    final seconds = max(0, (left.inMilliseconds / 1000).ceil());
    final urgent = seconds <= 5;
    if (seconds == 0) _timer?.cancel();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: urgent ? AppColors.red : AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: Brutal.hardShadow(offset: const Offset(3, 3)),
      ),
      child: Text('$seconds', textDirection: TextDirection.ltr, style: rankStyle(size: widget.size * 0.45, color: urgent ? AppColors.paper : AppColors.ink)),
    );
  }
}

// =================================================================
// تحذير القنبلة: في آخر 5 ثواني الستيكر بينبض أسرع ويحمر (من غير أرقام عشان الوقت يفضل سر)
// =================================================================
class BombWarning extends StatefulWidget {
  final DateTime? endsAt;
  final Widget child;
  const BombWarning({super.key, required this.endsAt, required this.child});

  @override
  State<BombWarning> createState() => _BombWarningState();
}

class _BombWarningState extends State<BombWarning> {
  Timer? _timer;
  bool _final = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final endsAt = widget.endsAt;
      final isFinal = endsAt != null && endsAt.difference(DateTime.now()).inMilliseconds <= 5000;
      if (isFinal != _final && mounted) setState(() => _final = isFinal); // بنعيد الرسم مرة واحدة بس
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pulse(
      key: ValueKey(_final),
      scale: _final ? 1.25 : 1.12,
      duration: Duration(milliseconds: _final ? 180 : 450),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _final ? AppColors.red.withValues(alpha: 0.35) : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
  }
}
