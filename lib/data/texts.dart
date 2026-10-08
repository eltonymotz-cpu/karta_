// =================================================================
// النصوص بلغتين: عربي و فرانكو
// -----------------------------------------------------------------
// كل نص في التطبيق عبارة عن LText فيه نسختين: ar (عربي) و fr (فرانكو).
// لإضافة نص جديد: أضفه في كلاس UiText بالشكل نفسه.
// الكلمات بين قوسين {} مثل {name} تُستبدل بقيم حقيقية وقت التشغيل.
// =================================================================

/// اللغات المتاحة في التطبيق
enum AppLang { ar, franco }

/// نص بلغتين
class LText {
  final String ar; // النسخة العربية
  final String fr; // نسخة الفرانكو
  const LText(this.ar, this.fr);

  /// ترجع النص حسب اللغة المختارة
  String of(AppLang lang) => lang == AppLang.ar ? ar : fr;

  /// تحويل لـ JSON (عشان نحفظه في Supabase أو نبعته للموبايلات التانية)
  Map<String, dynamic> toJson() => {'ar': ar, 'fr': fr};

  /// قراءة من JSON
  factory LText.fromJson(Map<String, dynamic> json) =>
      LText(json['ar'] as String? ?? '', json['fr'] as String? ?? '');
}

/// تستبدل الكلمات بين {} في النص بقيم حقيقية (للغتين مرة واحدة)
/// القيمة ممكن تكون نص عادي String أو LText (فيأخذ النسخة المناسبة لكل لغة)
LText fillText(LText template, Map<String, Object> vars) {
  String apply(String s, AppLang lang) {
    var result = s;
    vars.forEach((key, value) {
      final replacement = value is LText ? value.of(lang) : value.toString();
      result = result.replaceAll('{$key}', replacement);
    });
    return result;
  }

  return LText(apply(template.ar, AppLang.ar), apply(template.fr, AppLang.franco));
}

/// كل نصوص الواجهة
class UiText {
  // ---------- الشاشة الأولى ----------
  static const homeTitle = LText('هتلعبوا\nإزاي؟', 'Hatel3abo\nEzay?');
  static const homeSubtitle = LText('اختاروا طريقة اللعب', 'Ekhtaro tare2et el le3b');
  static const singleDevice = LText('موبايل واحد', 'Mobile Wa7ed');
  static const singleDeviceDesc = LText('الموبايل في النص والكل بيلعب عليه', 'El mobile fel nos w el kol byel3ab 3aleh');
  static const multiDevice = LText('أكتر من موبايل', 'Aktar Men Mobile');
  static const multiDeviceDesc = LText('اعمل قعدة والباقي يدخل بالـ QR ويشوف الكارت عنده', 'E3mel 2a3da w el ba2y yedkhol bel QR w yshoof el kart 3ando');
  static const joinTitle = LText('عندك كود قعدة؟', '3andak code 2a3da?');
  static const joinHint = LText('اكتب الكود', 'Ekteb el code');
  static const join = LText('ادخل', 'Odkhol');
  static const noSupabase = LText(
    'وضع أكتر من موبايل محتاج Supabase. حط البيانات في lib/config.dart',
    'Wad3 aktar men mobile me7tag Supabase. 7ot el data fe lib/config.dart',
  );

  // ---------- أكتر من جهاز ----------
  static const roomCode = LText('كود القعدة', 'Code el 2a3da');
  static const scanToJoin = LText('امسح الكود عشان تدخل', 'Ems7 el code 3ashan todkhol');
  static const close = LText('قفل', '2afel');
  static const waitingHost = LText('مستنيين صاحب القعدة يبدأ...', 'Mestanyeen sa7eb el 2a3da yebda2...');
  static const connecting = LText('بيتصل...', 'Byetesel...');
  static const leave = LText('اخرج', 'Okhrog');
  static const viewerHint = LText('👀 إنت بتتفرج - صاحب القعدة هو اللي بيلعب', '👀 Enta btetfarag - sa7eb el 2a3da howa elly byel3ab');

