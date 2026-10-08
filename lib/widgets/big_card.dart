// =================================================================
// الكارت الكبير: أهم عنصر في اللعبة
// -----------------------------------------------------------------
// - ضهر الكارت: لوجو كارتة + شريط "Loading" فيه الكروت الباقية
// - وش الكارت: شباك كمبيوتر قديم، كل قيمة ليها لون وستيكر مختلف (cardStyles في theme.dart)
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
        final w = min(constraints.maxWidth - shadow, (constraints.maxHeight - shadow) * 5 / 7);
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
                    // من غير ما نعيد رسم الكلام والستيكرز في كل فريم (ده سر النعومة)
                    child: RepaintBoundary(
                      child: card == null
                          ? _CardBack(width: w, height: h, game: game)
                          : _CardFront(
                              width: w,
                              height: h,
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

/// زرار شكل "OK" القديم: كريمي بحدود ونقط من جوه، وجنبه سهم الماوس
class _OkButton extends StatelessWidget {
  final double w;
  final String text;
  const _OkButton({required this.w, required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.012),
          decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
          child: CustomPaint(
            painter: _DottedBorderPainter(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.016),
              child: Text(text, textAlign: TextAlign.center, style: pixelStyle(size: w * 0.042)),
            ),
          ),
        ),
        // سهم الماوس على الركن
        Positioned(right: -w * 0.03, bottom: -w * 0.045, child: StickerImage(Sticker.cursor, size: w * 0.07)),
      ],
    );
  }
}

/// إطار نقط من جوه زرار "OK"
class _DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    const step = 5.0, dot = 1.6;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, dot, dot), paint);
      canvas.drawRect(Rect.fromLTWH(x, size.height - dot, dot, dot), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, dot, dot), paint);
      canvas.drawRect(Rect.fromLTWH(size.width - dot, y, dot, dot), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =================================================================
// ضهر الكارت
// =================================================================
class _CardBack extends StatelessWidget {
  final double width, height;
  final GameController game;
  const _CardBack({required this.width, required this.height, required this.game});

  @override
  Widget build(BuildContext context) {
    final w = width;
    final left = game.deck.length;
    final total = max(left, GameController.deckSize(game.modeId));
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(color: AppColors.bg, borderWidth: 2.5, shadowOffset: const Offset(6, 6)),
      child: Stack(
        children: [
          // مربعات الكراسة
          const Positioned.fill(child: CustomPaint(painter: _CardGridPainter())),
          Column(
            children: [
              // اللوجو
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.1, w * 0.07, w * 0.1, w * 0.02),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              // شباك "Loading" فيه الكروت الباقية
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                child: _LoadingWindow(w: w, left: left, total: total, label: game.t(UiText.cardsLeft)),
              ),
              SizedBox(height: w * 0.05),
              // "دوس اسحب"
              Pulse(scale: 1.06, child: _OkButton(w: w, text: game.t(UiText.tapToDraw))),
              SizedBox(height: w * 0.07),
            ],
          ),
        ],
      ),
    );
  }
}

