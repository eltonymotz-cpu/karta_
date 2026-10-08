// =================================================================
// حفظ وتحميل الأنماط اللي الأدمن بيضيفها
// -----------------------------------------------------------------
// - لو Supabase متظبط: الأنماط بتتحفظ في جدول karta_modes
//   (شوف supabase/setup.sql) فتظهر على كل الأجهزة.
// - وكمان بتتحفظ نسخة على الجهاز (SharedPreferences) عشان تشتغل من غير نت.
// =================================================================
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../data/game_modes.dart';

class ModeStore {
  static const _table = 'karta_modes';     // اسم الجدول في Supabase
  static const _cacheKey = 'custom_modes'; // اسم النسخة المحفوظة على الجهاز

  /// تحميل الأنماط: الأول من الجهاز (سريع)، وبعدين من Supabase (الأحدث)
  static Future<void> load() async {
    await _loadCache();
    if (!AppConfig.hasSupabase) return;
    try {
      final rows = await Supabase.instance.client.from(_table).select('id, data');
      customModes
        ..clear()
        ..addAll({
          for (final row in rows)
            row['id'] as String: GameMode.fromJson(Map<String, dynamic>.from(row['data'] as Map)),
        });
      await _saveCache();
    } catch (_) {
      // مفيش نت أو الجدول مش موجود: نكمّل بالنسخة اللي على الجهاز
    }
  }

  /// حفظ نمط (جديد أو تعديل). بترجع null لو كله تمام، أو رسالة الخطأ لو الحفظ أونلاين فشل
  static Future<String?> save(String id, GameMode mode) async {
    customModes[id] = mode;
    await _saveCache();
    if (!AppConfig.hasSupabase) return null;
    try {
      await Supabase.instance.client.from(_table).upsert({'id': id, 'data': mode.toJson()});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// مسح نمط
  static Future<void> delete(String id) async {
    customModes.remove(id);
    await _saveCache();
    if (!AppConfig.hasSupabase) return;
    try {
      await Supabase.instance.client.from(_table).delete().eq('id', id);
    } catch (_) {}
  }

  // ---------------- النسخة المحفوظة على الجهاز ----------------

  /// للاختبارات: حفظ وتحميل على الجهاز بس
  @visibleForTesting
  static Future<void> saveLocal(String id, GameMode mode) async {
    customModes[id] = mode;
    await _saveCache();
  }

  @visibleForTesting
  static Future<void> loadLocal() => _loadCache();

  static Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      customModes
        ..clear()
        ..addAll({
          for (final e in map.entries) e.key: GameMode.fromJson(Map<String, dynamic>.from(e.value as Map)),
        });
    } catch (_) {}
  }

  static Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({for (final e in customModes.entries) e.key: e.value.toJson()}),
      );
    } catch (_) {}
  }
}
