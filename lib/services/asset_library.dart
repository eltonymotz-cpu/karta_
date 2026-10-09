// =================================================================
// مكتبة الصور المرفوعة (جدول karta_assets + bucket الصور karta-images)
// -----------------------------------------------------------------
// الأدمن بس يقدر يرفع/يعدّل/يمسح (السيرفر نفسه بيتأكد بـ RLS).
// المسح آمن: مابنمسحش صورة مستخدمة في أي كارت أو نمط.
// =================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../data/game_modes.dart';
import '../data/pixel_assets.dart';
import '../data/texts.dart';
import 'storage_service.dart';

class AssetLibrary {
  static const table = 'karta_assets';

  /// الصور المرفوعة (آخر نسخة اتحملت)
  static List<LibraryAsset> uploaded = [];

  static SupabaseClient? get _client {
    if (!AppConfig.hasSupabase) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// كل الصور: الجاهزة + المرفوعة
  static List<LibraryAsset> get all => [...builtInAssets, ...uploaded];

  /// تحميل الصور المرفوعة. بيرجع رسالة خطأ أو null (الجاهزة بتفضل شغالة في كل الأحوال).
  static Future<String?> load() async {
    final client = _client;
    if (client == null) return null;
    try {
      final rows = await client.from(table).select().order('created_at');
      uploaded = [for (final r in rows) _fromRow(r)];
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == 'PGRST205') return 'Run supabase/migrations/003_settings_chat_voice.sql first';
      return e.message;
    } catch (e) {
      debugPrint('Asset library unavailable: $e');
      return e.toString();
    }
  }

  static LibraryAsset _fromRow(Map<String, dynamic> r) => LibraryAsset(
        id: r['id'] as String,
        ref: r['url'] as String,
        name: LText(r['name'] as String, r['name'] as String),
        category: AssetCategory.values.firstWhere((c) => c.name == r['category'], orElse: () => AssetCategory.other),
        tags: [for (final t in (r['tags'] as List? ?? [])) t.toString()],
      );

  /// رفع صورة جديدة للمكتبة (اختيار من الجهاز + رفع + تسجيل في الجدول)
  static Future<String?> upload({required String name, required AssetCategory category, List<String> tags = const []}) async {
    final result = await StorageService.pickAndUpload(folder: 'library', maxSide: 512);
    if (result.cancelled) return null;
    if (result.error != null) return result.error;
    try {
      await _client!.from(table).insert({'name': name.trim().isEmpty ? 'Image' : name.trim(), 'category': category.name, 'tags': tags, 'url': result.url});
      await load();
      return null;
    } on PostgrestException catch (e) {
      await StorageService.deleteByUrl(result.url, library: true); // الحفظ فشل: نمسح الملف عشان مايفضلش مالوش لازمة
      return e.message;
    }
  }

  /// تعديل الاسم/التصنيف/الكلمات
  static Future<String?> update(LibraryAsset asset, {String? name, AssetCategory? category, List<String>? tags}) async {
    try {
      await _client!.from(table).update({
        'name': ?name,
        'category': ?category?.name,
        'tags': ?tags,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', asset.id!);
      await load();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// استبدال الصورة: صورة جديدة بنفس المكان في الكروت؟ لأ - الكروت بتحفظ الرابط،
  /// فبنحدّث الرابط في كل الكروت اللي بتستخدمها كمان، وبعدين نمسح القديمة.
  static Future<String?> replace(LibraryAsset asset, Future<String?> Function(String oldRef, String newRef) updateUsages) async {
    final result = await StorageService.pickAndUpload(folder: 'library', maxSide: 512);
    if (result.cancelled) return null;
    if (result.error != null) return result.error;
    try {
      await _client!.from(table).update({'url': result.url, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', asset.id!);
      final error = await updateUsages(asset.ref, result.url!);
      if (error != null) return error;
      await StorageService.deleteByUrl(asset.ref, library: true);
      await load();
      return null;
    } on PostgrestException catch (e) {
      await StorageService.deleteByUrl(result.url, library: true);
      return e.message;
    }
  }

  /// الأماكن اللي الصورة مستخدمة فيها (عشان مانمسحش صورة شغالة)
  static List<String> usages(String ref) {
    final places = <String>[];
    for (final entry in allModes.entries) {
      final mode = entry.value;
      if (mode.image == ref) places.add('${mode.name.ar} (صورة النمط)');
      for (final card in cardsOf(entry.key)) {
        final d = card.rule.design;
        if (d.iconUrl == ref || d.artworkUrl == ref) places.add('${mode.name.ar} • ${card.rank}');
      }
    }
    return places;
  }

  /// مسح صورة مرفوعة (بيرفض لو مستخدمة)
  static Future<String?> delete(LibraryAsset asset) async {
    final used = usages(asset.ref);
    if (used.isNotEmpty) return 'In use: ${used.take(5).join(', ')}';
    try {
      await _client!.from(table).delete().eq('id', asset.id!);
      await StorageService.deleteByUrl(asset.ref, library: true);
      await load();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }
}