/// شباك صغير برتقالي فيه شريط تحميل = الكروت الباقية
class _LoadingWindow extends StatelessWidget {
  final double w;
  final int left, total;
  final String label;
  const _LoadingWindow({required this.w, required this.left, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    const segments = 16;
    final filled = total == 0 ? 0 : (left / total * segments).ceil();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowBar(title: '', color: AppColors.orange, height: w * 0.07),
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.015, w * 0.03, w * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$left $label...', style: pixelStyle(size: w * 0.04, weight: FontWeight.w500)),
                SizedBox(height: w * 0.012),
                // شريط مقسوم مربعات زرقا (زي Loading...)
                Container(
                  height: w * 0.05,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.ink, width: 1.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      for (var i = 0; i < segments; i++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.8),
                            color: i < filled ? AppColors.blue : Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// مربعات الكراسة على ضهر الكارت
class _CardGridPainter extends CustomPainter {
  const _CardGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1.6;
    final cell = size.width / 14;
    for (double x = cell; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = cell; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =================================================================
// وش الكارت: شباك بلون الكارت
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

  // شكل الكارت: لون وستيكر خاصين بقيمة الكارت
  CardStyle get style => styleFor(card.rank);

  // لون رمز الكارت: أحمر للقلب والديناري، وغامق للباقي
  Color get suitColor => card.isRed ? AppColors.red : AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(color: style.tint, borderWidth: 2.5, shadowOffset: const Offset(6, 6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط العنوان: قيمة الكارت وشكله + _ □ ✕
          _titleBar(w),
          Expanded(
            child: Stack(
              children: [
                // زينة: نقط فوق على اليمين ونجمة تحت على الشمال
                Positioned(top: w * 0.03, right: w * 0.04, child: const DotGrid(columns: 4, rows: 3)),
                Positioned(bottom: w * 0.03, left: w * 0.04, child: StickerImage(Sticker.sparkle, size: w * 0.07)),
                // الركن اللي تحت على اليمين (مقلوب)
                Positioned(
                  bottom: w * 0.025,
                  right: w * 0.045,
                  child: Transform.rotate(angle: pi, child: _corner(w)),
                ),
                // محتوى الكارت (بيتغير حسب المرحلة بحركة سريعة)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.05, w * 0.06, w * 0.13),
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
            ),
          ),
        ],
      ),
    );
  }

  /// شريط العنوان بلون الكارت
  Widget _titleBar(double w) {
    final barH = w * 0.12;
    final iconSize = barH * 0.36;
    return Container(
      height: barH,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      decoration: BoxDecoration(
        color: style.color,
        border: const Border(bottom: BorderSide(color: AppColors.ink, width: 2.5)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          // القيمة والشكل
          Text(card.rank, style: pixelStyle(size: barH * 0.62)),
          SizedBox(width: w * 0.015),
          Text(card.suit, style: TextStyle(fontSize: barH * 0.55, color: suitColor, height: 1)),
          const Spacer(),
          Container(width: iconSize, height: 2.4, margin: EdgeInsets.only(top: iconSize * 0.8), color: AppColors.ink),
          SizedBox(width: iconSize * 0.7),
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(border: Border.all(color: AppColors.ink, width: 2)),
          ),
          SizedBox(width: iconSize * 0.7),
          Icon(Icons.close, size: iconSize * 1.35, color: AppColors.ink),
        ],
      ),
    );
  }

  /// الركن: القيمة وتحتها الشكل
  Widget _corner(double w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(card.rank, style: pixelStyle(size: w * 0.075)),
        Text(card.suit, style: TextStyle(fontSize: w * 0.06, color: suitColor, height: 1)),
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
          hero: Pulse(
            scale: 1.15,
            duration: const Duration(milliseconds: 450),
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
          hint: game.t(UiText.tapToPickLoser),
        );
      case CardPhase.clapGo:
        return _clapButton(w);
      case CardPhase.front:
      case CardPhase.back:
        return _ruleView(w);
    }
  }

  /// عرض القاعدة: ستيكر الكارت + عنوان + شرح + زرار للضغطة الجاية
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

    return Column(
      children: [
        Expanded(
          child: Center(
            // لو الشرح طويل، المحتوى بيصغر تلقائياً عشان يدخل في الكارت
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: w * 0.88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الستيكر الكبير + إيموجي القاعدة في ركنه
                    SizedBox(
                      width: w * 0.36,
                      height: w * 0.3,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          StickerImage(style.sticker, size: w * 0.28),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(w * 0.01),
                              decoration: Brutal.box(color: AppColors.paper, borderWidth: 2, shadowOffset: const Offset(2, 2)),
                              child: Text(rule.emoji, style: TextStyle(fontSize: w * 0.06)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.035),
                    Headline(game.t(rule.title), size: w * 0.09, align: TextAlign.center),
                    SizedBox(height: w * 0.025),
                    Text(
                      game.t(description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: w * 0.03),
        _OkButton(w: w, text: game.t(hint)),
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
        if (hint != null) _OkButton(w: w, text: hint),
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
