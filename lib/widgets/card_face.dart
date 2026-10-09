// =================================================================
// شكل الكارت (وشه وضهره) - بيستخدمه الكارت الكبير في اللعبة
// وبيستخدمه كمان المعاينة اللايف في لوحة الأدمن، فاللي الأدمن بيشوفه هو بالظبط
// اللي اللاعيبة هيشوفوه.
// -----------------------------------------------------------------
// كل حاجة في الشكل بتيجي من بيانات الكارت (CardRule.design) ولو خانة فاضية
// بناخد الشكل الافتراضي من theme.dart (cardStyles).
// =================================================================
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/pixel_assets.dart';
import '../data/texts.dart';
import '../theme.dart';
import 'common.dart';

/// صورة من رابط (Supabase Storage) أو من base64 (الصور القديمة)
Widget imageFromRef(String ref, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  Widget broken() => SizedBox(width: width, height: height, child: Icon(Icons.broken_image, color: AppColors.muted));
  // أيقونة بيكسل جاهزة من مكتبة الصور: بتتكبر "بيكسل بيكسل" من غير تنعيم عشان تفضل حادة
  if (ref.startsWith(assetPrefix)) {
    return Image.asset(assetPath(ref), fit: fit, width: width, height: height, filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) => broken());
  }
  if (ref.startsWith('http')) {
    return Image.network(
      ref,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => broken(),
    );
  }
  try {
    return Image.memory(base64Decode(ref), fit: fit, width: width, height: height, gaplessPlayback: true);
  } catch (_) {
    return broken();
  }
}

/// الستيكر اللي الكارت هيستخدمه (من التصميم أو الافتراضي بتاع قيمته)
Sticker stickerFor(CardRule rule, String rank) {
  final name = rule.design.sticker;
  if (name != null) {
    for (final s in Sticker.values) {
      if (s.name == name) return s;
    }
  }
  return styleFor(rank).sticker;
}

/// ألوان الكارت النهائية (التصميم المخصص أو الافتراضي)
/// لون نص واضح فوق أي خلفية (غامق فوق الفاتح، وفاتح فوق الغامق)
Color readableOn(Color background) =>
    background.computeLuminance() > 0.45 ? const Color(0xFF3B2A2E) : const Color(0xFFF2F4F6);

class ResolvedCardColors {
  final Color bar, bg, text, border;
  const ResolvedCardColors(this.bar, this.bg, this.text, this.border);

  factory ResolvedCardColors.of(CardRule rule, String rank) {
    final style = styleFor(rank);
    final d = rule.design;
    // الوضع الغامق: شريط العنوان بيغمق شوية (زي الشبابيك في التصميم الغامق)
    final bar = d.bar != null ? Color(d.bar!) : style.color;
    final bg = d.bg != null ? Color(d.bg!) : style.tint;
    return ResolvedCardColors(
      AppColors.dark && d.bar == null ? Color.lerp(bar, Colors.black, 0.3)! : bar,
      bg,
      // لو الأدمن اختار خلفية بس من غير لون نص: نختار نص غامق أو فاتح حسب الخلفية عشان يتقري
      d.text != null ? Color(d.text!) : (d.bg != null ? readableOn(bg) : AppColors.ink),
      d.border != null ? Color(d.border!) : AppColors.ink,
    );
  }
}

// =================================================================
// وش الكارت: شباك بشريط عنوان + محتوى
// =================================================================
class CardFrontFace extends StatelessWidget {
  final double width, height;
  final String rank, suit;
  final CardRule rule;
  final Widget body; // المحتوى (عرض القاعدة، اختيار الخسران، القنبلة...)

  const CardFrontFace({
    super.key,
    required this.width,
    required this.height,
    required this.rank,
    required this.suit,
    required this.rule,
    required this.body,
  });

  bool get _isRed => suit == '♥' || suit == '♦';

