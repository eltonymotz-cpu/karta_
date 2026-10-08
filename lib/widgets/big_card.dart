// =================================================================
// الكارت الكبير: أهم عنصر في اللعبة
// -----------------------------------------------------------------
// - ضهر الكارت: لوجو كارتة + عدد الكروت الباقية
// - وش الكارت: القيمة والشكل في الأركان + القاعدة في النص
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
        final w = min(
          constraints.maxWidth - shadow,
          (constraints.maxHeight - shadow) * 5 / 7,
        );
        final h = w * 7 / 5;

        final card = game.currentCard;
        // مفتاح الوش: لما يتغير، الكارت بيتقلب
        final faceKey = card == null ? 'back' : 'front-${card.label}';

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
                  switchInCurve: const Interval(
                    0.5,
                    1,
                    curve: Curves.easeOutCubic,
                  ),
                  switchOutCurve: const Interval(
                    0.5,
                    1,
                    curve: Curves.easeInCubic,
                  ),
                  transitionBuilder: (child, animation) =>
                      _flipTransition(child, animation, faceKey),
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
                      child: card == null
                          ? _CardBack(
                              width: w,
                              deckCount: game.deck.length,
                              game: game,
                            )
                          : _CardFront(
                              width: w,
                              card: card,
                              rule: game.currentRule!,
                              phase: game.phase,
                              game: game,
                            ),
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
  Widget _flipTransition(
    Widget child,
    Animation<double> animation,
    String currentKey,
  ) {
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

/// إطار الكارت: أبيض بحدود سودا تقيلة وظل صلب
class _CardFrame extends StatelessWidget {
  final double width, height;
  final Widget child;
  const _CardFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: Brutal.box(
        borderWidth: 3,
        shadowOffset: const Offset(6, 6),
        radius: width * 0.04,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.04 - 3),
        child: child,
      ),
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
  const _CardBack({
    required this.width,
    required this.deckCount,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Stack(
      fit: StackFit.expand,
      children: [
        // زينة: نقط ومربعات في الأركان
        Positioned(
          top: w * 0.05,
          right: w * 0.05,
          child: const DotGrid(columns: 4, rows: 3),
        ),
        Positioned(
          top: w * 0.05,
          left: w * 0.05,
          child: const CheckerSquares(size: 11),
        ),
        Positioned(
          bottom: w * 0.1,
          right: w * 0.05,
          child: const CheckerSquares(size: 11),
        ),
        Positioned(
          bottom: w * 0.1,
          left: w * 0.05,
          child: const DotGrid(columns: 3, rows: 3),
        ),
        // عدد الكروت الباقية فوق
        Positioned(
          top: w * 0.05,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.035,
                vertical: w * 0.012,
              ),
              color: AppColors.ink,
              child: Text(
                '$deckCount ${game.t(UiText.cardsLeft)}'.toUpperCase(),
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w900,
                  color: AppColors.yellow,
                ),
              ),
            ),
          ),
        ),
        // اللوجو في النص
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.08, w * 0.17, w * 0.08, w * 0.3),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        // "دوس اسحب"
        Positioned(
          bottom: w * 0.1,
          left: 0,
          right: 0,
          child: Center(
            child: Pulse(
              scale: 1.07,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06,
                  vertical: w * 0.02,
                ),
                decoration: Brutal.box(
                  color: AppColors.yellow,
                  shadowOffset: const Offset(3, 3),
                ),
                child: Text(
                  game.t(UiText.tapToDraw).toUpperCase(),
                  style: TextStyle(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        // شريط التحذير تحت
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HazardStripes(height: w * 0.045),
        ),
      ],
    );
  }
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

  // لون الكارت: الأحمر للقلب والديناري، والأسود للباقي
  Color get suitColor => card.isRed ? AppColors.red : AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Stack(
      children: [
        // شكل الكارت كبير وباهت في الخلفية
        Positioned.fill(
          child: Center(
            child: Text(
              card.suit,
              style: TextStyle(
                fontSize: w * 0.95,
                color: suitColor.withValues(alpha: 0.05),
                height: 1,
              ),
            ),
          ),
        ),
        Positioned(
          top: w * 0.05,
          right: w * 0.05,
          child: const DotGrid(columns: 4, rows: 3),
        ),
        // الركن اللي فوق على الشمال
        Positioned(top: w * 0.035, left: w * 0.05, child: _corner(w)),
        // الركن اللي تحت على اليمين (مقلوب)
        Positioned(
          bottom: w * 0.065,
          right: w * 0.05,
          child: Transform.rotate(angle: pi, child: _corner(w)),
        ),
        // شريط التحذير تحت
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HazardStripes(height: w * 0.035),
        ),
        // محتوى الكارت (بيتغير حسب المرحلة بحركة سريعة)
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.21, w * 0.06, w * 0.2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(phase), child: _content(w)),
            ),
          ),
        ),
      ],
    );
  }

  /// الركن: القيمة وتحتها الشكل
  Widget _corner(double w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rank,
          style: TextStyle(
            fontSize: w * 0.11,
            fontWeight: FontWeight.w900,
            color: suitColor,
            height: 1,
          ),
        ),
        Text(
          card.suit,
          style: TextStyle(fontSize: w * 0.08, color: suitColor, height: 1.1),
        ),
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
          emoji: Pulse(
            scale: 1.15,
            duration: const Duration(milliseconds: 500),
            child: _emojiBox(w, '💣', w * 0.3),
          ),
          title: game.t(UiText.passPhone),
          subtitle: game.t(UiText.anyMoment),
        );
      case CardPhase.bombExploded:
        return _bigMessage(
          w,
          emoji: _emojiBox(w, '💥', w * 0.34, color: AppColors.red),
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

  /// مربع أصفر بحدود سودا فيه إيموجي (زي صورة البروفايل في التصميم)
  Widget _emojiBox(
    double w,
    String emoji,
    double size, {
    Color color = AppColors.yellow,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: Brutal.box(color: color, shadowOffset: const Offset(4, 4)),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.58)),
    );
  }

  /// عرض القاعدة: إيموجي + عنوان + شرح + تلميح للضغطة الجاية
  Widget _ruleView(double w) {
    final description = fillText(rule.description, {
      'player': game.currentPlayer.name,
    });
    final hint = switch (rule.type) {
      RuleType.assign => UiText.tapToChoose,
      RuleType.free => UiText.tapToGive,
      RuleType.self => UiText.tapToTake,
      RuleType.cadu => UiText.tapNext,
      RuleType.bomb => UiText.tapStartBomb,
      RuleType.clap => UiText.tapToPickLoser,
      RuleType.silence => UiText.silenceHint,
    };
    final innerWidth = w * 0.88;

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
                    _emojiBox(w, rule.emoji, w * 0.22),
                    SizedBox(height: w * 0.05),
                    Headline(
                      game.t(rule.title),
                      size: w * 0.1,
                      align: TextAlign.center,
                    ),
                    SizedBox(height: w * 0.03),
                    Text(
                      game.t(description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A2A2A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: w * 0.02),
        _hintBar(w, game.t(hint)),
      ],
    );
  }

  /// لوحة اختيار الخسران جوه الكارت
  Widget _choosePanel(double w) {
    final prompt = rule.prompt ?? UiText.tapToPickLoser;
    final gap = w * 0.03;

    // LayoutBuilder بيدينا العرض الحقيقي المتاح، فنقسمه على عمودين بالظبط
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth - 4; // نسيب مكان للظل
        final buttonWidth = (fullWidth - gap) / 2 - 1;
        return SingleChildScrollView(
          child: Column(
            children: [
              Headline(
                game.t(prompt),
                size: w * 0.075,
                align: TextAlign.center,
              ),
              // تحذير الكادو
              if (game.caduActive)
                Padding(
                  padding: EdgeInsets.only(top: w * 0.015),
                  child: Text(
                    game.t(
                      fillText(UiText.caduWarn, {'n': game.caduCards.length}),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                ),
              SizedBox(height: w * 0.045),
              // زرار لكل لاعب
              Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < game.players.length; i++)
                    _playerButton(w, i, buttonWidth),
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
      },
    );
  }

  /// زرار باسم لاعب: مربع بلونه + الاسم
  Widget _playerButton(double w, int index, double width) {
    final player = game.players[index];
    return GestureDetector(
      onTap: () => game.pickLoser(index),
      child: Container(
        width: width,
        height: w * 0.13,
        decoration: Brutal.box(
          borderWidth: 2,
          shadowOffset: const Offset(3, 3),
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.06,
              decoration: BoxDecoration(
                color: player.color,
                border: const BorderDirectional(
                  end: BorderSide(color: AppColors.ink, width: 2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// رسالة كبيرة في نص الكارت (للقنبلة)
  Widget _bigMessage(
    double w, {
    required Widget emoji,
    required String title,
    String? subtitle,
    String? hint,
    Color titleColor = AppColors.ink,
  }) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: w * 0.88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    emoji,
                    SizedBox(height: w * 0.06),
                    Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w * 0.085,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: w * 0.02),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.05,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hint != null) _hintBar(w, hint),
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
                      game.t(UiText.clapNow).toUpperCase(),
                      style: TextStyle(
                        fontSize: w * 0.095,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
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
          style: TextStyle(
            fontSize: w * 0.045,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  /// تلميح تحت: شريط أسود والكلام أصفر
  Widget _hintBar(double w, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.018),
      color: AppColors.ink,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: w * 0.038,
          fontWeight: FontWeight.w900,
          color: AppColors.yellow,
        ),
      ),
    );
  }
}