  // ---------- الأدمن ----------
  static const adminPinTitle = LText('الرقم السري', 'El Ra2am El Serry');
  static const wrongPin = LText('الرقم غلط', 'El ra2am ghalat');
  static const adminTitle = LText('لوحة\nالأدمن', 'Lo7et\nEl Admin');
  static const adminSubtitle = LText('ضيف أنماط جديدة: كل نمط 13 كارت من A لـ 2', 'Daif anmat gdeda: kol namat 13 kart men A le 2');
  static const newMode = LText('نمط جديد', 'Namat Gedeed');
  static const editMode = LText('تعديل النمط', 'Ta3deel El Namat');
  static const noCustomModes = LText('لسه مفيش أنماط متضافة', 'Lessa mafeesh anmat metdafa');
  static const builtIn = LText('أساسي', 'Asasy');
  static const edited = LText('معدّل', 'Met3addel');
  static const resetConfirm = LText('ترجّع النمط ده لأصله؟ تعديلاتك هتتمسح', 'Terga3 el namat da l asloh? Ta3deelatak hatetmese7');
  static const reset = LText('رجّع الأصلي', 'Raga3 el asly');
  static const deleteConfirm = LText('تمسح النمط ده؟', 'Tems7 el namat da?');
  static const delete = LText('امسح', 'Ems7');
  static const save = LText('احفظ', 'E7faz');
  static const saved = LText('اتحفظ ✅', 'Et7afaz ✅');
  static const savedLocalOnly = LText('اتحفظ على الجهاز ده بس (Supabase مش متظبط)', 'Et7afaz 3al gehaz da bas (Supabase mesh metzabat)');
  static const saveFailed = LText('الحفظ أونلاين فشل: {error}', 'El 7efz online feshel: {error}');
  static const back = LText('رجوع', 'Rogo3');
  static const modeInfo = LText('بيانات النمط', 'Bayanat El Namat');
  static const modeNameAr = LText('اسم النمط (عربي)', 'Esm el namat (3araby)');
  static const modeNameFr = LText('اسم النمط (فرانكو)', 'Esm el namat (Franco)');
  static const modeDescAr = LText('وصف النمط (عربي)', 'Wasf el namat (3araby)');
  static const modeDescFr = LText('وصف النمط (فرانكو)', 'Wasf el namat (Franco)');
  static const emoji = LText('إيموجي', 'Emoji');
  static const copyFrom = LText('ابدأ من نمط موجود', 'Ebda2 men namat mawgood');
  static const theCards = LText('الـ 13 كارت', 'El 13 Kart');
  static const playerTip = LText('اكتب {player} في الشرح ويتبدّل باسم صاحب الدور', 'Ekteb {player} fel shar7 w yetbaddel b esm sa7eb el dor');
  static const ruleTitleAr = LText('العنوان (عربي)', 'El 3enwan (3araby)');
  static const ruleTitleFr = LText('العنوان (فرانكو)', 'El 3enwan (Franco)');
  static const ruleDescAr = LText('الشرح (عربي)', 'El shar7 (3araby)');
  static const ruleDescFr = LText('الشرح (فرانكو)', 'El shar7 (Franco)');
  static const rulePromptAr = LText('سؤال اختيار الخسران (عربي)', 'So2al ekhtyar el khasran (3araby)');
  static const rulePromptFr = LText('سؤال اختيار الخسران (فرانكو)', 'So2al ekhtyar el khasran (Franco)');
  static const ruleType = LText('نوع الكارت', 'No3 el kart');
  static const silence = LText('يفعّل وضع الصمت 🤐', 'Yfa33al wad3 el samt 🤐');
  static const fillRequired = LText('لازم تكتب اسم النمط وعنوان كل الـ 13 كارت', 'Lazem tekteb esm el namat w 3enwan kol el 13 kart');