  @override
  Widget build(BuildContext context) {
    final w = width;
    final colors = ResolvedCardColors.of(rule, rank);
    final d = rule.design;
    final dashed = d.borderStyle == 'dashed';
    final borderWidth = d.borderStyle == 'thick' ? 4.5 : 2.5;
    final suitColor = _isRed ? AppColors.red : AppColors.ink;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(Brutal.radius),
        border: dashed ? null : Border.all(color: colors.border, width: borderWidth),
        boxShadow: Brutal.hardShadow(offset: const Offset(6, 6)),
      ),
      foregroundDecoration: null,
      child: CustomPaint(
        foregroundPainter: dashed ? _DashedBorderPainter(colors.border) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titleBar(w, colors, suitColor, borderWidth),
            Expanded(
              child: Stack(
                children: [
                  // صورة خلفية الكارت (لو الأدمن رفع واحدة)
                  if (d.artworkUrl != null)
                    Positioned.fill(child: Opacity(opacity: d.artworkOpacity, child: imageFromRef(d.artworkUrl!))),
                  // نقشة خفيفة
                  if (d.pattern != 'none')
                    Positioned.fill(child: CustomPaint(painter: PatternPainter(d.pattern, colors.bar.withValues(alpha: 0.35)))),
                  // زينة: نقط فوق على اليمين ونجمة تحت على الشمال
                  Positioned(top: w * 0.03, right: w * 0.04, child: const DotGrid(columns: 4, rows: 3)),
                  Positioned(bottom: w * 0.03, left: w * 0.04, child: StickerImage(Sticker.sparkle, size: w * 0.07)),
                  // الركن اللي تحت على اليمين (مقلوب)
                  Positioned(
                    bottom: w * 0.025,
                    right: w * 0.045,
                    child: Transform.rotate(angle: pi, child: _corner(w, suitColor)),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.05, w * 0.06, w * 0.13),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBar(double w, ResolvedCardColors colors, Color suitColor, double borderWidth) {
    final barH = w * 0.12;
    final iconSize = barH * 0.36;
    return Container(
      height: barH,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(bottom: BorderSide(color: colors.border, width: borderWidth)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Text(rank, textDirection: TextDirection.ltr, style: rankStyle(size: barH * 0.62)),
          SizedBox(width: w * 0.015),
          Text(suit, style: TextStyle(fontSize: barH * 0.55, color: suitColor, height: 1)),
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

  Widget _corner(double w, Color suitColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rank, textDirection: TextDirection.ltr, style: rankStyle(size: w * 0.075)),
        Text(suit, style: TextStyle(fontSize: w * 0.06, color: suitColor, height: 1)),
      ],
    );
  }
}

/// عرض القاعدة على وش الكارت: الأيقونة + العنوان + السطر الصغير + الشرح + زرار الضغطة الجاية
class RuleBody extends StatelessWidget {
  final double width;
  final String rank;
  final CardRule rule;
  final String title;
  final String? subtitle;
  final String description;
  final String hint;

  const RuleBody({
    super.key,
    required this.width,
    required this.rank,
    required this.rule,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final d = rule.design;
    final colors = ResolvedCardColors.of(rule, rank);
    final start = d.align == 'start';
    final textAlign = start ? TextAlign.start : TextAlign.center;
    final iconSize = w * 0.28 * d.iconScale;
    final background = d.iconPos == 'background';

    // الأيقونة: مرفوعة من الأدمن أو ستيكر
    Widget icon(double size) => d.iconUrl != null
        ? imageFromRef(d.iconUrl!, fit: BoxFit.contain, width: size, height: size)
        : StickerImage(stickerFor(rule, rank), size: size);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (!background)
          SizedBox(
            width: max(iconSize, w * 0.2) + w * 0.06,
            height: iconSize + w * 0.02,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                icon(iconSize),
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
        if (background) Text(rule.emoji, style: TextStyle(fontSize: w * 0.12)),
        SizedBox(height: w * 0.035),
        Text(title, textAlign: textAlign, style: pixelStyle(size: w * 0.09, color: colors.text)),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: w * 0.01),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: colors.text.withValues(alpha: 0.75)),
          ),
        ],
        SizedBox(height: w * 0.025),
        Text(
          description,
          textAlign: textAlign,
          style: TextStyle(fontSize: w * 0.05, fontWeight: FontWeight.w600, color: colors.text, height: 1.45),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // أيقونة كبيرة وباهتة ورا الكلام
              if (background) Center(child: Opacity(opacity: 0.18, child: icon(w * 0.6 * d.iconScale))),
              Align(
                alignment: start ? AlignmentDirectional.centerStart : Alignment.center,
                // لو الشرح طويل، المحتوى بيصغر تلقائياً عشان يدخل في الكارت
                child: FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: w * 0.88, child: content)),
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.03),
        OkButton(w: w, text: hint),
      ],
    );
  }
}

