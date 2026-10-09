// =================================================================
// رفع الصور (صور الأنماط وأيقونات وخلفيات الكروت) على Supabase Storage
// -----------------------------------------------------------------
// - الصورة بتترفع في bucket اسمه karta-images (شوف supabase/migrations)
// - اللي بيتحفظ في بيانات الكارت هو الرابط الدائم للصورة (مش ملف مؤقت)
// - الرفع محتاج تسجيل دخول الأدمن (الصلاحيات متظبطة في Supabase نفسه)
// =================================================================
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// نتيجة اختيار ورفع صورة: يا رابط، يا رسالة خطأ، يا null لو المستخدم لغى
class UploadResult {
  final String? url;
  final String? error;
  const UploadResult({this.url, this.error});
  bool get cancelled => url == null && error == null;
}

class StorageService {
  static const bucket = 'karta-images';
  static const maxBytes = 2 * 1024 * 1024; // أقصى حجم: 2 ميجا

  /// الأنواع المسموحة (الامتداد ← نوع الملف)
  static const allowedTypes = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  /// اختيار صورة من الجهاز ورفعها. folder = مكانها جوه الـ bucket (modes / icons / artwork)
  static Future<UploadResult> pickAndUpload({required String folder, double maxSide = 800}) async {
    if (!AppConfig.hasSupabase) return const UploadResult(error: 'Supabase not configured (lib/config.dart)');
    if (Supabase.instance.client.auth.currentUser == null) {
      return const UploadResult(error: 'Admin login required');
    }
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: 82,
      );
    } catch (e) {
      return UploadResult(error: 'Could not open the image: $e');
    }
    if (file == null) return const UploadResult(); // المستخدم لغى

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      return UploadResult(error: 'Could not read the image: $e');
    }
    if (bytes.isEmpty) return const UploadResult(error: 'The image file is empty');
    // التحقق من النوع: من محتوى الملف نفسه (أول بايتات) مش من اسمه،
    // لأن على الويب الاسم ساعات بيبقى من غير امتداد أو امتداده غلط
    final ext = sniffImageType(bytes) ?? _extension(file.name, file.mimeType);
    final contentType = allowedTypes[ext];
    if (contentType == null) {
      return UploadResult(error: 'Unsupported file type (.$ext). Use PNG, JPG, WEBP or GIF');
    }
    // التحقق من الحجم
    if (bytes.length > maxBytes) {
      return UploadResult(error: 'Image is too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB, max 2 MB)');
    }
    return upload(bytes, ext, contentType, folder);
  }

  /// رفع بايتات صورة وإرجاع الرابط الدائم
  static Future<UploadResult> upload(Uint8List bytes, String ext, String contentType, String folder) async {
    try {
      final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$ext';
      final storage = Supabase.instance.client.storage.from(bucket);
      await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: false));
      return UploadResult(url: storage.getPublicUrl(path));
    } on StorageException catch (e) {
      // أشهر الأسباب: الـ bucket مش موجود، أو الحساب مش أدمن
      return UploadResult(error: 'Upload failed: ${e.message}${e.statusCode == null ? '' : ' (${e.statusCode})'}');
    } catch (e) {
      return UploadResult(error: 'Upload failed: $e');
    }
  }

  /// مسح صورة قديمة (لو كانت مرفوعة على الـ bucket بتاعنا). أي خطأ بيتجاهل
  /// عشان مسح صورة قديمة مايبوّظش حفظ الكارت.
  static Future<void> deleteByUrl(String? url, {bool library = false}) async {
    final path = pathFromUrl(url);
    if (path == null || !AppConfig.hasSupabase) return;
    // صور مكتبة الصور مشتركة بين كذا كارت: مابتتمسحش غير من شاشة المكتبة نفسها
    if (path.startsWith('library/') && !library) return;
    try {
      await Supabase.instance.client.storage.from(bucket).remove([path]);
    } catch (_) {}
  }

  /// استخراج مسار الملف من رابطه العام
  static String? pathFromUrl(String? url) {
    if (url == null) return null;
    const marker = '/storage/v1/object/public/$bucket/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    return Uri.decodeComponent(url.substring(index + marker.length));
  }

  /// نوع الصورة من أول بايتات الملف (png / jpg / gif / webp) أو null لو مش صورة معروفة
  static String? sniffImageType(Uint8List b) {
    bool starts(List<int> sig, [int offset = 0]) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'png';
    if (starts([0xFF, 0xD8, 0xFF])) return 'jpg';
    if (starts([0x47, 0x49, 0x46, 0x38])) return 'gif';
    if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) return 'webp';
    return null;
  }

  static String _extension(String name, String? mimeType) {
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) return name.substring(dot + 1).toLowerCase();
    // على الويب الاسم ساعات مابيبقاش فيه امتداد، فناخده من نوع الملف
    for (final entry in allowedTypes.entries) {
      if (entry.value == mimeType) return entry.key;
    }
    return 'unknown';
  }
}
