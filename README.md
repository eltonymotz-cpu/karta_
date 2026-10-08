# كارتة KARTA 🃏

لعبة كروت للقعدات (Flutter): على موبايل واحد في النص، أو على أكتر من موبايل عن طريق Supabase.

## التشغيل

| الأمر | الوظيفة |
|---|---|
| `flutter run -d chrome` | تجربة سريعة في المتصفح |
| `flutter build web` ثم `node tool/serve.js` | نسخة الويب النهائية على http://localhost:8080 |
| `flutter build apk` | ملف APK للأندرويد (محتاج Android SDK) |

## تظبيط وضع "أكتر من موبايل" (Supabase)

1. اعمل مشروع على [supabase.com](https://supabase.com).
2. من **Project Settings → API Keys** انسخ الـ **Project URL** والـ **Publishable key** وحطهم في `lib/config.dart`.
3. من **SQL Editor** شغّل ملف `supabase/setup.sql` (عشان الأنماط اللي الأدمن بيضيفها تتحفظ أونلاين).
4. ارفع نسخة الويب (`build/web`) على أي استضافة (Netlify / Vercel / GitHub Pages) وحط رابطها في `joinBaseUrl` في `lib/config.dart`.
   ده الرابط اللي بيتحط في الـ QR، فلازم يكون رابط على النت مش localhost.

**إزاي بيشتغل:** صاحب القعدة يختار "أكتر من موبايل" ويبدأ اللعب → يدوس زرار الـ QR الأصفر فوق →
الباقيين يعملوا سكان بكاميرا الموبايل (أو يكتبوا الكود في الشاشة الأولى) ويتفرجوا على الكارت بيتقلب عندهم لايف.
صاحب القعدة بس هو اللي بيتحكم.

## لوحة الأدمن (مخفية)

في الشاشة الأولى: **دوس على اللوجو 5 مرات ورا بعض** → اكتب الرقم السري (`adminPin` في `lib/config.dart`، الافتراضي `2468`).
من هناك تقدر تضيف نمط جديد بـ 13 كارت (A لـ 2)، أو تعدّل وتمسح الأنماط اللي ضفتها.
الأنماط بتظهر في شاشة الإعداد على طول.

> ⚠️ الرقم السري جوه التطبيق، فده مش حماية حقيقية: أي حد معاه الـ publishable key يقدر يكتب في جدول الأنماط.
> كفاية للعب بين أصحاب، بس لو هتنشر التطبيق للناس ضيف Supabase Auth.

## فين أعدّل إيه؟

| عايز تغيّر... | الملف |
|---|---|
| Supabase والرقم السري ورابط الـ QR | `lib/config.dart` |
| قواعد الكروت والأنماط الأساسية | `lib/data/game_modes.dart` |
| أي كلام (عربي أو فرانكو) | `lib/data/texts.dart` |
| الألوان والستايل | `lib/theme.dart` |
| منطق اللعب والمزامنة بين الموبايلات | `lib/game/game_controller.dart` |
| الاتصال بالقعدة أونلاين | `lib/services/room_service.dart` |
| حفظ أنماط الأدمن | `lib/services/mode_store.dart` |
| شكل الكارت | `lib/widgets/big_card.dart` |
| الشاشات | `lib/screens/` |
| الأصوات | `assets/sounds/*.wav` و `lib/services/sound_service.dart` |
| اللوجو | `assets/images/logo.png` |
