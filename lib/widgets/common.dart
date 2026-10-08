// =================================================================
// عناصر واجهة مشتركة بتستخدمها كل الشاشات (ستايل Playful Geometric)
// =================================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';

/// خلفية التطبيق: كريمي + نقط في الخلفية كلها + أشكال هندسية خفيفة في الأركان
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          // النقط
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DotsPainter()))),
          // أشكال هندسية في الأركان
          Positioned(top: 90, right: -18, child: Transform.rotate(angle: 0.3, child: _shape(AppColors.sky, 46, circle: false))),
          Positioned(bottom: 120, left: -20, child: _shape(AppColors.red, 54, circle: true)),
          const Positioned(top: 200, left: 14, child: ShapeAccent(size: 12)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _shape(Color color, double size, {required bool circle}) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          border: Border.all(color: AppColors.ink, width: 2),
        ),
      ),
    );
  }
}

/// نقط صغيرة منتظمة في الخلفية كلها
class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.13);
    const gap = 18.0;
    for (double x = gap / 2; x < size.width; x += gap) {
      for (double y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// شبكة نقط صغيرة للزينة
class DotGrid extends StatelessWidget {
  final int columns;
  final int rows;
  final double gap;
  const DotGrid({super.key, this.columns = 4, this.rows = 4, this.gap = 8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: columns * gap,
      height: rows * gap,
      child: CustomPaint(painter: _DotPainter(columns, rows, gap)),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int columns, rows;
  final double gap;
  _DotPainter(this.columns, this.rows, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.6);
    for (var x = 0; x < columns; x++) {
      for (var y = 0; y < rows; y++) {
        canvas.drawCircle(Offset(x * gap + gap / 2, y * gap + gap / 2), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// علامة زينة: مربع أحمر صغير عليه علامة + (زي التصميم)
class ShapeAccent extends StatelessWidget {
  final double size;
  final Color color;
  const ShapeAccent({super.key, this.size = 14, this.color = AppColors.red});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.4,
      height: size * 2.4,
      child: CustomPaint(painter: _AccentPainter(color, size)),
    );
  }
}

class _AccentPainter extends CustomPainter {
  final Color color;
  final double s;
  _AccentPainter(this.color, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawRect(Rect.fromCenter(center: c, width: s, height: s), Paint()..color = color);
    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), line);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// شريط أشكال هندسية ملونة (دواير ومثلثات ومربعات) - بيتحط تحت الشاشات والكروت
class ShapesStrip extends StatelessWidget {
  final double height;
  const ShapesStrip({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _StripPainter()),
    );
  }
}

class _StripPainter extends CustomPainter {
  static const _colors = [AppColors.yellow, AppColors.sky, AppColors.red, AppColors.green, AppColors.violet];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height * 0.7;          // مقاس الشكل
    final step = size.height * 1.6;       // المسافة بين الأشكال
    final y = size.height / 2;
    final border = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.height * 0.09);
    var i = 0;
    for (double x = step / 2; x < size.width; x += step, i++) {
      final fill = Paint()..color = _colors[i % _colors.length];
      final c = Offset(x, y);
      switch (i % 3) {
        case 0:
          canvas.drawCircle(c, s / 2, fill);
          canvas.drawCircle(c, s / 2, border);
          break;
        case 1:
          final path = Path()
            ..moveTo(c.dx, c.dy - s / 2)
            ..lineTo(c.dx + s / 2, c.dy + s / 2)
            ..lineTo(c.dx - s / 2, c.dy + s / 2)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, border);
          break;
        default:
          final r = Rect.fromCenter(center: c, width: s, height: s);
          canvas.drawRect(r, fill);
          canvas.drawRect(r, border);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// صندوق مدوّر بحدود سودا وظل صلب
class BrutalBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const BrutalBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.paper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: Brutal.box(color: color), child: child);
  }
}

/// الزرار الكبير: أصفر مدوّر + دايرة سودا فيها سهم (زي "I'm Done!")
class BrutalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool showArrow;
  final double height;
  final double fontSize;
  const BrutalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.yellow,
    this.showArrow = true,
    this.height = 58,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        height: height,
        // لما تدوس الزرار بينزل مكان الظل كأنه اتضغط فعلاً
        transform: Matrix4.translationValues(pressed ? 3 : 0, pressed ? 3 : 0, 0),
        padding: EdgeInsets.symmetric(horizontal: height * 0.16),
        decoration: Brutal.box(
          color: color,
          radius: height * 0.32,
          shadowOffset: pressed ? const Offset(1, 1) : Brutal.shadow,
        ),
        child: Row(
          children: [
            if (showArrow) SizedBox(width: height * 0.62),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
            ),
            if (showArrow)
              Container(
                width: height * 0.62,
                height: height * 0.62,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                // arrow_forward بيتقلب لوحده في العربي فيشاور شمال (اتجاه القراءة)
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: height * 0.38),
              ),
          ],
        ),
      ),
    );
  }
}

/// زرار صغير مدوّر بحدود سودا (للشريط العلوي)
class SquareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  const SquareButton({super.key, required this.child, this.onTap, this.color = AppColors.paper});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 40,
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        transform: Matrix4.translationValues(pressed ? 2 : 0, pressed ? 2 : 0, 0),
        decoration: Brutal.box(
          color: color,
          borderWidth: 2,
          radius: 14,
          shadowOffset: pressed ? Offset.zero : const Offset(2, 2),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
          child: IconTheme.merge(data: const IconThemeData(color: AppColors.ink, size: 20), child: child),
        ),
      ),
    );
  }
}

/// مفتاح تبديل اللغة: عربي | Franco
class LangToggle extends StatelessWidget {
  final GameController game;
  const LangToggle({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, AppLang value) {
      final active = game.lang == value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: active ? Border.all(color: AppColors.ink, width: 1.6) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      );
    }

    return GestureDetector(
      onTap: game.toggleLang,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: Brutal.box(borderWidth: 2, radius: 99, shadowOffset: const Offset(2, 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr, // ترتيب ثابت مهما كانت اللغة
          children: [segment('عربي', AppLang.ar), segment('Franco', AppLang.franco)],
        ),
      ),
    );
  }
}

/// عنوان كبير (زي "Sepideh just finished her challenge")
class Headline extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const Headline(this.text, {super.key, this.size = 34, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.15,
      ),
    );
  }
}

/// يكبّر ويصغّر العنصر بشكل متكرر (نبض) - بنستخدمه للتنبيه
class Pulse extends StatefulWidget {
  final Widget child;
  final bool enabled;      // لو false يظهر العنصر عادي من غير نبض
  final double scale;      // أقصى تكبير
  final Duration duration; // سرعة النبضة
  const Pulse({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 1.06,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    // تشغيل/إيقاف النبض لما الخاصية enabled تتغير
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      // RepaintBoundary: النبض بيكبّر صورة جاهزة بدل ما يعيد رسم العنصر كل فريم
      child: RepaintBoundary(child: widget.child),
    );
  }
}

/// يعرف إذا كان الزرار مضغوط دلوقتي (عشان حركة "الضغط" على الظل)
class _Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(bool pressed) builder;
  const _Pressable({required this.onTap, required this.builder});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap != null && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: widget.builder(_pressed),
    );
  }
}
