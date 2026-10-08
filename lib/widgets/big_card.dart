// =================================================================
// الكارت الكبير: أهم عنصر في اللعبة
// -----------------------------------------------------------------
// - ضهر الكارت: لوجو كارتة + عدد الكروت الباقية
// - وش الكارت: كل قيمة ليها لون ونقشة هندسية مختلفة (شوف cardStyles في theme.dart)
// - كل الضغطات في اللعبة بتكون على الكارت ده (شوف game_controller.dart)
// - مقاس الكارت بيتحسب تلقائياً عشان ياخد أكبر مساحة ممكنة (نسبة 5:7)
// =================================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../models.dart';
import '../theme.dart';
import 'card_decor.dart';
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
        // لون إطار الكارت: لون الكارت المسحوب، أو أصفر لضهر الكارت
        final frameColor = card == null ? AppColors.paper : styleFor(card.rank).tint;

        return Center(
          child: SizedBox(
            width: w + shadow,
            height: h + shadow,
            // RepaintBoundary: حركة الكارت بترسم الكارت بس، مش الشاشة كلها (أنعم)
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: game.tapCard, // كل الضغطات على الكارت
                child: AnimatedSwitcher(
                  // مدة القلبة كلها 340 مللي ثانية (سريعة وناعمة)
                  duration: const Duration(milliseconds: 340),
                  // الوش القديم يلف في أول نص الوقت، والجديد في النص التاني
                  switchInCurve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
                  switchOutCurve: const Interval(0.5, 1, curve: Curves.easeInCubic),
                  transitionBuilder: (child, animation) => _flipTransition(child, animation, faceKey),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    // ?current = ضيفه للقائمة بس لو مش null
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(faceKey),
                    child: _CardFrame(
                      width: w,
                      height: h,
                      color: frameColor,
                      child: card == null
                          ? _CardBack(width: w, deckCount: game.deck.length, game: game)
                          : _CardFront(width: w, card: card, rule: game.currentRule!, phase: game.phase, game: game),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

/// إطار الكارت: مدوّر بحدود سودا وظل صلب
class _CardFrame extends StatelessWidget {
  final double width, height;
  final Color color;
  final Widget child;
  const _CardFrame({required this.width, required this.height, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = width * 0.07;
    return Container(
      width: width,
      height: height,
      decoration: Brutal.box(color: color, borderWidth: 2.5, shadowOffset: const Offset(6, 6), radius: radius),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius - 2.5), child: child),
    );
  }
}

// =================================================================
// ضهر الكارت
// =================================================================
class _CardBack extends StatelessWidget {
  final double width;
  final int deckCount;
  final GameController game;
  const _CardBack({required this.width, required this.deckCount, required this.game});

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Stack(
      fit: StackFit.expand,
      children: [
        // زينة هندسية
        Positioned(top: w * 0.05, right: w * 0.05, child: const DotGrid(columns: 4, rows: 3)),
        Positioned(top: w * 0.04, left: w * 0.04, child: const ShapeAccent(size: 10)),
        Positioned(
          bottom: w * 0.13,
          left: -w * 0.06,
          child: _circle(w * 0.16, AppColors.sky),
        ),
        Positioned(
          top: w * 0.32,
          right: -w * 0.05,
          child: Transform.rotate(angle: 0.4, child: _square(w * 0.12, AppColors.red)),
        ),
        // عدد الكروت الباقية فوق
        Positioned(
          top: w * 0.05,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.008),
              decoration: Brutal.box(color: AppColors.sky, borderWidth: 2, radius: 99, shadowOffset: Offset.zero),
              child: Text(
                '🃏 $deckCount ${game.t(UiText.cardsLeft)}',
                style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
          ),
        ),
        // اللوجو في النص
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.1, w * 0.18, w * 0.1, w * 0.32),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        // "دوس اسحب"
        Positioned(
          bottom: w * 0.11,
          left: 0,
          right: 0,
          child: Center(
            child: Pulse(
              scale: 1.07,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: w * 0.022),
                decoration: Brutal.box(color: AppColors.yellow, radius: 99, shadowOffset: const Offset(3, 3)),
                child: Text(
                  game.t(UiText.tapToDraw),
                  style: TextStyle(fontSize: w * 0.055, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
            ),
          ),
        ),
        // شريط الأشكال تحت
        Positioned(left: w * 0.04, right: w * 0.04, bottom: w * 0.025, child: ShapesStrip(height: w * 0.045)),
      ],
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.ink, width: 2)),
      );

  Widget _square(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, border: Border.all(color: AppColors.ink, width: 2)),
      );
}

// =================================================================
// وش الكارت
// =================================================================
class _CardFront extends StatelessWidget {
  final double width;
  final PlayingCard card;
  final CardRule rule;
  final CardPhase phase;
  final GameController game;

  const _CardFront({
    required this.width,
    required this.card,
    required this.rule,
    required this.phase,
    required this.game,
  });

  // شكل الكارت: لون ونقشة خاصين بقيمة الكارت
  CardStyle get style => styleFor(card.rank);

