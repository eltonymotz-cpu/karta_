// =================================================================
// نافذة الـ QR: الباقيين يعملوا سكان ويدخلوا القعدة ويتفرجوا على الكارت
// =================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import 'common.dart';

/// رابط الدخول للقعدة (ده اللي بيتحط جوه الـ QR)
String joinUrl(String code) {
  // 1) لو حاطط رابط نسخة الويب في config.dart نستخدمه
  if (AppConfig.joinBaseUrl.isNotEmpty) return '${AppConfig.joinBaseUrl}?room=$code';
  // 2) لو التطبيق نفسه شغال على الويب نستخدم رابطه الحالي
  if (kIsWeb) return Uri.base.replace(queryParameters: {'room': code}, fragment: '').toString();
  // 3) غير كده: الكود بس (يكتبوه بإيدهم في الشاشة الأولى)
  return code;
}

Future<void> showQrDialog(BuildContext context, GameController game) {
  final code = game.roomCode ?? '';
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BrutalBox(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Headline(game.t(UiText.scanToJoin), size: 24),
            const SizedBox(height: 16),
            // الـ QR في مربع أبيض بحدود سودا
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: Brutal.box(shadowOffset: const Offset(5, 5)),
                child: QrImageView(data: joinUrl(code), size: 220, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            // الكود مكتوب في مربعات زي خانات الـ OTP
            Text(game.t(UiText.roomCode).toUpperCase(),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              children: [
                for (final ch in code.split(''))
                  Container(
                    width: 40,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    alignment: Alignment.center,
                    decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
                    child: Text(ch, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            BrutalButton(label: game.t(UiText.close), onTap: () => Navigator.pop(context), showArrow: false),
          ],
        ),
      ),
    ),
  );
}
