// =================================================================
// مقعد اللاعب: دايرة بلونه + الاسم + شارة صغيرة فيها عدد كروته
// -----------------------------------------------------------------
// المقاعد بتتلف حوالين الكارت على أطراف الشاشة.
// - صاحب الدور: المقعد أصفر + كلمة "دورك"
// - وقت اختيار الخسران: المقعد بينبض وظله بيبقى أحمر وبيبقى قابل للضغط
// =================================================================
import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class PlayerSeat extends StatelessWidget {
  final Player player;
  final bool isCurrent;    // هل ده صاحب الدور؟
  final bool isSilent;     // هل هو في وضع الصمت (Q)؟
  final bool clickable;    // هل ينفع نختاره كخسران دلوقتي؟
  final bool vertical;     // لما المساحة ضيقة المقعد بيبقى رأسي
  final String turnLabel;  // كلمة "دورك" باللغة الحالية
  final VoidCallback onTap;

  const PlayerSeat({
    super.key,
    required this.player,
    required this.isCurrent,
    required this.isSilent,
    required this.clickable,
    required this.vertical,
    required this.turnLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // أول حرف من الاسم يظهر في الدايرة الملوّنة
    final initial = player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase();

    final avatar = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: player.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
    );

    final name = Text(
      player.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2),
    );

    // شارة عدد الكروت: زي شارة "15 Stars" في التصميم
    final count = player.cards.length;
    final scoreBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: count > 0 ? AppColors.sky : AppColors.paper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.ink, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );

    final turnTag = Text(
      turnLabel,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.red, height: 1.1),
    );

    // ترتيب المحتوى: رأسي لما المساحة ضيقة، أفقي لما فيه مساحة
    final content = vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 3),
              name,
              if (isCurrent) turnTag,
              const SizedBox(height: 4),
              scoreBox,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, if (isCurrent) turnTag],
                ),
              ),
              const SizedBox(width: 6),
              scoreBox,
            ],
          );

    return Pulse(
      enabled: clickable,
      scale: 1.07,
      child: GestureDetector(
        onTap: clickable ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: vertical ? 6 : 8, vertical: 6),
              decoration: Brutal.box(
                color: isCurrent ? AppColors.yellow : AppColors.paper,
                radius: 16,
                shadowOffset: clickable ? const Offset(4, 4) : const Offset(3, 3),
                shadowColor: clickable ? AppColors.red : AppColors.ink,
              ),
              child: content,
            ),
            // علامة الصمت 🤐 فوق المقعد
            if (isSilent)
              const Positioned(top: -10, right: -8, child: Text('🤐', style: TextStyle(fontSize: 17))),
          ],
        ),
      ),
    );
  }
}
