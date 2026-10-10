// =================================================================
// أنيميشن خفيفة مربوطة بأحداث اللعبة الحقيقية (lastEvent)
// -----------------------------------------------------------------
// - حد خسر: كارت صغير بيطير من نص الترابيزة لمكان الخسران + "+1 🃏" حمرا فوق اسمه
//   + تنبيه صغير فوق "فلان خسر!"
// - تصحيح (الهوست شال كارت): "-1 ✔" خضرا فوق اسم اللاعب
// - محدش خسر / سكيب / الوقت خلص: تنبيه صغير فوق
// الأنيميشن مش بتغيّر أي حاجة في اللعبة، بتعرض بس اللي حصل فعلاً.
// لو الموبايل مفعّل "تقليل الحركة"، الكارت مش بيطير والتنبيهات بتظهر من غير حركة.
// =================================================================
import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// تنبيه صغير بيظهر فوق ويختفي لوحده
class FxToast extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onDone;
  const FxToast({super.key, required this.text, required this.color, required this.onDone});

  @override
  State<FxToast> createState() => _FxToastState();
}

class _FxToastState extends State<FxToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // يظهر بسرعة، يقف، ويختفي في الآخر
        final opacity = t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
        final dy = still ? 0.0 : (t < 0.15 ? (1 - t / 0.15) * -12 : 0.0);
        return Opacity(opacity: opacity.clamp(0, 1), child: Transform.translate(offset: Offset(0, dy), child: child));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: Brutal.box(color: widget.color, borderWidth: 2, shadowOffset: const Offset(3, 3)),
        child: Text(widget.text, style: pixelStyle(size: 16, color: AppColors.ink)),
      ),
    );
  }
}

/// كارت صغير بيطير من مكان لمكان ويصغر
class FxFlyingCard extends StatefulWidget {
  final Offset from;
  final Offset to;
  final Color color;
  final VoidCallback onDone;
  const FxFlyingCard({super.key, required this.from, required this.to, required this.color, required this.onDone});

  @override
  State<FxFlyingCard> createState() => _FxFlyingCardState();
}

class _FxFlyingCardState extends State<FxFlyingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const w = 54.0, h = 76.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInCubic.transform(_c.value);
        final pos = Offset.lerp(widget.from, widget.to, t)!;
        final scale = 1.0 - 0.65 * t;
        return Positioned(
          left: pos.dx - w / 2,
          top: pos.dy - h / 2,
          child: Opacity(
            opacity: 1.0 - 0.4 * t,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: w,
                height: h,
                decoration: Brutal.box(color: widget.color, borderWidth: 2, shadowOffset: const Offset(2, 2)),
                child: const Center(child: StickerImage(Sticker.sparkle, size: 22)),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// رقم صغير بيطلع لفوق فوق اسم اللاعب ويختفي ("+1 🃏" أو "-1 ✔")
class FxFloatingLabel extends StatefulWidget {
  final Offset at;
  final String text;
  final Color color;
  final Duration delay;
  final VoidCallback onDone;
  const FxFloatingLabel({
    super.key,
    required this.at,
    required this.text,
    required this.color,
    required this.onDone,
    this.delay = Duration.zero,
  });

  @override
  State<FxFloatingLabel> createState() => _FxFloatingLabelState();
}

class _FxFloatingLabelState extends State<FxFloatingLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward().whenComplete(widget.onDone);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        if (t == 0) return const SizedBox.shrink();
        // بيكبر شوية في الأول (bounce) وبعدين يطلع لفوق ويختفي
        final scale = still ? 1.0 : (t < 0.25 ? 0.6 + 1.8 * t : 1.05 - 0.05 * t);
        final dy = still ? 0.0 : -26 * t;
        return Positioned(
          left: widget.at.dx - 40,
          top: widget.at.dy - 34 + dy,
          width: 80,
          child: Opacity(
            opacity: t > 0.7 ? (1 - t) / 0.3 : 1.0,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: Brutal.box(color: widget.color, borderWidth: 2, shadowOffset: const Offset(2, 2)),
          child: Text(widget.text, style: pixelStyle(size: 15, color: AppColors.ink)),
        ),
      ),
    );
  }
}

/// إيموجي من الأزرار السريعة: بيظهر كبير في نص اللعبة ويطلع لفوق ويختفي (ومعاه اسم اللي بعته)
class FxReaction extends StatefulWidget {
  final Offset at;
  final String emoji;
  final String name;
  final VoidCallback onDone;
  const FxReaction({super.key, required this.at, required this.emoji, required this.name, required this.onDone});

  @override
  State<FxReaction> createState() => _FxReactionState();
}

class _FxReactionState extends State<FxReaction> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final scale = still ? 1.0 : (t < 0.15 ? 0.4 + 4.6 * t : 1.09 - 0.09 * t);
        final dy = still ? 0.0 : -90 * Curves.easeOut.transform(t);
        return Positioned(
          left: widget.at.dx - 60,
          top: widget.at.dy - 50 + dy,
          width: 120,
          child: Opacity(opacity: t > 0.75 ? (1 - t) / 0.25 : 1.0, child: Transform.scale(scale: scale, child: child)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: Brutal.box(borderWidth: 1.6, shadowOffset: Offset.zero),
            child: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