  // أسماء أنواع الكروت في لوحة الأدمن
  static const typeAssign = LText('اللاعيبة يختاروا الخسران', 'El la3eeba yekhtaro el khasran');
  static const typeFree = LText('صاحب الدور يديه لحد', 'Sa7eb el dor yeddeeh le 7ad');
  static const typeSelf = LText('لصاحب الدور على طول', 'Le sa7eb el dor 3ala tool');
  static const typeCadu = LText('كادو (لأول خسران)', 'Kado (le awel khasran)');
  static const typeBomb = LText('قنبلة موقوتة', '2onbela maw2ota');
  static const typeClap = LText('تصفيق (آخر واحد يخسر)', 'Tasfee2 (akher wa7ed yekhsar)');

  // ---------- شاشة الإعداد ----------
  static const setupTitle = LText('جهّز\nالقعدة', 'Gahez\nEl 2a3da');
  static const subtitle = LText('اكتبوا أساميكم واختاروا النمط... والكارت هو الحكم!', 'Ektebo asameeko w ekhtaro el namat... w el kart howa el 7akam!');
  static const players = LText('اللاعيبة', 'El La3eeba');
  static const playersRange = LText('(من 3 لـ 8)', '(men 3 le 8)');
  static const playerLabel = LText('اللاعب {n}', 'La3eb {n}');
  static const typeName = LText('اكتب الاسم...', 'Ekteb el esm...');
  static const defaultPlayer = LText('لاعب {n}', 'La3eb {n}');
  static const addPlayer = LText('ضيف لاعب', 'Daif la3eb');
  static const mode = LText('نمط اللعب', 'Namat el le3b');
  static const start = LText('يلا نلعب 🚀', 'Yalla nel3ab 🚀');
  static const duplicateNames = LText('فيه أسامي متكررة! غيّرها 🙏', 'Fe asamy mekarara! Ghayarha 🙏');

  // ---------- الشريط العلوي ----------
  static const history = LText('السجل', 'El Sigel');
  static const end = LText('إنهاء', 'Khalas');
  static const confirmEnd = LText('متأكد عايز تنهي اللعبة؟', 'Met2aked 3ayez tenhy el le3ba?');
  static const yes = LText('أيوه', 'Aywa');
  static const no = LText('لأ', 'La2');
  static const noHistory = LText('لسه مفيش أحداث', 'Lessa mafeesh a7das');

  // ---------- المقاعد والحالة ----------
  static const yourTurn = LText('دورك', 'Dorak');
  static const caduChip = LText('🎁 كادو مستني ({n})', '🎁 Kado mestanny ({n})');
  static const silentChip = LText('🤐 ممنوع تكلموا {name}', '🤐 Mamno3 tkalemo {name}');
  static const silentChipTap = LText('🤐 {name} صامت • حد كلّمه؟ دوس هنا', '🤐 {name} samet • 7ad kallemo? Dos hena');
  static const whoTalked = LText('مين كلّم {name}؟', 'Meen kallem {name}?');
  static const whoTalkedHint = LText('اللي هتختاره ياخد الكارت ويبقى هو الصامت', 'Elly hatekhtaro yakhod el kart w yeb2a howa el samet');
  static const cancel = LText('إلغاء', 'Elgha2');
  static const silenceHint = LText('👆 دوس وخد الكارت 🤐', '👆 Dos w khod el kart 🤐');
  static const logSilentTake = LText('🤐 {name} خد {card} وبقى صامت', '🤐 {name} khad {card} w ba2a samet');
  static const logSilencePass = LText('🤐 {to} كلّم {from} وخد منه {card}', '🤐 {to} kallem {from} w khad meno {card}');
  static const typeSilence = LText('صمت (اللي يكلّمه ياخد الكارت)', 'Samt (elly ykallemo yakhod el kart)');

