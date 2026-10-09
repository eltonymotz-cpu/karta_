// =================================================================
// الرسايل الصوتية المتسجلة (من غير مكالمات لايف ومن غير أي حفظ)
// -----------------------------------------------------------------
// 1) التسجيل: باكدج record (مجانية BSD) - على الويب بتستخدم MediaRecorder.
//    إذن المايك بيتطلب بس لما اللاعب يدوس "سجّل".
// 2) قبل الإرسال: اللاعب يسمع التسجيل ويقرر يبعته أو يمسحه.
// 3) الإرسال: الصوت نفسه (مضغوط وصغير) بيتبعت جوه الرسالة على قناة القعدة،
//    ومابيترفعش على أي سيرفر ومابيتحفظش في أي قاعدة بيانات.
//    الصوت بيفضل في ذاكرة الموبايلات بس، وبيتمسح أول ما اللعبة تتقفل.
// قناة Supabase بتشيل رسالة لحد حوالي 250 KB (اتجربت)، فالتسجيل محدود بـ 60 ثانية
// وبجودة كلام (حوالي 16–24 kbps) عشان يفضل تحت الحد بأمان.
// =================================================================
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'app_settings.dart';
import 'temp_file_io.dart' if (dart.library.js_interop) 'temp_file_web.dart';

/// تسجيل جاهز للمعاينة والإرسال (في الذاكرة بس)
class VoiceDraft {
  final Uint8List bytes;
  final int durationMs;
  final String mime;
  const VoiceDraft({required this.bytes, required this.durationMs, required this.mime});
}

class VoiceService {
  /// أقصى حجم للصوت الخام (بعد base64 بيبقى حوالي 230 KB، تحت حد القناة)
  static const maxBytes = 170 * 1024;

  static final AudioRecorder _recorder = AudioRecorder();
  static DateTime? _startedAt;
  static String _mime = 'audio/webm';

  /// يبدأ التسجيل (وبيطلب إذن المايك هنا بس). بيرجع رسالة خطأ أو null.
  static Future<String?> start() async {
    try {
      if (!await _recorder.hasPermission()) return 'Microphone permission denied';
      // أصغر حجم: Opus على الويب (webm)، و AAC على الموبايل (m4a)
      var encoder = AudioEncoder.opus;
      var bitRate = 16000;
      _mime = 'audio/webm';
      if (!kIsWeb || !await _recorder.isEncoderSupported(AudioEncoder.opus)) {
        encoder = AudioEncoder.aacLc;
        bitRate = 24000;
        _mime = 'audio/mp4';
      }
      // على الموبايل لازم ملف مؤقت (بنمسحه أول ما نقراه)، وعلى الويب بيتسجل في الذاكرة
      final path = kIsWeb ? '' : '${(await getTemporaryDirectory()).path}/karta_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(RecordConfig(encoder: encoder, bitRate: bitRate, sampleRate: 16000, numChannels: 1), path: path);
      _startedAt = DateTime.now();
      return null;
    } catch (e) {
      return 'Recording failed: $e';
    }
  }

  /// مدة التسجيل لحد دلوقتي
  static Duration get elapsed => _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// يوقف التسجيل ويرجّعه في الذاكرة. بيرجع (التسجيل، رسالة خطأ)
  static Future<(VoiceDraft?, String?)> stop() async {
    final started = _startedAt;
    _startedAt = null;
    try {
      final path = await _recorder.stop();
      if (path == null || started == null) return (null, 'Recording failed');
      final bytes = await XFile(path).readAsBytes();
      _deleteTemp(path); // الملف المؤقت مالوش لازمة بعد كده
      if (bytes.isEmpty) return (null, 'The recording is empty');
      if (bytes.length > maxBytes) return (null, 'Recording is too long, try a shorter one');
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (ms > (AppSettings.current.voiceMaxSeconds + 2) * 1000) return (null, 'Recording is too long');
      return (VoiceDraft(bytes: bytes, durationMs: ms, mime: _mime), null);
    } catch (e) {
      return (null, 'Recording failed: $e');
    }
  }

  /// يلغي التسجيل ويمسحه
  static Future<void> cancel() async {
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  static void _deleteTemp(String path) => deleteTempFile(path);
}
