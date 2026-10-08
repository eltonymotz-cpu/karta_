// =================================================================
// خدمة الأصوات
// -----------------------------------------------------------------
// كل الأصوات ملفات WAV صغيرة في مجلد assets/sounds
// اسم الصوت في enum Sfx لازم يطابق اسم الملف بالظبط.
//
// السرعة: بنحمّل كل صوت مرة واحدة في أول التطبيق (preload) في مشغل خاص بيه،
// فلما نحتاجه بنرجّعه للأول ونشغّله على طول من غير ما نستنى تحميل الملف.
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
  alarm,    // إنذار التصفيق (5 و 6 و 7)
  gift,     // هدية الكادو
  fanfare,  // نهاية اللعبة
}

class SoundService {
  // نسخة واحدة فقط من الخدمة في التطبيق كله (Singleton)
  SoundService._();
  static final SoundService instance = SoundService._();

  // مشغل جاهز لكل صوت (الملف متحمّل فيه من الأول)
  final Map<Sfx, AudioPlayer> _players = {};
  final _random = Random();

  /// هل الصوت شغال؟ (زرار 🔊 في الشريط العلوي)
  bool enabled = true;

  /// تحميل كل الأصوات مرة واحدة (بتتنادى في main.dart)
  Future<void> preload() async {
    await Future.wait(Sfx.values.map((sfx) async {
      try {
        final player = AudioPlayer();
        // ReleaseMode.stop: بعد ما الصوت يخلص الملف يفضل متحمّل وجاهز للمرة الجاية
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('sounds/${sfx.name}.wav'));
        _players[sfx] = player;
      } catch (_) {
        // لو صوت معيّن فشل يتحمّل، هيتشغّل بالطريقة العادية وقت الحاجة
      }
    }));
  }

  /// تشغيل صوت معيّن
  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    try {
      final player = _players[sfx];
      if (player != null) {
        // الصوت متحمّل: نرجعه للأول ونشغّله فوراً
        await player.seek(Duration.zero);
        await player.resume();
      } else {
        // احتياط: لو لسه متحمّلش نشغّله بالطريقة العادية
        await AudioPlayer().play(AssetSource('sounds/${sfx.name}.wav'));
      }
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
