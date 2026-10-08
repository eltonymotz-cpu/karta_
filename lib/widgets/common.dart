// =================================================================
// عناصر واجهة مشتركة بتستخدمها كل الشاشات (ستايل Neo-Brutalism)
// =================================================================
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';

/// خلفية التطبيق: كريمي + نقط ومربعات زينة في الأركان
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          // نقط فوق على اليمين وتحت على الشمال
          const Positioned(top: 70, right: 14, child: DotGrid(columns: 5, rows: 4)),
          const Positioned(bottom: 90, left: 12, child: DotGrid(columns: 4, rows: 4)),
          // مربعات أسود وأصفر (زي الشطرنج)
          const Positioned(top: 150, left: 10, child: CheckerSquares(size: 12)),
          const Positioned(bottom: 170, right: 12, child: CheckerSquares(size: 12)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
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
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.55);
    for (var x = 0; x < columns; x++) {
      for (var y = 0; y < rows; y++) {
        canvas.drawCircle(Offset(x * gap + gap / 2, y * gap + gap / 2), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// مربعين متقاطعين: أسود وأصفر (علامة مميزة للستايل)
class CheckerSquares extends StatelessWidget {
  final double size;
  const CheckerSquares({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Container(width: size, height: size, color: AppColors.ink)),
          Positioned(left: 0, bottom: 0, child: Container(width: size, height: size, color: AppColors.yellow)),
        ],
      ),
    );
  }
}

/// شريط خطوط مايلة أسود وأبيض (زي شريط التحذير)
class HazardStripes extends StatelessWidget {
  final double height;
  final Color color;
  const HazardStripes({super.key, this.height = 14, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _StripePainter(color)),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  _StripePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final stripe = size.height * 1.1; // عرض الشريطة
    for (double x = -size.height; x < size.width + size.height; x += stripe * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripe, 0)
        ..lineTo(x + stripe, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// صندوق أبيض بحدود سودا وظل صلب
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

/// الزرار الكبير: أصفر + مربع أسود فيه سهم (زي "CONTINUE →")
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
        duration: const Duration(milliseconds: 80),
        height: height,
        // لما تدوس الزرار بينزل مكان الظل كأنه اتضغط فعلاً
        transform: Matrix4.translationValues(pressed ? 3 : 0, pressed ? 3 : 0, 0),
        decoration: Brutal.box(color: color, shadowOffset: pressed ? const Offset(1, 1) : Brutal.shadow),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ),
            ),
            if (showArrow)
              Container(
                width: height,
                color: AppColors.ink,
                // arrow_forward بيتقلب لوحده في العربي فيشاور شمال (اتجاه القراءة)
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 26),
              ),
          ],
        ),
      ),
    );
  }
}

/// زرار مربع صغير بحدود سودا (للشريط العلوي، زي زرار الرجوع ←)
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
        duration: const Duration(milliseconds: 80),
        height: 40,
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        transform: Matrix4.translationValues(pressed ? 2 : 0, pressed ? 2 : 0, 0),
        decoration: Brutal.box(color: color, borderWidth: 2, shadowOffset: pressed ? Offset.zero : const Offset(2, 2)),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
          child: IconTheme.merge(data: const IconThemeData(color: AppColors.ink, size: 20), child: child),
        ),
      ),
    );
  }
}

/// مفتاح تبديل اللغة: عربي | FRANCO
class LangToggle extends StatelessWidget {
  final GameController game;
  const LangToggle({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, AppLang value) {
      final active = game.lang == value;
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        color: active ? AppColors.ink : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: active ? AppColors.yellow : AppColors.ink,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: game.toggleLang,
      child: Container(
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr, // ترتيب ثابت مهما كانت اللغة
          children: [segment('عربي', AppLang.ar), segment('FRANCO', AppLang.franco)],
        ),
      ),
    );
  }
}

/// عنوان كبير تقيل (زي "CREATE YOUR PROFILE")
class Headline extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const Headline(this.text, {super.key, this.size = 34, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(), // الفرانكو بيبقى حروف كبيرة، والعربي مش بيتأثر
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
        height: 1.05,
        letterSpacing: -0.5,
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
      child: widget.child,
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
