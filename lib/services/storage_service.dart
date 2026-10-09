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

    // التحقق من النوع
    final ext = _extension(file.name, file.mimeType);
    final contentType = allowedTypes[ext];
    if (contentType == null) {
      return UploadResult(error: 'Unsupported file type (.$ext). Use PNG, JPG, WEBP or GIF');
    }
    final bytes = await file.readAsBytes();
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
  static Future<void> deleteByUrl(String? url) async {
    final path = pathFromUrl(url);
    if (path == null || !AppConfig.hasSupabase) return;
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