// =================================================================
// ضهر الكارت
// =================================================================
class CardBackFace extends StatelessWidget {
  final double width, height;
  final int deckLeft, deckTotal;
  final CardCategory category; // عادي ولا أكشن (من غير ما نكشف هو أنهي كارت)
  final int? backColor;        // لون مخصص من الأدمن
  final String backPattern;    // auto / dots / stripes / grid
  final String? titleOnBack;   // عنوان يظهر على الضهر (لو الأدمن اختار كده)
  final String cardsLeftLabel;
  final String tapLabel;
  final String actionLabel;

  const CardBackFace({
    super.key,
    required this.width,
    required this.height,
    required this.deckLeft,
    required this.deckTotal,
    required this.category,
    required this.cardsLeftLabel,
    required this.tapLabel,
    required this.actionLabel,
    this.backColor,
    this.backPattern = 'auto',
    this.titleOnBack,
  });

  /// لون ضهر كروت الأكشن (بمبي فاتح دافي عشان يتميز عن الأزرق العادي)
  static Color get actionBackColor => AppColors.dark ? const Color(0xFF3A211B) : const Color(0xFFFBD9CF);

  @override
  Widget build(BuildContext context) {
    final w = width;
    final action = category != CardCategory.normal;
    final bg = backColor != null ? Color(backColor!) : (action ? actionBackColor : AppColors.bg);
    // النقشة: الأكشن خطوط مايلة خفيفة، والعادي مربعات الكراسة
    final pattern = backPattern != 'auto' ? backPattern : (action ? 'stripes' : 'grid');

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(color: bg, borderWidth: 2.5, shadowOffset: const Offset(6, 6)),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PatternPainter(pattern, action ? AppColors.orange.withValues(alpha: 0.22) : AppColors.gridLine,
                  cell: w / 14),
            ),
          ),
          Column(
            children: [
              // علامة "أكشن" صغيرة فوق (بتقول إنه كارت أكشن بس، مش بتقول هو أنهي)
              if (action)
                Padding(
                  padding: EdgeInsets.only(top: w * 0.035),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.006),
                    decoration: Brutal.box(color: AppColors.orange, borderWidth: 2, shadowOffset: const Offset(2, 2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StickerImage(Sticker.sparkle, size: w * 0.05),
                        SizedBox(width: w * 0.012),
                        Text(actionLabel, style: pixelStyle(size: w * 0.04)),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.1, w * (action ? 0.03 : 0.07), w * 0.1, w * 0.02),
                  child: Image.asset(AppTheme.logo, fit: BoxFit.contain),
                ),
              ),
              if (titleOnBack != null)
                Padding(
                  padding: EdgeInsets.only(bottom: w * 0.02),
                  child: Text(titleOnBack!, textAlign: TextAlign.center, style: pixelStyle(size: w * 0.055)),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                child: LoadingWindow(w: w, left: deckLeft, total: deckTotal, label: cardsLeftLabel),
              ),
              SizedBox(height: w * 0.05),
              Pulse(scale: 1.06, child: OkButton(w: w, text: tapLabel)),
              SizedBox(height: w * 0.07),
            ],
          ),
        ],
      ),
    );
  }
}

/// زرار شكل "OK" القديم: كريمي بحدود ونقط من جوه، وجنبه سهم الماوس
class OkButton extends StatelessWidget {
  final double w;
  final String text;
  const OkButton({super.key, required this.w, required this.text});

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
        Positioned(right: -w * 0.03, bottom: -w * 0.045, child: StickerImage(Sticker.cursor, size: w * 0.07)),
      ],
    );
  }
}

