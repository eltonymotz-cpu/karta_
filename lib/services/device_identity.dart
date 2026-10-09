// =================================================================
// رقم الموبايل في القعدة الحالية بس
// -----------------------------------------------------------------
// بيتخزن مؤقتاً عشان لو الصفحة اتعملها ريفريش وسط اللعب، الموبايل يرجع لنفس اللاعب.
// أول ما اللعبة تتقفل (الرجوع للشاشة الأولى) بيتمسح نهائي.
// مفيش اسم ولا رسايل ولا أي حاجة تانية بتتحفظ.
// =================================================================
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';

class DeviceIdentity {
  static const _deviceKey = 'device_id';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_name'); // اسم الشات القديم (لو اتحفظ في نسخة قديمة) بيتمسح
      var id = prefs.getString(_deviceKey);
      if (id == null || id.length < 8) {
        final r = Random.secure();
        id = List.generate(16, (_) => r.nextInt(36).toRadixString(36)).join();
        await prefs.setString(_deviceKey, id);
      }
      GameController.savedDeviceId = id;
    } catch (e) {
      debugPrint('Device id could not be stored: $e');
    }
    GameController.onSessionClosed = clear;
  }

  /// اللعبة اتقفلت: نمسح الرقم المتخزن
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceKey);
    } catch (_) {}
  }
}
