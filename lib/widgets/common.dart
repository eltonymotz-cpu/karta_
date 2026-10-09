// =================================================================
// عناصر واجهة مشتركة بتستخدمها كل الشاشات (ستايل Retro Pixel)
// =================================================================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/game_modes.dart';
import '../data/pixel_assets.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';

// =================================================================
// الخطوط
// =================================================================

/// اللغة الحالية بالنسبة للخطوط (main.dart بيحدّثها مع كل تغيير لغة)
class PixelFont {
  static bool arabic = true;
}

/// خط العناوين والزراير:
/// - في الفرانكو: خط البيكسل (Silkscreen - أرقامه واضحة)
/// - في العربي: خط Baloo المدوّر، لأن مفيش خط بيكسل عربي
TextStyle pixelStyle({double size = 16, Color? color, FontWeight weight = FontWeight.w700}) {
  color ??= AppColors.ink;
  if (PixelFont.arabic) {
    return GoogleFonts.balooBhaijaan2(fontSize: size, color: color, fontWeight: FontWeight.w800, height: 1.15);
  }
  return GoogleFonts.silkscreen(
    fontSize: size * 0.9,
    color: color,
    fontWeight: weight.value >= 600 ? FontWeight.w700 : FontWeight.w400,
    height: 1.2,
  ).copyWith(fontFamilyFallback: [GoogleFonts.balooBhaijaan2().fontFamily!]);
}

/// خط البيكسل دايماً (لقيمة الكارت والأرقام لوحدها) - الـ Text بيبقى
/// textDirection: TextDirection.ltr عشان الترتيب يفضل صح جوه الكلام العربي
TextStyle rankStyle({double size = 16, Color? color}) {
  color ??= AppColors.ink;
  return GoogleFonts.silkscreen(fontSize: size * 0.9, color: color, fontWeight: FontWeight.w700, height: 1.15);
}

// =================================================================
// الخلفية
// =================================================================

/// خلفية التطبيق: أزرق فاتح بمربعات زي الكراسة + ستيكرز صغيرة في الأركان
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _GridPainter()))),
          const Positioned(top: 96, right: 8, child: Opacity(opacity: 0.8, child: StickerImage(Sticker.sparkle, size: 26))),
          const Positioned(bottom: 110, left: 6, child: Opacity(opacity: 0.8, child: StickerImage(Sticker.heart, size: 26))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// مربعات الخلفية
class _GridPainter extends CustomPainter {
  final bool dark = AppColors.dark; // بيترسم من جديد لما الوضع الغامق يتغير

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 2;
    const cell = 24.0;
    for (double x = 0; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => (oldDelegate as _GridPainter).dark != dark;
}

// =================================================================
// الستيكرز
// =================================================================

/// صورة ستيكر بيكسل
class StickerImage extends StatelessWidget {
  final Sticker sticker;
  final double size;
  const StickerImage(this.sticker, {super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(sticker.path, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
  }
}

/// ستيكر زينة صغير (نجمة بيكسل)
class ShapeAccent extends StatelessWidget {
  final double size;
  const ShapeAccent({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) => StickerImage(Sticker.sparkle, size: size * 2);
}

/// شريط ستيكرز صغيرة متكررة (بيتحط تحت الشاشات والكروت)
class ShapesStrip extends StatelessWidget {
  final double height;
  const ShapesStrip({super.key, this.height = 16});

  static const _row = [Sticker.heart, Sticker.sparkle, Sticker.check, Sticker.smiley, Sticker.music, Sticker.xbutton];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final count = (constraints.maxWidth / (height * 1.7)).floor().clamp(1, 40);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (var i = 0; i < count; i++) StickerImage(_row[i % _row.length], size: height)],
        );
      }),
    );
  }
}

