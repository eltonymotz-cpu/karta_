// =================================================================
// مقعد اللاعب: الاسم + صندوق صغير فيه عدد كروته
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
    // أول حرف من الاسم يظهر في المربع الملوّن
    final initial = player.name.isEmpty ? '?' : player.name.characters.first.toUpperCase();

    final avatar = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: player.color,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
    );

    final name = Text(
      player.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2),
    );

    // صندوق عدد الكروت: مربع أسود والرقم أصفر
    final count = player.cards.length;
    final scoreBox = Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      color: AppColors.ink,
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: count > 0 ? AppColors.yellow : Colors.white54,
        ),
      ),
    );

    final turnTag = Text(
      turnLabel.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.1),
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
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: vertical ? 5 : 7, vertical: 6),
              decoration: Brutal.box(
                color: isCurrent ? AppColors.yellow : AppColors.paper,
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
