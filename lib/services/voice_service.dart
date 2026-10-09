// =================================================================
// الرسايل الصوتية المتسجلة (من غير مكالمات لايف)
// -----------------------------------------------------------------
// 1) التسجيل: باكدج record (مجانية BSD) - على الويب بتستخدم MediaRecorder
//    الإذن بالمايك بيتطلب بس لما اللاعب يدوس "سجّل".
// 2) قبل الإرسال: اللاعب يسمع التسجيل ويقرر يبعته أو يمسحه (مفيش رفع قبل التأكيد).
// 3) الإرسال: الملف بيترفع على Supabase Storage (bucket خاص karta-voice) في فولدر
//    باسم هوية الضيف بتاعه، وبنعمل رابط مؤقت (24 ساعة) يتبعت في الشات.
// 4) المكتبة: اللاعب يحفظ الرسالة (بنفس الملف، من غير رفع تاني) خاصة أو عامة.
// الهوية: دخول كضيف مجاني (Anonymous Sign-ins) لازم يتفعّل في Supabase.
// =================================================================
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'app_settings.dart';

/// تسجيل جاهز للمعاينة (لسه مااترفعش)
class VoiceDraft {
  final String localPath; // على الويب: رابط blob، على الموبايل: ملف مؤقت
  final int durationMs;
  final String mime;
  final String ext;
  const VoiceDraft({required this.localPath, required this.durationMs, required this.mime, required this.ext});
}

/// نتيجة رفع: رابط مؤقت + مكان الملف، أو رسالة خطأ
class VoiceUpload {
  final String? url;
  final String? path;
  final String? error;
  const VoiceUpload({this.url, this.path, this.error});
}

/// رسالة محفوظة في المكتبة
class SavedVoiceNote {
  final String id;
  final String owner;
  final String ownerName;
  final String title;
  final String path;
  final int durationMs;
  final String visibility; // private / public
  final String status;     // pending / approved / rejected
  final DateTime createdAt;

  const SavedVoiceNote({
    required this.id,
    required this.owner,
    required this.ownerName,
    required this.title,
    required this.path,
    required this.durationMs,
    required this.visibility,
    required this.status,
    required this.createdAt,
  });