  // ---------- الكارت ----------
  static const cardsLeft = LText('كارت فاضل', 'kart fadel');
  static const tapToDraw = LText('👆 دوس اسحب', '👆 Dos es7ab');
  static const tapToChoose = LText('👆 دوس على الكارت أو على اسم الخسران', '👆 Dos 3al kart aw 3ala esm el khasran');
  static const tapToGive = LText('👆 دوس على الكارت أو على اسم اللي هتديه', '👆 Dos 3al kart aw 3ala esm elly hatedeeh');
  static const tapToTake = LText('👆 دوس وخدها 😅', '👆 Dos w khodha 😅');
  static const tapNext = LText('👆 دوس للدور اللي بعده', '👆 Dos lel dor elly ba3do');
  static const tapStartBomb = LText('👆 دوس عشان تشغّل القنبلة', '👆 Dos 3ashan tshaghal el 2onbela');
  static const passPhone = LText('مرّروا الموبايل بسرعة!', 'Marraro el mobile besor3a!');
  static const anyMoment = LText('هتنفجر في أي لحظة... 😬', 'Hatenfeger fe ay la7za... 😬');
  static const boom = LText('بووووم!', 'BOOOOM!');
  static const tapToPickLoser = LText('👆 دوس واختار الخسران', '👆 Dos w ekhtar el khasran');
  static const lastClapLoses = LText('آخر واحد يصقّف ياخد الكارت!', 'Akher wa7ed ysa22af yakhod el kart!');
  static const clapNow = LText('صقّف!', 'SA22AF!');
  static const nobody = LText('🙌 محدش خسر', '🙌 Ma7adesh khesr');
  static const setAside = LText('🤷 مش عارفين؟ حطّه على جنب', '🤷 Mesh 3arfeen? 7otto 3ala ganb');
  static const asideChip = LText('📥 على جنب ({n}) • أول خسران ياخدهم', '📥 3ala ganb ({n}) • awel khasran yakhodhom');
  static const asideWarn = LText('📥 الخسران هياخد كمان {n} كارت من اللي على جنب', '📥 El khasran hayakhod kaman {n} kart men elly 3ala ganb');
  static const asideLeft = LText('📥 فاضل {n} كارت على جنب من غير صاحب', '📥 Fadel {n} kart 3ala ganb men gher sa7bo');
  static const logAside = LText('📥 {card} اتحط على جنب و{name} هيعيد الدور', '📥 {card} et7at 3ala ganb w {name} hay3eed el dor');
  static const logAsideTaken = LText('📥 {name} خد الكروت اللي على جنب: {cards}', '📥 {name} khad el kroot elly 3ala ganb: {cards}');
  static const caduWarn = LText('⚠️ الخسران هياخد الكادو ({n}) معاه!', '⚠️ El khasran hayakhod el kado ({n}) ma3ah!');

  // ---------- شاشة النهاية ----------
  static const gameOver = LText('خلصت اللعبة!', 'Khelset el le3ba!');
  static const fewestWins = LText('اللي معاه أقل كروت هو الكسبان', 'Elly ma3ah a2al kroot howa el kasban');
  static const cards = LText('كارت', 'kart');
  static const playAgain = LText('🔁 العب تاني', '🔁 El3ab tany');
  static const backToSetup = LText('⚙️ رجوع للإعدادات', '⚙️ Rogo3 lel e3dadat');
  static const caduLeft = LText('🎁 فاضل {n} كادو من غير صاحب', '🎁 Fadel {n} kado men gher sa7bo');

  // ---------- سجل الأحداث ----------
  static const logStart = LText('🎬 اللعبة بدأت - {mode}', '🎬 El le3ba bada2et - {mode}');
  static const logDraw = LText('🃏 {name} سحب {card} - {rule}', '🃏 {name} sa7ab {card} - {rule}');
  static const logTake = LText('📌 {name} خد {card}', '📌 {name} khad {card}');
  static const logCadu = LText('🎁 {name} خد الكادو: {cards}', '🎁 {name} khad el kado: {cards}');
  static const logNobody = LText('🙌 محدش خسر الدور ده', '🙌 Ma7adesh khesr el dor da');
  static const logCaduWait = LText('🎁 الكادو مستني أول خسران...', '🎁 El kado mestanny awel khasran...');
  static const logBoom = LText('💥 القنبلة انفجرت!', '💥 El 2onbela enfagaret!');
}