/// أيقونة النمط: صورته لو الأدمن رفع صورة، وإلا الإيموجي بتاعه
class ModeIcon extends StatelessWidget {
  final GameMode mode;
  final double size;
  final Color? color;
  const ModeIcon({super.key, required this.mode, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    final image = mode.image;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(color: color ?? AppColors.yellow, borderWidth: 2, shadowOffset: Offset.zero),
      // الصورة يا رابط (Supabase Storage) يا base64 (الصور القديمة)
      child: image == null
          ? Text(mode.emoji, style: TextStyle(fontSize: size * 0.5))
          : image.startsWith(assetPrefix)
              ? Image.asset(assetPath(image), width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.none)
              : image.startsWith('http')
              ? Image.network(image, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Text(mode.emoji, style: TextStyle(fontSize: size * 0.5)))
              : Image.memory(base64Decode(image), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
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
  final bool dark = AppColors.dark;
  _DotPainter(this.columns, this.rows, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.55);
    for (var x = 0; x < columns; x++) {
      for (var y = 0; y < rows; y++) {
        // نقط مربعة (بيكسل)
        canvas.drawRect(Rect.fromCenter(center: Offset(x * gap + gap / 2, y * gap + gap / 2), width: 2.4, height: 2.4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => (oldDelegate as _DotPainter).dark != dark;
}

// =================================================================
// الشبابيك والصناديق
// =================================================================

/// صندوق كريمي بحدود غامقة وظل صلب
class BrutalBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const BrutalBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: Brutal.box(color: color), child: child);
  }
}

/// شباك كمبيوتر قديم: شريط عنوان ملون فيه اسم + أزرار _ □ ✕، وتحته المحتوى
class RetroWindow extends StatelessWidget {
  final String title;
  final Color? barColor;
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const RetroWindow({
    super.key,
    required this.title,
    required this.child,
    this.barColor,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowBar(title: title, color: barColor),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// شريط عنوان الشباك لوحده
class WindowBar extends StatelessWidget {
  final String title;
  final Color? color;
  final double height;
  const WindowBar({super.key, required this.title, this.color, this.height = 30});

  @override
  Widget build(BuildContext context) {
    final iconSize = height * 0.42;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.3),
      decoration: BoxDecoration(
        color: color ?? AppColors.teal,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: Brutal.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pixelStyle(size: height * 0.45, weight: FontWeight.w600),
            ),
          ),
          // أزرار الشباك _ □ ✕ (للشكل بس)
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Container(width: iconSize, height: 2, margin: EdgeInsets.only(top: iconSize * 0.8), color: AppColors.ink),
              SizedBox(width: iconSize * 0.6),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(border: Border.all(color: AppColors.ink, width: 1.8)),
              ),
              SizedBox(width: iconSize * 0.6),
              Icon(Icons.close, size: iconSize * 1.3, color: AppColors.ink),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// الزراير
// =================================================================

/// الزرار الكبير: لون مليان بحدود غامقة وظل صلب، وجنبه مربع فيه سهم
class BrutalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showArrow;
  final double height;
  final double fontSize;
  const BrutalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
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
        padding: EdgeInsets.all(height * 0.1),
        decoration: Brutal.box(color: color ?? AppColors.yellow, shadowOffset: pressed ? const Offset(1, 1) : Brutal.shadow),
        child: Row(
          children: [
            if (showArrow) SizedBox(width: height * 0.8),
            Expanded(
              child: Center(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: pixelStyle(size: fontSize)),
              ),
            ),
            if (showArrow)
              Container(
                width: height * 0.8,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(3)),
                // arrow_forward بيتقلب لوحده في العربي فيشاور شمال (اتجاه القراءة)
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.paper, size: height * 0.42),
              ),
          ],
        ),
      ),
    );
  }
}

/// زرار صغير (للشريط العلوي)
class SquareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  const SquareButton({super.key, required this.child, this.onTap, this.color});

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
          style: pixelStyle(size: 14),
          child: IconTheme.merge(data: IconThemeData(color: AppColors.ink, size: 20), child: child),
        ),
      ),
    );
  }
}

/// مفتاح تبديل اللغة: عربي | Franco
class LangToggle extends StatelessWidget {
  final GameController game;
  final bool compact; // نسخة أصغر للشريط العلوي في شاشة اللعب
  const LangToggle({super.key, required this.game, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, AppLang value) {
      final active = game.lang == value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        color: active ? AppColors.yellow : Colors.transparent,
        child: Text(label, style: pixelStyle(size: 13)),
      );
    }

    final lang = GestureDetector(
      onTap: game.toggleLang,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr, // ترتيب ثابت مهما كانت اللغة
          children: [
            segment('عربي', AppLang.ar),
            Container(width: 2, height: 34, color: AppColors.ink),
            segment(compact ? 'FR' : 'Franco', AppLang.franco),
          ],
        ),
      ),
    );
    // زرار الوضع الغامق جنب اللغة على طول
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [lang, SizedBox(width: compact ? 5 : 8), const ThemeToggle()],
    );
  }
}

/// زرار الشمس/القمر: بيبدّل بين الوضع الفاتح والغامق (وبيتحفظ على الجهاز)
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    return Semantics(
      button: true,
      label: dark ? 'Light mode' : 'Dark mode',
      child: GestureDetector(
        onTap: AppTheme.toggle,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: Brutal.box(
            color: dark ? AppColors.yellow : AppColors.ink,
            borderWidth: 2,
            shadowOffset: const Offset(2, 2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.6, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(dark),
              size: 20,
              color: dark ? const Color(0xFFFFD45C) : AppColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

/// عنوان كبير بخط البيكسل
class Headline extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const Headline(this.text, {super.key, this.size = 34, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: align, style: pixelStyle(size: size));
  }
}

// =================================================================
// حركات
// =================================================================

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
    // لو الموبايل مفعّل "تقليل الحركة"، مفيش نبض
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return widget.child;
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
