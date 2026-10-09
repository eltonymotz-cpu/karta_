// =================================================================
// رقم الموبايل + اسمه في الشات (بيتحفظوا على الجهاز)
// -----------------------------------------------------------------
// عشان لو الصفحة اتعملها ريفريش أو النت فصل ورجع، الموبايل يرجع بنفس الرقم:
// الهوست يعرفه، فيرجع لنفس اللاعب اللي كان ماسكه ونفس رسايله في الشات.
// =================================================================
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';

class DeviceIdentity {
  static const _deviceKey = 'device_id';
  static const _nameKey = 'chat_name';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_deviceKey);
      if (id == null || id.length < 8) {
        final r = Random.secure();
        id = List.generate(16, (_) => r.nextInt(36).toRadixString(36)).join();
        await prefs.setString(_deviceKey, id);
      }
      GameController.savedDeviceId = id;
      GameController.savedNickname = prefs.getString(_nameKey) ?? '';
    } catch (e) {
      debugPrint('Device id could not be stored: $e');
    }
  }
}

/// حفظ اسمي في الشات للمرة الجاية
Future<void> saveNickname(String name) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(DeviceIdentity._nameKey, name);
  } catch (e) {
    debugPrint('Nickname could not be saved: $e');
  }
}
