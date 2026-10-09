// مسح ملف مؤقت (على الموبايل والكمبيوتر)
import 'dart:io';

void deleteTempFile(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {}
}
