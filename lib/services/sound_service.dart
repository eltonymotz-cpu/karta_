// =================================================================
// خدمة الأصوات
// -----------------------------------------------------------------
// كل الأصوات ملفات WAV صغيرة في مجلد assets/sounds
// اسم الصوت في enum Sfx لازم يطابق اسم الملف بالظبط.
// =================================================================
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// كل الأصوات المتاحة
enum Sfx {
  flip,     // سحب/قلب الكارت
  quack,    // بطة 🦆
  horn,     // زمارة 🎺
  boom,     // انفجار 💥
  tick,     // تكة القنبلة
  clap,     // تصفيقة
  boing,    // سوستة
  trombone, // ترومبون حزين (واه واه واه)
  ding,     // دينج (حظ حلو)
  alarm,    // إنذار ظهور زرار التصفيق
  gift,     // هدية الكادو
  fanfare,  // نهاية اللعبة
}

class SoundService {
  // نسخة واحدة فقط من الخدمة في التطبيق كله (Singleton)
  SoundService._();
  static final SoundService instance = SoundService._();

  // مجموعة مشغلات بنستخدمها بالتناوب، عشان أكتر من صوت يشتغلوا مع بعض
  final List<AudioPlayer> _pool = List.generate(5, (_) => AudioPlayer());
  int _next = 0;
  final _random = Random();

  /// هل الصوت شغال؟ (زرار 🔊 في الشريط العلوي)
  bool enabled = true;

  /// تشغيل صوت معيّن
  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'));
    } catch (_) {
      // لو الجهاز مش قادر يشغّل الصوت نكمّل اللعب عادي
    }
  }

  /// صوت عشوائي للعقوبة: مرة بطة، ومرة زمارة، ومرة بوم...
  void playPenalty() {
    const options = [Sfx.quack, Sfx.horn, Sfx.boom, Sfx.boing, Sfx.trombone];
    play(options[_random.nextInt(options.length)]);
  }
}
