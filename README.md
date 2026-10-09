# كارتة KARTA 🃏

لعبة كروت للقعدات (Flutter): على موبايل واحد في النص، أو على أكتر من موبايل عن طريق Supabase.

🌐 **العب أونلاين:** https://karta-flame-pi.vercel.app

## رفع نسخة جديدة على Vercel

```
flutter build web
vercel.cmd deploy --prod
```

`vercel.json` و `.vercelignore` بيخلّوا Vercel يرفع فولدر `build/web` الجاهز بس.

## التشغيل والاختبارات

| الأمر | الوظيفة |
|---|---|
| `flutter run -d chrome` | تجربة سريعة في المتصفح |
| `flutter build web` ثم `node tool/serve.js` | نسخة الويب النهائية على http://localhost:8080 |
| `flutter test` | اختبارات منطق اللعبة (السكيب، الصلاحيات، المؤقتات، الكروت...) |
| `flutter analyze` | فحص الكود |
| `flutter build apk` | ملف APK للأندرويد (محتاج Android SDK) |

## تظبيط Supabase

1. من **Project Settings → API Keys** حط الـ **Project URL** والـ **Publishable key** في `lib/config.dart`.
2. من **SQL Editor** شغّل الملفات دي بالترتيب (آمنة لو اتشغلت أكتر من مرة، ومش بتمسح بيانات):
   - `supabase/setup.sql` (جدول الأنماط)
   - `supabase/migrations/002_admin_auth_storage_realtime.sql` (حماية الأدمن + رفع الصور + التحديث اللايف)
     **قبل ما تشغّله:** غيّر `YOUR_ADMIN_EMAIL@example.com` لإيميل الأدمن.
3. من **Authentication → Users → Add user** اعمل يوزر بنفس إيميل الأدمن وباسورد.
   ويُفضّل تقفل التسجيل العام: **Authentication → Sign In / Providers → Allow new users to sign up** (Off).
4. حط رابط نسخة الويب في `joinBaseUrl` في `lib/config.dart` (ده اللي بيتحط في الـ QR).

## أكتر من موبايل

الهوست يختار "أكتر من موبايل" ويبدأ اللعب → يدوس زرار الـ QR الأصفر → الباقيين يعملوا سكان أو يكتبوا الكود.
كل واحد يختار هو مين (الشريط اللي فوق)، وبعدها يقدر يسحب الكارت من موبايله في دوره بس.
الهوست بس هو اللي بيختار الخسران، وبيعمل سكيب، وبيصحح الكروت. أي طلب تاني من موبايل لاعب بيتجاهل عند الهوست.

## لوحة الأدمن (مخفية)

في الشاشة الأولى: **دوس على اللوجو 5 مرات ورا بعض** → سجّل دخول بإيميل وباسورد الأدمن.
- **مكتبة الكروت**: كل الكروت في كل الأنماط، بحث وفلترة، تعديل الشكل والمحتوى والإعدادات مع معاينة لايف،
  نسخ، تفعيل/قفل، مسح (الكروت الزيادة)، وكارت جديد.
- **الأنماط**: نمط جديد، تعديل، صورة للنمط، ورجوع الأنماط الأساسية لأصلها.
- الصور بتترفع على Supabase Storage (bucket `karta-images`) واللي بيتحفظ هو رابطها.
- الحفظ والرفع محميين في Supabase نفسه (RLS)، فحتى لو حد فتح اللوحة مش هيقدر يحفظ غير لو كان أدمن.
- لو Supabase مش متظبط، اللوحة بتفتح بالرقم السري (`adminPin`) وبتحفظ على الجهاز بس.

## فين أعدّل إيه؟

| عايز تغيّر... | الملف |
|---|---|
| Supabase والرقم السري ورابط الـ QR | `lib/config.dart` |
| قواعد الكروت والأنماط الأساسية | `lib/data/game_modes.dart` |
| أي كلام (عربي أو فرانكو) | `lib/data/texts.dart` |
| صفحة المساعدة | `lib/data/help_texts.dart` و `lib/screens/help_screen.dart` |
| الألوان والستايل وشكل كل كارت | `lib/theme.dart` |
| منطق اللعب والمزامنة والصلاحيات | `lib/game/game_controller.dart` |
| مؤقت الأسئلة ووقت القنبلة | `lib/game/game_settings.dart` |
| الاتصال بالقعدة أونلاين | `lib/services/room_service.dart` |
| حفظ الأنماط والكروت | `lib/services/mode_store.dart` |
| رفع الصور | `lib/services/storage_service.dart` |
| دخول الأدمن | `lib/services/admin_auth.dart` |
| شكل الكارت (وشه وضهره) | `lib/widgets/card_face.dart` و `lib/widgets/big_card.dart` |
| الأنيميشن | `lib/widgets/game_fx.dart` |
| الشاشات | `lib/screens/` |
| الأصوات | `assets/sounds/*.wav` و `lib/services/sound_service.dart` |