  // لون رمز الكارت: أحمر للقلب والديناري، وأسود للباقي
  Color get suitColor => card.isRed ? AppColors.red : AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Stack(
      children: [
        // النقشة الهندسية الخاصة بالكارت ده
        Positioned.fill(child: CardDecor(style: style, seed: card.rank.hashCode)),
        // الركن اللي فوق على الشمال
        Positioned(top: w * 0.035, left: w * 0.05, child: _corner(w)),
        // الركن اللي تحت على اليمين (مقلوب)
        Positioned(
          bottom: w * 0.035,
          right: w * 0.05,
          child: Transform.rotate(angle: pi, child: _corner(w)),
        ),
        // محتوى الكارت (بيتغير حسب المرحلة بحركة سريعة)
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.07, w * 0.2, w * 0.07, w * 0.19),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(anim), child: child),
              ),
              child: KeyedSubtree(key: ValueKey(phase), child: _content(w)),
            ),
          ),
        ),
      ],
    );
  }

  /// الركن: القيمة في دايرة بلون الكارت وتحتها الشكل
  Widget _corner(double w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(card.rank,
            style: TextStyle(fontSize: w * 0.1, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1)),
        Text(card.suit, style: TextStyle(fontSize: w * 0.075, color: suitColor, height: 1.1)),
      ],
    );
  }

  /// المحتوى حسب المرحلة
  Widget _content(double w) {
    switch (phase) {
      case CardPhase.choosing:
        return _choosePanel(w);
      case CardPhase.bombTicking:
        return _bigMessage(
          w,
          emoji: Pulse(scale: 1.15, duration: const Duration(milliseconds: 500), child: _emojiCircle(w, '💣', w * 0.3)),
          title: game.t(UiText.passPhone),
          subtitle: game.t(UiText.anyMoment),
        );
      case CardPhase.bombExploded:
        return _bigMessage(
          w,
          emoji: _emojiCircle(w, '💥', w * 0.34, color: AppColors.red),
          title: game.t(UiText.boom),
          titleColor: AppColors.red,
          hint: game.t(UiText.tapToPickLoser),
        );
      case CardPhase.clapGo:
        return _clapButton(w);
      case CardPhase.front:
      case CardPhase.back:
        return _ruleView(w);
    }
  }

  /// دايرة بلون الكارت بحدود سودا فيها إيموجي (زي صور البروفايل في التصميم)
  Widget _emojiCircle(double w, String emoji, double size, {Color? color}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? style.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: Brutal.hardShadow(offset: const Offset(3, 3)),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }

  /// عرض القاعدة: إيموجي + عنوان + شرح + تلميح للضغطة الجاية
  Widget _ruleView(double w) {
    final description = fillText(rule.description, {'player': game.currentPlayer.name});
    final hint = switch (rule.type) {
      RuleType.assign => UiText.tapToChoose,
      RuleType.free => UiText.tapToGive,
      RuleType.self => UiText.tapToTake,
      RuleType.cadu => UiText.tapNext,
      RuleType.bomb => UiText.tapStartBomb,
      RuleType.clap => UiText.tapToPickLoser,
      RuleType.silence => UiText.silenceHint,
    };
    final innerWidth = w * 0.86;

    return Column(
      children: [
        Expanded(
          child: Center(
            // لو الشرح طويل، المحتوى بيصغر تلقائياً عشان يدخل في الكارت
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: innerWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _emojiCircle(w, rule.emoji, w * 0.24),
                    SizedBox(height: w * 0.045),
                    Headline(game.t(rule.title), size: w * 0.095, align: TextAlign.center),
                    SizedBox(height: w * 0.025),
                    Text(
                      game.t(description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B2A2E),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: w * 0.02),
        _hintPill(w, game.t(hint)),
      ],
    );
  }

  /// لوحة اختيار الخسران جوه الكارت
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
            Headline(game.t(prompt), size: w * 0.075, align: TextAlign.center),
            // تحذير الكادو
            if (game.caduActive)
              Padding(
                padding: EdgeInsets.only(top: w * 0.015),
                child: Text(
                  game.t(fillText(UiText.caduWarn, {'n': game.caduCards.length})),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: AppColors.red),
                ),
              ),
            SizedBox(height: w * 0.045),
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
              SizedBox(height: w * 0.045),
              SizedBox(
                width: fullWidth,
                child: BrutalButton(
                  label: game.t(UiText.nobody),
                  onTap: game.pickNobody,
                  showArrow: false,
                  height: w * 0.13,
                  fontSize: w * 0.05,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// زرار باسم لاعب: دايرة بلونه + الاسم
  Widget _playerButton(double w, int index, double width) {
    final player = game.players[index];
    final initial = player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase();
    return GestureDetector(
      onTap: () => game.pickLoser(index),
      child: Container(
        width: width,
        height: w * 0.13,
        padding: EdgeInsets.symmetric(horizontal: w * 0.015),
        decoration: Brutal.box(borderWidth: 2, radius: 99, shadowOffset: const Offset(3, 3)),
        child: Row(
          children: [
            Container(
              width: w * 0.09,
              height: w * 0.09,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: player.color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 1.6),
              ),
              child: Text(initial, style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w800)),
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
      {required Widget emoji, required String title, String? subtitle, String? hint, Color titleColor = AppColors.ink}) {
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
                    emoji,
                    SizedBox(height: w * 0.06),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: w * 0.085, fontWeight: FontWeight.w800, color: titleColor),
                    ),
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
        if (hint != null) _hintPill(w, hint),
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
                width: w * 0.66,
                height: w * 0.66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow,
                  border: Border.all(color: AppColors.ink, width: 3),
                  boxShadow: Brutal.hardShadow(offset: const Offset(6, 6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👏', style: TextStyle(fontSize: w * 0.19)),
                    Text(
                      game.t(UiText.clapNow),
                      style: TextStyle(fontSize: w * 0.095, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
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

  /// تلميح تحت: زرار صغير أصفر مدوّر
  Widget _hintPill(double w, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.016),
      decoration: Brutal.box(color: AppColors.yellow, borderWidth: 2, radius: 99, shadowOffset: const Offset(2, 2)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
    );
  }
}
