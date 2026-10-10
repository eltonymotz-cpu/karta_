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
  final bool clickable;    // هل ينفع نختاره كخسران دلوقتي؟ (بينبض)
  final bool tappable;     // هل المقعد بيستقبل ضغطات أصلاً؟ (الهوست: لتصحيح الكروت)
  final bool isMe;         // موبايل اللاعب: ده أنا؟
  final bool vertical;     // لما المساحة ضيقة المقعد بيبقى رأسي
  final String turnLabel;  // كلمة "دورك" باللغة الحالية
  final VoidCallback onTap;
  final Widget? clock;     // ساعة الدور (بتظهر لصاحب الدور بس)
  final Widget? coins;     // رصيد الكوينز (شارة صغيرة تحت المقعد، مابتغيرش مقاسه)

  const PlayerSeat({
    super.key,
    required this.player,
    required this.isCurrent,
    required this.isSilent,
    required this.clickable,
    required this.vertical,
    required this.turnLabel,
    required this.onTap,
    this.tappable = false,
    this.isMe = false,
    this.clock,
    this.coins,
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
      child: Text(initial, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
    );

    final name = Text(
      player.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2),
    );

    // شارة عدد الكروت: زي شارة "15 Stars" في التصميم
    final count = player.cards.length;
    final scoreBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: count > 0 ? AppColors.yellow : AppColors.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );

    final label = Text(
      turnLabel,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.red, height: 1.1),
    );
    // "دورك" + ساعة الدور جنبها
    final turnTag = clock == null
        ? label
        : Row(mainAxisSize: MainAxisSize.min, children: [label, const SizedBox(width: 4), clock!]);

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
        onTap: clickable || tappable ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: vertical ? 6 : 8, vertical: 6),
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
            // الكوينز: شارة تحت المقعد (مختلفة عن عدد الكروت)
            if (coins != null)
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: Brutal.box(color: AppColors.paper, borderWidth: 1.4, shadowOffset: Offset.zero, radius: 8),
                    child: coins,
                  ),
                ),
              ),
            // موبايل اللاعب: علامة صغيرة على اللاعب اللي هو ماسكه
            if (isMe)
              Positioned(
                top: -9,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: Brutal.box(color: AppColors.green, borderWidth: 1.6, shadowOffset: Offset.zero),
                  child: Icon(Icons.person, size: 12, color: AppColors.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