  factory SavedVoiceNote.fromRow(Map<String, dynamic> row) => SavedVoiceNote(
        id: row['id'] as String,
        owner: row['owner'] as String,
        ownerName: row['owner_name'] as String? ?? '',
        title: row['title'] as String? ?? '',
        path: row['path'] as String,
        durationMs: (row['duration_ms'] as num).toInt(),
        visibility: row['visibility'] as String? ?? 'private',
        status: row['status'] as String? ?? 'approved',
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class VoiceService {
  static const bucket = 'karta-voice';
  static const table = 'karta_voice_notes';
  static const linkSeconds = 24 * 3600; // الرابط المؤقت للرسالة في الشات: 24 ساعة

  static final AudioRecorder _recorder = AudioRecorder();
  static DateTime? _startedAt;
  static String _mime = 'audio/webm';
  static String _ext = 'webm';

  static SupabaseClient? get _client {
    if (!AppConfig.hasSupabase) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// الهوية: لو فيه حساب داخل (الأدمن مثلاً) نستخدمه، وإلا ندخل كضيف.
  /// بترجع رسالة خطأ أو null.
  static Future<String?> ensureIdentity() async {
    final client = _client;
    if (client == null) return 'Supabase not configured';
    if (client.auth.currentUser != null) return null;
    try {
      await client.auth.signInAnonymously();
      return null;
    } on AuthException catch (e) {
      if (e.code == 'anonymous_provider_disabled' || e.message.contains('Anonymous sign-ins are disabled')) {
        return 'Guest sign-in is off: enable Anonymous Sign-ins in Supabase (Authentication → Sign In / Providers)';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static String? get myId => _client?.auth.currentUser?.id;

  // =================================================================
  // التسجيل
  // =================================================================

  /// يبدأ التسجيل (وبيطلب إذن المايك هنا بس). بيرجع رسالة خطأ أو null.
  static Future<String?> start() async {
    try {
      if (!await _recorder.hasPermission()) return 'Microphone permission denied';
      // أصغر حجم: Opus على الويب (webm)، و AAC على الموبايل (m4a)
      var encoder = AudioEncoder.opus;
      _mime = 'audio/webm';
      _ext = 'webm';
      if (!kIsWeb || !await _recorder.isEncoderSupported(AudioEncoder.opus)) {
        encoder = AudioEncoder.aacLc;
        _mime = 'audio/mp4';
        _ext = 'm4a';
      }
      final path = kIsWeb ? '' : '${(await getTemporaryDirectory()).path}/karta_${DateTime.now().millisecondsSinceEpoch}.$_ext';
      await _recorder.start(RecordConfig(encoder: encoder, bitRate: 32000, sampleRate: 22050, numChannels: 1), path: path);
      _startedAt = DateTime.now();
      return null;
    } catch (e) {
      return 'Recording failed: $e';
    }
  }

  /// مدة التسجيل لحد دلوقتي
  static Duration get elapsed => _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// يوقف التسجيل ويرجّع التسجيل للمعاينة (أو null لو فشل)
  static Future<VoiceDraft?> stop() async {
    final started = _startedAt;
    _startedAt = null;
    try {
      final path = await _recorder.stop();
      if (path == null || started == null) return null;
      final ms = DateTime.now().difference(started).inMilliseconds;
      return VoiceDraft(localPath: path, durationMs: ms, mime: _mime, ext: _ext);
    } catch (e) {
      debugPrint('Recording stop failed: $e');
      return null;
    }
  }

  /// يلغي التسجيل ويمسحه
  static Future<void> cancel() async {
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  // =================================================================
  // الرفع (بعد ما اللاعب يأكد الإرسال بس)
  // =================================================================
  static Future<VoiceUpload> upload(VoiceDraft draft) async {
    final settings = AppSettings.current;
    if (draft.durationMs > (settings.voiceMaxSeconds + 1) * 1000) {
      return VoiceUpload(error: 'Recording is longer than ${settings.voiceMaxSeconds}s');
    }
    final identity = await ensureIdentity();
    if (identity != null) return VoiceUpload(error: identity);
    final client = _client!;
    final Uint8List bytes;
    try {
      bytes = await XFile(draft.localPath).readAsBytes();
    } catch (e) {
      return VoiceUpload(error: 'Could not read the recording: $e');
    }
    if (bytes.isEmpty) return const VoiceUpload(error: 'The recording is empty');
    if (bytes.length > settings.voiceMaxKB * 1024) {
      return VoiceUpload(error: 'Recording is too large (${bytes.length ~/ 1024} KB, max ${settings.voiceMaxKB} KB)');
    }
    final path = '${client.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.${draft.ext}';
    try {
      final storage = client.storage.from(bucket);
      await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: draft.mime, upsert: false));
      final url = await storage.createSignedUrl(path, linkSeconds);
      return VoiceUpload(url: url, path: path);
    } on StorageException catch (e) {
      if (e.statusCode == '404' || e.message.contains('Bucket not found')) {
        return const VoiceUpload(error: 'Run supabase/migrations/003_settings_chat_voice.sql first');
      }
      return VoiceUpload(error: 'Upload failed: ${e.message}');
    } catch (e) {
      return VoiceUpload(error: 'Upload failed: $e');
    }
  }

  /// رابط مؤقت لملف محفوظ (للتشغيل أو لإعادة إرساله في الشات من غير رفع تاني)
  static Future<String?> linkFor(String path) async {
    final client = _client;
    if (client == null) return null;
    try {
      return await client.storage.from(bucket).createSignedUrl(path, linkSeconds);
    } catch (e) {
      debugPrint('Voice link failed: $e');
      return null;
    }
  }

  // =================================================================
  // المكتبة
  // =================================================================

  /// حفظ رسالة (ملف اترفع خلاص) في مكتبتي. بيرجع رسالة خطأ أو null.
  static Future<String?> save({
    required String path,
    required int durationMs,
    required String title,
    required String ownerName,
    String mime = 'audio/webm',
    int sizeBytes = 1,
    bool public = false,
  }) async {
    if (!AppSettings.current.voiceAllowSave) return 'Saving voice notes is turned off';
    final identity = await ensureIdentity();
    if (identity != null) return identity;
    // الملف لازم يكون بتاعي (السيرفر كمان بيتأكد)
    if (!path.startsWith('${myId!}/')) return 'You can only save your own recordings';
    try {
      await _client!.from(table).insert({
        'path': path,
        'duration_ms': durationMs.clamp(1, 300000),
        'size_bytes': sizeBytes.clamp(1, 5242880),
        'mime': mime,
        'title': title.trim().length > 60 ? title.trim().substring(0, 60) : title.trim(),
        'owner_name': ownerName.length > 30 ? ownerName.substring(0, 30) : ownerName,
        'visibility': public && AppSettings.current.voiceAllowPublic ? 'public' : 'private',
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return null; // محفوظة قبل كده
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// رسايلي + الرسايل العامة المتوافق عليها
  static Future<(List<SavedVoiceNote>, String?)> list({bool publicOnly = false, bool pendingOnly = false}) async {
    final identity = await ensureIdentity();
    if (identity != null) return (<SavedVoiceNote>[], identity);
    try {
      var query = _client!.from(table).select();
      if (pendingOnly) {
        query = query.eq('status', 'pending');
      } else if (publicOnly) {
        query = query.eq('visibility', 'public').eq('status', 'approved');
      } else {
        query = query.eq('owner', myId!);
      }
      final rows = await query.order('created_at', ascending: false).limit(200);
      return ([for (final r in rows) SavedVoiceNote.fromRow(r)], null);
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == 'PGRST205') return (<SavedVoiceNote>[], 'Run supabase/migrations/003_settings_chat_voice.sql first');
      return (<SavedVoiceNote>[], e.message);
    } catch (e) {
      return (<SavedVoiceNote>[], e.toString());
    }
  }

  static Future<String?> update(String id, {String? title, String? visibility, String? status}) async {
    try {
      await _client!.from(table).update({
        'title': ?title,
        'visibility': ?visibility,
        'status': ?status,
      }).eq('id', id);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// مسح من المكتبة (والملف كمان لو أنا صاحبه)
  static Future<String?> delete(SavedVoiceNote note) async {
    try {
      await _client!.from(table).delete().eq('id', note.id);
      await _client!.storage.from(bucket).remove([note.path]);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
