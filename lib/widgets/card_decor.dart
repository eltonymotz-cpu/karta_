// =================================================================
// النقشات الهندسية على وش الكارت
// -----------------------------------------------------------------
// كل كارت ليه لون ونقشة (شوف cardStyles في theme.dart).
// الرسم بيكون على الأطراف والأركان بس، عشان نص الكارت يفضل فاضي للكلام.
// =================================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class CardDecor extends StatelessWidget {
  final CardStyle style;
  final int seed; // رقم ثابت لكل كارت عشان الـ confetti تترسم بنفس الشكل كل مرة
  const CardDecor({super.key, required this.style, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DecorPainter(style, seed), size: Size.infinite);
  }
}

class _DecorPainter extends CustomPainter {
  final CardStyle style;
  final int seed;
  _DecorPainter(this.style, this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = max(1.6, w * 0.008);

    // فرش جاهزة
    final fill = Paint()..color = style.color;
    final soft = Paint()..color = style.color.withValues(alpha: 0.35);
    final ink = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final faint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.7;

    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    void plus(Offset c, double r, Paint p) {
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), p);
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), p);
    }

    switch (style.pattern) {
      case CardPattern.triangles:
        // مثلث مليان تحت على الشمال + مثلث فاضي فوق على اليمين
        final t1 = tri(Offset(-w * 0.05, h), Offset(w * 0.32, h), Offset(w * 0.1, h * 0.8));
        canvas.drawPath(t1, fill);
        canvas.drawPath(t1, ink);
        canvas.drawPath(tri(Offset(w * 0.72, h * 0.06), Offset(w * 0.94, h * 0.06), Offset(w * 0.83, h * 0.2)), ink);
        canvas.drawPath(tri(Offset(w * 0.86, h * 0.62), Offset(w * 0.97, h * 0.7), Offset(w * 0.86, h * 0.78)), soft);
        break;

      case CardPattern.circles:
        // نص دايرة كبيرة تحت على اليمين + دايرة فاضية فوق
        final r = w * 0.26;
        final c = Offset(w * 0.98, h * 0.98);
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, ink);
        canvas.drawCircle(Offset(w * 0.86, h * 0.12), w * 0.07, ink);
        canvas.drawCircle(Offset(w * 0.08, h * 0.7), w * 0.035, fill);
        canvas.drawCircle(Offset(w * 0.14, h * 0.75), w * 0.02, soft);
        break;

      case CardPattern.grid:
        // شبكة خطوط فوق على اليمين + مربع مليان تحت
        final gx = w * 0.62, gy = h * 0.04, cell = w * 0.07;
        for (var i = 0; i <= 4; i++) {
          canvas.drawLine(Offset(gx + i * cell, gy), Offset(gx + i * cell, gy + 4 * cell), faint);
          canvas.drawLine(Offset(gx, gy + i * cell), Offset(gx + 4 * cell, gy + i * cell), faint);
        }
        final sq = Rect.fromLTWH(w * 0.04, h * 0.8, w * 0.18, w * 0.18);
        canvas.drawRect(sq, fill);
        canvas.drawRect(sq, ink);
        break;

      case CardPattern.burst:
        // شعاع خطوط حوالين نقطة فوق على اليمين + دايرة مليانة تحت
        final c = Offset(w * 0.84, h * 0.13);
        for (var i = 0; i < 10; i++) {
          final a = i * pi / 5;
          canvas.drawLine(c + Offset(cos(a), sin(a)) * w * 0.05, c + Offset(cos(a), sin(a)) * w * 0.11, ink);
        }
        canvas.drawCircle(c, w * 0.03, fill);
        canvas.drawCircle(Offset(w * 0.1, h * 0.9), w * 0.12, fill);
        canvas.drawCircle(Offset(w * 0.1, h * 0.9), w * 0.12, ink);
        break;

      case CardPattern.confetti:
        // قصاقيص ملونة متفرقة على الأطراف
        final rnd = Random(seed + 7);
        for (var i = 0; i < 22; i++) {
          // نختار مكان على الأطراف (مش في نص الكارت)
          final edge = rnd.nextInt(4);
          final t = rnd.nextDouble();
          final p = switch (edge) {
            0 => Offset(t * w, h * (0.03 + rnd.nextDouble() * 0.12)),
            1 => Offset(t * w, h * (0.85 + rnd.nextDouble() * 0.12)),
            2 => Offset(w * (0.03 + rnd.nextDouble() * 0.08), t * h),
            _ => Offset(w * (0.89 + rnd.nextDouble() * 0.08), t * h),
          };
          final paint = i.isEven ? fill : soft;
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * pi);
          if (i % 3 == 0) {
            canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w * 0.035, height: w * 0.012), paint);
          } else if (i % 3 == 1) {
            canvas.drawCircle(Offset.zero, w * 0.012, paint);
          } else {
            canvas.drawPath(tri(Offset(0, -w * 0.016), Offset(w * 0.015, w * 0.012), Offset(-w * 0.015, w * 0.012)), paint);
          }
          canvas.restore();
        }
        break;

      case CardPattern.waves:
        // 3 خطوط متموجة تحت + دايرة فاضية فوق
        for (var line = 0; line < 3; line++) {
          final y = h * (0.86 + line * 0.035);
          final path = Path()..moveTo(0, y);
          for (double x = 0; x <= w; x += w * 0.02) {
            path.lineTo(x, y + sin(x / w * pi * 6) * w * 0.015);
          }
          canvas.drawPath(path, line == 1 ? (Paint()..color = style.color..style = PaintingStyle.stroke..strokeWidth = stroke * 1.8) : ink);
        }
        canvas.drawCircle(Offset(w * 0.86, h * 0.12), w * 0.06, fill);
        canvas.drawCircle(Offset(w * 0.86, h * 0.12), w * 0.06, ink);
        break;

      case CardPattern.squares:
        // مربع "متحدد" بمقابض زي برامج التصميم فوق على اليمين + مربع فاضي تحت
        final r = Rect.fromLTWH(w * 0.66, h * 0.05, w * 0.22, w * 0.22);
        canvas.drawRect(r, fill);
        canvas.drawRect(r, ink);
        for (final corner in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          final handle = Rect.fromCenter(center: corner, width: w * 0.04, height: w * 0.04);
          canvas.drawRect(handle, Paint()..color = AppColors.paper);
          canvas.drawRect(handle, ink);
        }
        canvas.save();
        canvas.translate(w * 0.13, h * 0.88);
        canvas.rotate(pi / 8);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: w * 0.14), ink);
        canvas.restore();
        break;

      case CardPattern.halfMoon:
        // نص دايرة على الحافة الشمال + مستطيل مليان تحت على اليمين
        final c = Offset(0, h * 0.5);
        canvas.drawArc(Rect.fromCircle(center: c, radius: w * 0.12), -pi / 2, pi, true, fill);
        canvas.drawArc(Rect.fromCircle(center: c, radius: w * 0.12), -pi / 2, pi, true, ink);
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.86, w * 0.26, h * 0.06), const Radius.circular(4));
        canvas.drawRRect(rect, soft);
        canvas.drawRRect(rect, ink);
        plus(Offset(w * 0.86, h * 0.12), w * 0.045, ink);
        break;

      case CardPattern.crosses:
        // علامات + متفرقة فوق وتحت (بعيد عن الكلام) + مربع مليان فيه علامة +
        for (final p in [
          Offset(w * 0.74, h * 0.07),
          Offset(w * 0.9, h * 0.14),
          Offset(w * 0.34, h * 0.94),
          Offset(w * 0.62, h * 0.92),
        ]) {
          plus(p, w * 0.03, ink);
        }
        final sq = Rect.fromLTWH(w * 0.05, h * 0.82, w * 0.14, w * 0.14);
        canvas.drawRect(sq, fill);
        plus(sq.center, w * 0.05, Paint()..color = AppColors.paper..strokeWidth = stroke * 1.3);
        break;

      case CardPattern.stripes:
        // شريط خطوط مايلة جوه مستطيل مدوّر تحت + مثلث فاضي فوق
        final band = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.04, h * 0.84, w * 0.42, h * 0.09), Radius.circular(w * 0.03));
        canvas.save();
        canvas.clipRRect(band);
        canvas.drawRRect(band, Paint()..color = AppColors.paper);
        for (double x = band.left - band.height; x < band.right; x += w * 0.05) {
          canvas.drawLine(Offset(x, band.bottom), Offset(x + band.height, band.top), Paint()..color = style.color..strokeWidth = w * 0.018);
        }
        canvas.restore();
        canvas.drawRRect(band, ink);
        canvas.drawPath(tri(Offset(w * 0.74, h * 0.18), Offset(w * 0.84, h * 0.04), Offset(w * 0.94, h * 0.18)), ink);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DecorPainter old) => old.style != style || old.seed != seed;
}