/// شباك صغير برتقالي فيه شريط تحميل = الكروت الباقية
class LoadingWindow extends StatelessWidget {
  final double w;
  final int left, total;
  final String label;
  const LoadingWindow({super.key, required this.w, required this.left, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    const segments = 16;
    final safeTotal = max(total, left);
    final filled = safeTotal == 0 ? 0 : (left / safeTotal * segments).ceil();
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

/// نقشات الخلفية: dots / grid / stripes
class PatternPainter extends CustomPainter {
  final String pattern;
  final Color color;
  final double cell;
  const PatternPainter(this.pattern, this.color, {this.cell = 22});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    switch (pattern) {
      case 'grid':
        for (double x = cell; x < size.width; x += cell) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = cell; y < size.height; y += cell) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;
      case 'dots':
        for (double x = cell / 2; x < size.width; x += cell) {
          for (double y = cell / 2; y < size.height; y += cell) {
            canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 3, height: 3), paint);
          }
        }
        break;
      case 'stripes':
        paint.strokeWidth = cell * 0.35;
        for (double x = -size.height; x < size.width; x += cell * 1.4) {
          canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter old) => old.pattern != pattern || old.color != color || old.cell != cell;
}

/// إطار نقط من جوه زرار "OK"
class _DottedBorderPainter extends CustomPainter {
  final bool dark = AppColors.dark;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => (oldDelegate as _DottedBorderPainter).dark != dark;
}

/// حدود متقطعة للكارت (لو الأدمن اختار "dashed")
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const dash = 9.0, gap = 6.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Brutal.radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, min(d + dash, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

// =================================================================
// زرار التصفيق (التسقيف): شكله جاي من إعدادات الكارت (الأدمن بيغيّره من المحرر)
// =================================================================
class ClapButtonView extends StatelessWidget {
  final double w;              // عرض الكارت (كل المقاسات نسبة منه)
  final ClapButtonStyle style;
  final String defaultText;    // "صقّف!" باللغة الحالية لو الأدمن ماكتبش كلام
  final String Function(LText) translate;
  final bool enabled;          // false = شكل باهت (التصفيق مقفول أو صقّفت خلاص)
  final String? overrideText;  // كلام بدل كلام الزرار (مثلاً "✔ صقّفت!")

  const ClapButtonView({
    super.key,
    required this.w,
    required this.style,
    required this.defaultText,
    required this.translate,
    this.enabled = true,
    this.overrideText,
  });

  @override
  Widget build(BuildContext context) {
    final factor = switch (style.size) { 's' => 0.42, 'm' => 0.53, _ => 0.64 };
    final width = w * factor;
    final circle = style.shape == 'circle';
    final height = circle || style.shape == 'square' ? width : width * 0.46;
    final bg = style.bg != null ? Color(style.bg!) : AppColors.yellow;
    final fg = style.fg != null ? Color(style.fg!) : (style.bg != null ? readableOn(bg) : AppColors.ink);
    final text = overrideText ?? (style.text == null ? defaultText : translate(style.text!));
    final radius = switch (style.shape) {
      'pill' => BorderRadius.circular(height),
      'square' => BorderRadius.circular(4),
      'rounded' => BorderRadius.circular(style.radius),
      _ => null,
    };
    final horizontal = !circle && style.shape != 'square';

    final label = Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: pixelStyle(size: width * 0.13, color: fg));
    final icon = Text(style.icon, style: TextStyle(fontSize: width * (horizontal ? 0.16 : 0.28)));

    Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
        decoration: BoxDecoration(
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: radius,
          color: bg,
          border: style.border ? Border.all(color: AppColors.ink, width: 3) : null,
          boxShadow: style.border && enabled ? Brutal.hardShadow(offset: const Offset(6, 6)) : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: horizontal
              ? Row(mainAxisSize: MainAxisSize.min, children: [icon, SizedBox(width: width * 0.04), label])
              : Column(mainAxisSize: MainAxisSize.min, children: [icon, label]),
        ),
      ),
    );
    if (style.animate && enabled) {
      button = Pulse(scale: 1.06, duration: const Duration(milliseconds: 300), child: button);
    }
    return button;
  }

  /// مكان الزرار جوه الكارت
  Alignment get alignment => switch (style.position) {
        'top' => Alignment.topCenter,
        'bottom' => Alignment.bottomCenter,
        _ => Alignment.center,
      };
}
