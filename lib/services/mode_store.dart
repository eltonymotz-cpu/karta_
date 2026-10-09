// =================================================================
// حفظ وتحميل الأنماط والكروت اللي الأدمن بيضيفها أو بيعدّلها
// -----------------------------------------------------------------
// - لو Supabase متظبط: الأنماط بتتحفظ في جدول karta_modes فتظهر على كل الأجهزة،
//   وأي تعديل بيوصل للأجهزة التانية لايف (Realtime) من غير ما حد يعمل ريفريش.
// - وكمان بتتحفظ نسخة على الجهاز (SharedPreferences) عشان تشتغل من غير نت.
// - الحفظ أونلاين لازم ينجح الأول، وبعدين بنحدّث الجهاز (عشان مانقولش "اتحفظ" وهو ماتحفظش).
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
  static RealtimeChannel? _channel;

  /// تحميل الأنماط: الأول من الجهاز (سريع)، وبعدين من Supabase (الأحدث)
  static Future<void> load() async {
    await _loadCache();
    await _loadRemote();
  }

  static Future<bool> _loadRemote() async {
    if (!AppConfig.hasSupabase) return false;
    try {
      final rows = await Supabase.instance.client.from(_table).select('id, data');
      customModes
        ..clear()
        ..addAll({
          for (final row in rows)
            row['id'] as String: GameMode.fromJson(Map<String, dynamic>.from(row['data'] as Map)),
        });
      await _saveCache();
      return true;
    } catch (_) {
      // مفيش نت أو الجدول مش موجود: نكمّل بالنسخة اللي على الجهاز
      return false;
    }
  }

  /// متابعة التعديلات لايف: لما الأدمن يحفظ من أي جهاز، الأجهزة التانية بتتحدث
  static void listen(VoidCallback onChange) {
    if (!AppConfig.hasSupabase || _channel != null) return;
    try {
      _channel = Supabase.instance.client
          .channel('karta-modes-changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _table,
            callback: (_) async {
              if (await _loadRemote()) onChange();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  /// حفظ نمط (جديد أو تعديل). بترجع null لو كله تمام، أو رسالة الخطأ.
  /// لو الحفظ أونلاين فشل، مفيش أي حاجة بتتغير (لا على الجهاز ولا في اللعبة).
  static Future<String?> save(String id, GameMode mode) async {
    if (AppConfig.hasSupabase) {
      try {
        await Supabase.instance.client
            .from(_table)
            .upsert({'id': id, 'data': mode.toJson(), 'updated_at': DateTime.now().toUtc().toIso8601String()});
      } on PostgrestException catch (e) {
        return _friendly(e);
      } catch (e) {
        return e.toString();
      }
    }
    customModes[id] = mode;
    await _saveCache();
    return null;
  }

  /// مسح نمط. بترجع null لو كله تمام، أو رسالة الخطأ
  static Future<String?> delete(String id) async {
    if (AppConfig.hasSupabase) {
      try {
        await Supabase.instance.client.from(_table).delete().eq('id', id);
      } on PostgrestException catch (e) {
        return _friendly(e);
      } catch (e) {
        return e.toString();
      }
    }
    customModes.remove(id);
    await _saveCache();
    return null;
  }

  /// رسالة خطأ مفهومة (أشهرها: مش داخل كأدمن)
  static String _friendly(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('row-level security')) {
      return 'Not allowed: log in with an admin account (${e.message})';
    }
    return e.message;
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

  @visibleForTesting
  static Future<void> deleteLocal(String id) async {
    customModes.remove(id);
    await _saveCache();
  }

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
