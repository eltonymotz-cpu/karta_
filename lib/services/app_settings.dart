// =================================================================
// إعدادات اللعبة العامة اللي الأدمن بيغيّرها (الأونلاين + الشات + الرسايل الصوتية)
// (دي إعدادات الأدمن بس - مفيش أي بيانات من القعدات نفسها بتتحفظ)
// -----------------------------------------------------------------
// - بتتحفظ في Supabase (جدول karta_settings، صف واحد id = 'global')
// - نسخة منها بتتحفظ على الجهاز، فلو مفيش نت اللعبة بتشتغل بآخر إعدادات
// - أي خانة مش موجودة بتاخد القيمة الافتراضية (فالإعدادات القديمة بتشتغل عادي)
// =================================================================
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class AppSettings {
  // ---------------- الأونلاين ----------------
  final bool onlineEnabled;      // زرار "أكتر من موبايل" ظاهر؟

  // ---------------- الشات ----------------
  final bool chatOnline;         // الشات في القعدات الأونلاين
  final int chatMaxLength;       // أقصى طول للرسالة
  final int chatPerMinute;       // أقصى عدد رسايل في الدقيقة لكل لاعب

  // ---------------- الرسايل الصوتية ----------------
  final bool voiceOnline;        // تسجيل رسايل صوتية في القعدات الأونلاين
  final int voiceMaxSeconds;     // أقصى مدة للتسجيل (الصوت بيتبعت جوه الرسالة ومابيتحفظش)

  const AppSettings({
    this.onlineEnabled = true,
    this.chatOnline = true,
    this.chatMaxLength = 300,
    this.chatPerMinute = 20,
    this.voiceOnline = true,
    this.voiceMaxSeconds = 30,
  });

  /// الحدود المسموحة (الأدمن مايقدرش يحط قيمة برا المدى ده)
  static const chatLengthRange = (50, 1000);
  static const chatPerMinuteRange = (3, 60);
  static const voiceSecondsRange = (5, 60); // أكتر من كده الرسالة تعدي حد قناة القعدة (حوالي 250 KB)

  /// الإعدادات الحالية (بتتحمل أول ما التطبيق يفتح)
  static AppSettings current = const AppSettings();
  static final ValueNotifier<int> changes = ValueNotifier(0);

  Map<String, dynamic> toJson() => {
        'online': {'enabled': onlineEnabled},
        'chat': {'online': chatOnline, 'maxLength': chatMaxLength, 'perMinute': chatPerMinute},
        'voice': {
          'online': voiceOnline,
          'maxSeconds': voiceMaxSeconds,
        },
      };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    const d = AppSettings();
    if (json == null) return d;
    Map<String, dynamic> section(String key) => json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : {};
    final online = section('online'), chat = section('chat'), voice = section('voice');
    bool flag(Map<String, dynamic> m, String key, bool fallback) => m[key] is bool ? m[key] as bool : fallback;
    int number(Map<String, dynamic> m, String key, int fallback, (int, int) range) {
      final value = (m[key] as num?)?.toInt() ?? fallback;
      return value.clamp(range.$1, range.$2);
    }

    return AppSettings(
      onlineEnabled: flag(online, 'enabled', d.onlineEnabled),
      chatOnline: flag(chat, 'online', d.chatOnline),
      chatMaxLength: number(chat, 'maxLength', d.chatMaxLength, chatLengthRange),
      chatPerMinute: number(chat, 'perMinute', d.chatPerMinute, chatPerMinuteRange),
      voiceOnline: flag(voice, 'online', d.voiceOnline),
      voiceMaxSeconds: number(voice, 'maxSeconds', d.voiceMaxSeconds, voiceSecondsRange),
    );
  }

  AppSettings copyWith({
    bool? onlineEnabled,
    bool? chatOnline,
    int? chatMaxLength,
    int? chatPerMinute,
    bool? voiceOnline,
    int? voiceMaxSeconds,
  }) =>
      AppSettings.fromJson({
        ...AppSettings(
          onlineEnabled: onlineEnabled ?? this.onlineEnabled,
          chatOnline: chatOnline ?? this.chatOnline,
          chatMaxLength: chatMaxLength ?? this.chatMaxLength,
          chatPerMinute: chatPerMinute ?? this.chatPerMinute,
          voiceOnline: voiceOnline ?? this.voiceOnline,
          voiceMaxSeconds: voiceMaxSeconds ?? this.voiceMaxSeconds,
        ).toJson(),
      });

  // =================================================================
  // التحميل والحفظ
  // =================================================================
  static const _localKey = 'app_settings';

  /// تحميل: الأول من الجهاز (سريع)، وبعدين من Supabase لو متاح
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(_localKey);
      if (local != null) _apply(AppSettings.fromJson(jsonDecode(local) as Map<String, dynamic>));
    } catch (e) {
      debugPrint('Local settings could not be read: $e');
    }
    if (!AppConfig.hasSupabase) return;
    try {
      final row = await Supabase.instance.client.from('karta_settings').select('data').eq('id', 'global').maybeSingle();
      if (row != null) await _store(AppSettings.fromJson(Map<String, dynamic>.from(row['data'] as Map)));
    } catch (e) {
      debugPrint('Online settings could not be loaded (using saved copy): $e');
    }
  }

  /// أي تعديل من الأدمن (من أي جهاز) بيوصل لايف
  static void listen() {
    if (!AppConfig.hasSupabase) return;
    try {
      Supabase.instance.client
          .channel('karta-settings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'karta_settings',
            callback: (payload) {
              final data = payload.newRecord['data'];
              if (data is Map) _store(AppSettings.fromJson(Map<String, dynamic>.from(data)));
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Settings live updates unavailable: $e');
    }
  }

  /// الأدمن بيحفظ (بيرجع رسالة الخطأ أو null). السيرفر بيرفض لو مش أدمن.
  static Future<String?> save(AppSettings settings) async {
    if (!AppConfig.hasSupabase) {
      await _store(settings);
      return null;
    }
    try {
      final client = Supabase.instance.client;
      await client.from('karta_settings').upsert({
        'id': 'global',
        'data': settings.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': client.auth.currentUser?.email,
      });
      await _store(settings);
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('row-level security')) return 'Admin permission required';
      if (e.code == '42P01' || e.code == 'PGRST205') return 'Run supabase/migrations/003_settings_chat_voice.sql first';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> _store(AppSettings settings) async {
    _apply(settings);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Settings could not be saved on this device: $e');
    }
  }

  static void _apply(AppSettings settings) {
    current = settings;
    changes.value++;
  }
}
