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
  static const adminLogin = LText('دخول الأدمن', 'Dokhool el admin');
  static const email = LText('الإيميل', 'El email');
  static const password = LText('الباسورد', 'El password');
  static const login = LText('ادخل', 'Odkhol');
  static const logout = LText('خروج', 'Khoroog');
  static const loggedInAs = LText('داخل بـ {email}', 'Dakhel b {email}');
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
  static const modeImage = LText('صورة النمط', 'Soret el namat');
  static const pickImage = LText('اختار صورة', 'Ekhtar sora');
  static const removeImage = LText('شيل الصورة', 'Sheel el sora');
  static const imageFailed = LText('مقدرناش نفتح الصورة', 'Ma2dernash nefta7 el sora');
  static const extraCards = LText('كروت زيادة', 'Kroot ziada');
  static const extraCardsHint = LText(
    'كروت بقواعد جديدة غير الـ 13 العاديين، بتتضاف للكومة. اكتب اسم قصير (لحد 3 حروف) وعدد النسخ.',
    'Kroot b 2awa3ed gdeda gher el 13 el 3adeyeen, btetdaf lel koma. Ekteb esm 2osayar (l7ad 3 7orof) w 3adad el nosakh.',
  );
  static const addExtra = LText('كارت زيادة', 'Kart ziada');
  static const extraLabel = LText('اسم الكارت (لحد 3 حروف)', 'Esm el kart (l7ad 3 7orof)');
  static const copies = LText('عدد النسخ', '3adad el nosakh');
  static const extraInvalid = LText(
    'كل كارت زيادة لازم يكون ليه اسم مش متكرر (ومش زي A أو K...) وعنوان',
    'Kol kart ziada lazem ykoon leh esm mesh mekarar (w mesh zay A aw K...) w 3enwan',
  );
  static const fillRequired = LText('لازم تكتب اسم النمط وعنوان كل الـ 13 كارت', 'Lazem tekteb esm el namat w 3enwan kol el 13 kart');

  // ---------- مكتبة الكروت ----------
  static const cardLibrary = LText('مكتبة الكروت', 'Maktabet el kroot');
  static const cardLibraryHint = LText(
    'كل كروت كل الأنماط: عدّل الشكل والمحتوى والإعدادات، أو انسخ، أو اقفل، أو امسح. التعديلات بتوصل للعبة على طول.',
    'Kol kroot kol el anmat: 3addel el shakl wel mo7tawa wel e3dadat, aw ensakh, aw e2fel, aw ems7. El ta3deelat btewsal lel le3ba 3ala tool.',
  );
  static const newCard = LText('كارت جديد', 'Kart gedeed');
  static const editCard = LText('تعديل الكارت', 'Ta3deel el kart');
  static const cardsCount = LText('{n} كارت', '{n} kart');
  static const searchCards = LText('دوّر على كارت...', 'Dawwar 3ala kart...');
  static const allModes = LText('كل الأنماط', 'Kol el anmat');
  static const allTypes = LText('كل الأنواع', 'Kol el anwa3');
  static const allStatus = LText('الكل', 'El kol');
  static const enabledLabel = LText('مفعّل', 'Mfa33al');
  static const disabledLabel = LText('مقفول', 'Ma2fool');
  static const enabledHint = LText('الكارت المقفول مش بيتحط في الكومة في الألعاب الجديدة', 'El kart el ma2fool mesh byet7at fel koma fel al3ab el gdeda');
  static const cardEnabled = LText('الكارت اتفعّل ✅', 'El kart etfa33al ✅');
  static const cardDisabled = LText('الكارت اتقفل', 'El kart et2afal');
  static const cardDeleted = LText('الكارت اتمسح', 'El kart etmasa7');
  static const cardDuplicated = LText('اتعمل نسخة: {card}', 'Et3amal noskha: {card}');
  static const deleteCardConfirm = LText('تمسح الكارت {card}؟', 'Tems7 el kart {card}?');
  static const chooseMode = LText('اختار النمط', 'Ekhtar el namat');
  static const edit = LText('تعديل', 'Ta3deel');
  static const duplicate = LText('نسخ', 'Nasakh');
  static const updatedAt = LText('آخر تعديل: {date}', 'Akher ta3deel: {date}');
  static const catNormal = LText('عادي', 'Normal');
  static const catAction = LText('أكشن', 'Action');
  static const catQueen = LText('صمت (Q)', 'Samt (Q)');
  static const catBomb = LText('قنبلة', '2onbela');

  // ---------- محرر الكارت ----------
  static const tabContent = LText('المحتوى', 'El Mo7tawa');
  static const tabDesign = LText('الشكل', 'El Shakl');
  static const tabGameplay = LText('اللعب', 'El Le3b');
  static const livePreview = LText('معاينة', 'Mo3ayna');
  static const front = LText('الوش', 'El Wesh');
  static const backFace = LText('الضهر', 'El Dahr');
  static const mobile = LText('موبايل', 'Mobile');
  static const subtitleAr = LText('سطر صغير تحت العنوان (عربي)', 'Satr soghayar ta7t el 3enwan (3araby)');
  static const subtitleFr = LText('سطر صغير تحت العنوان (فرانكو)', 'Satr soghayar ta7t el 3enwan (Franco)');
  static const textAlign = LText('محاذاة الكلام', 'Mo7azat el kalam');
  static const alignCenter = LText('في النص', 'Fel nos');
  static const alignStart = LText('على الجنب', '3al ganb');
  static const titleOnBack = LText('العنوان يظهر على ضهر الكارت', 'El 3enwan yezhar 3ala dahr el kart');
  static const titleOnBackHint = LText('اللاعيبة هيشوفوا عنوان الكارت قبل ما يتقلب', 'El la3eeba hayshoofo 3enwan el kart 2abl ma yet2eleb');
  static const barColor = LText('لون شريط العنوان', 'Loon shereet el 3enwan');
  static const bgColor = LText('لون الخلفية', 'Loon el khalfeya');
  static const textColor = LText('لون الكلام', 'Loon el kalam');
  static const borderColor = LText('لون الحدود', 'Loon el 7odood');
  static const borderStyle = LText('شكل الحدود', 'Shakl el 7odood');
  static const borderSolid = LText('عادي', '3ady');
  static const borderThick = LText('تقيل', 'T2eel');
  static const borderDashed = LText('متقطع', 'Met2atta3');
  static const icon = LText('الأيقونة', 'El Ay2ona');
  static const uploadIcon = LText('ارفع أيقونة', 'Erfa3 ay2ona');
  static const iconSize = LText('حجم الأيقونة', '7agm el ay2ona');
  static const iconPosition = LText('مكان الأيقونة', 'Makan el ay2ona');
  static const iconTop = LText('فوق العنوان', 'Fo2 el 3enwan');
  static const iconBackground = LText('كبيرة ورا الكلام', 'Kbeera wara el kalam');
  static const artwork = LText('صورة خلفية للكارت', 'Soret khalfeya lel kart');
  static const uploadArtwork = LText('ارفع صورة خلفية', 'Erfa3 soret khalfeya');
  static const artworkOpacity = LText('وضوح الصورة', 'Wodoo7 el sora');
  static const pattern = LText('نقشة', 'Na2sha');
  static const patternNone = LText('من غير', 'Men gher');
  static const patternDots = LText('نقط', 'No2at');
  static const patternGrid = LText('مربعات', 'Moraba3at');
  static const patternStripes = LText('خطوط', 'Khotoot');
  static const patternAuto = LText('تلقائي', 'Tel2a2y');
  static const backColor = LText('لون ضهر الكارت', 'Loon dahr el kart');
  static const backPattern = LText('نقشة الضهر', 'Na2shet el dahr');
  static const inMode = LText('في نمط', 'Fe namat');
  static const category = LText('التصنيف', 'El Tasneef');
  static const timedCard = LText('كارت أسئلة بمؤقت', 'Kart as2ela b mo2a2et');
  static const timedCardHint = LText('العداد بيشتغل أول ما الكارت يتقلب', 'El 3addad byeshtaghal awel ma el kart yet2eleb');
  static const cardTimer = LText('مدة المؤقت', 'Moddet el mo2a2et');
  static const useGameSetting = LText('حسب إعدادات اللعبة', '7asab e3dadat el le3ba');
  static const copiesHint = LText('كل ما يزيد، الكارت يطلع أكتر', 'Kol ma yzeed, el kart yetla3 aktar');
  static const uploading = LText('بيترفع...', 'Byetrefe3...');
  static const uploaded = LText('الصورة اترفعت ✅', 'El sora etrafa3et ✅');
  static const titleRequired = LText('لازم تكتب عنوان للكارت', 'Lazem tekteb 3enwan lel kart');

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
  static const logTimeout = LText('⏰ وقت {name} خلص', '⏰ Wa2t {name} khelis');
  static const logSkip = LText('⏭ الهوست عدّى {card} (دور {name})', '⏭ El host 3adda {card} (dor {name})');
  static const logCorrection = LText('🛠 تصحيح: الهوست شال {card} من {name}', '🛠 Tas7ee7: el host shal {card} men {name}');

  // ---------- الهوست والدور ----------
  static const skipCard = LText('سكيب للكارت', 'Skip lel kart');
  static const actionCard = LText('أكشن', 'ACTION');
  static const hostDecides = LText('👀 الهوست هو اللي بيكمّل', '👀 El host howa elly bykammel');
  static const hostPicking = LText('الهوست بيختار الخسران...', 'El host byekhtar el khasran...');
  static const timeUp = LText('الوقت خلص!', 'El wa2t khelis!');
  static const yourTurnDraw = LText('👆 دورك! دوس اسحب', '👆 Dorak! Dos es7ab');
  static const turnOf = LText('دور {name}', 'Dor {name}');
  static const pickYourSeatShort = LText('اختار إنت مين فوق', 'Ekhtar enta meen fo2');
  static const pickYourSeat = LText('دوس هنا واختار إنت مين عشان تسحب في دورك', 'Dos hena w ekhtar enta meen 3ashan tes7ab fe dorak');
  static const youAre = LText('إنت {name} • استنى دورك', 'Enta {name} • Estanna dorak');
  static const youAreTurn = LText('إنت {name} • دورك! اسحب الكارت', 'Enta {name} • Dorak! Es7ab el kart');
  static const whoAreYou = LText('إنت مين؟', 'Enta meen?');
  static const whoAreYouHint = LText(
    'اختار اسمك عشان تقدر تسحب الكارت من موبايلك لما ييجي دورك. الهوست هو اللي بيحدد الخسران.',
    'Ekhtar esmak 3ashan te2dar tes7ab el kart men mobilak lama yeegy dorak. El host howa elly byhadded el khasran.',
  );
  static const justWatch = LText('أتفرج بس', 'Atfarrag bas');
  static const seatTaken = LText('محجوز', 'Ma7gooz');

  // ---------- إعدادات اللعبة ----------
  static const gameSettings = LText('إعدادات اللعبة', 'E3dadat el le3ba');
  static const questionTimer = LText('مؤقت كروت الأسئلة', 'Mo2a2et kroot el as2ela');
  static const questionTimerHint = LText(
    'بيشتغل لوحده لما كارت أسئلة يتقلب (زي وزن وقافية والبراندات). لما يخلص بيفتح اختيار الخسران، والهوست هو اللي بيقرر.',
    'Byeshtaghal lewa7do lama kart as2ela yet2eleb (zay wazn w 2afya wel brandat). Lama ykhallas byefta7 ekhtyar el khasran, wel host howa elly by2arrar.',
  );
  static const bombRange = LText('وقت القنبلة', 'Wa2t el 2onbela');
  static const bombRangeHint = LText(
    'بيتختار وقت عشوائي سري في المدى ده كل مرة القنبلة تشتغل.',
    'Byetkhtar wa2t 3ashwa2y serry fel mada da kol marra el 2onbela teshtaghal.',
  );
  static const off = LText('مقفول', 'Ma2fool');
  static const sec = LText('ث', 's');

  // ---------- الأنيميشن ----------
  static const fxLost = LText('😬 {name} خسر!', '😬 {name} khesr!');
  static const fxCorrected = LText('✔ اتشال كارت من {name}', '✔ Etshal kart men {name}');
  static const fxNobody = LText('🙌 محدش خسر', '🙌 Ma7adesh khesr');
  static const fxSkipped = LText('⏭ الكارت اتعدّى', '⏭ El kart et3adda');

  // ---------- تصحيح الكروت ----------
  static const cardsOf = LText('كروت {name}', 'Kroot {name}');
  static const correctionHint = LText(
    'لو كارت اتدى بالغلط، دوس ✕ جنبه وهيتشال (من غير ما اللعبة تبدأ من الأول).',
    'Law kart etdda bel ghalat, dos ✕ ganbo w hayetshal (men gher ma el le3ba tebda2 men el awel).',
  );
  static const noCards = LText('مفيش كروت لسه', 'Mafeesh kroot lessa');
  static const removeCardConfirm = LText('تشيل {card} من {name}؟', 'Teshil {card} men {name}?');
  static const removeCard = LText('شيله', 'Sheelo');

  // ---------- ساعة كل لاعب (الأدوار) ----------
  static const turns = LText('الأدوار والوقت', 'El adwar wel wa2t');
  static const turnActive = LText('دوره شغال', 'Doro shaghal');
  static const turnWaiting = LText('مستني', 'Mestanni');
  static const turnAnswered = LText('جاوب', 'Gaweb');
  static const turnNoAnswer = LText('ماجاوبش', 'Magawebsh');
  static const turnFinished = LText('الدور خلص', 'El dor khelis');
  static const turnSkipped = LText('اتعدّى', 'Et3adda');
  static const turnPaused = LText('واقف مؤقتاً', 'Wa2ef mo2aqatan');
  static const pause = LText('إيقاف مؤقت', 'Wa2af');
  static const resume = LText('كمّل', 'Kammel');
  static const endTurn = LText('إنهاء الدور', 'Enha2 el dor');
  static const markAnswered = LText('✔ جاوب', '✔ Gaweb');
  static const markNoAnswer = LText('✕ ماجاوبش', '✕ Magawebsh');
  static const skipPlayer = LText('عدّي الدور', '3addy el dor');
  static const totalTime = LText('الوقت الكلي', 'El wa2t el kolly');
  static const noTurns = LText('لسه محدش لعب', 'Lessa ma7adesh le3eb');
  static const turnsHint = LText(
    'كل لاعب ليه ساعة لوحده: بتبدأ لما يسحب الكارت وبتقف لما دوره يخلص، ووقته بيتسجل.',
    'Kol la3eb leeh sa3a lewa7do: btebda2 lama yes7ab el kart w bto2af lama doro ykhallas, w wa2to byetsaggel.',
  );
  static const logPlayerSkipped = LText('⏭ الهوست عدّى دور {name}', '⏭ El host 3adda dor {name}');
  static const logTurnEnded = LText('⏱ دور {name} خلص ({time})', '⏱ Dor {name} khelis ({time})');
  static const logTurnStatus = LText('📝 دور {name}: {status}', '📝 Dor {name}: {status}');

  // ---------- زرار التصفيق (التسقيف) ----------
  static const clapTap = LText('صقّف!', 'Sa22af!');
  static const clapTapped = LText('✔ صقّفت!', '✔ Sa22aft!');
  static const clapClosed = LText('التصفيق خلص', 'El tasfee2 khelis');
  static const clapWaitOpen = LText('استنى الهوست يفتح التصفيق', 'Estanna el host yefta7 el tasfee2');
  static const clapFirst = LText('{name} صقّف الأول!', '{name} sa22af el awel!');
  static const clapLast = LText('{name} صقّف الأخير!', '{name} sa22af el akher!');
  static const clapOrder = LText('ترتيب التصفيق', 'Tarteeb el tasfee2');
  static const clapNone = LText('محدش صقّف من موبايله لسه', 'Ma7adesh sa22af men mobilo lessa');
  static const clapCloseHint = LText('👆 دوس على الكارت لما الكل يصقّف', '👆 Dos 3al kart lama el kol ysa22af');
  static const clapOpenAgain = LText('افتح التصفيق تاني', 'Efta7 el tasfee2 tany');
  static const clapGiveLast = LText('اديه لـ {name} (الأخير)', 'Eddih le {name} (el akher)');
  static const logClapResult = LText('👏 أول واحد: {first} • آخر واحد: {last}', '👏 Awel wa7ed: {first} • Akher wa7ed: {last}');

  // ---------- الإجابة ----------
  static const showAnswer = LText('👁 اكشف الإجابة', '👁 Ekshef el egaba');
  static const hideAnswer = LText('اخفي الإجابة', 'Ekhfy el egaba');
  static const answer = LText('الإجابة', 'El egaba');
  static const answerHidden = LText('الإجابة مخفية', 'El egaba makhfeya');
  static const logAnswerShown = LText('👁 الهوست كشف الإجابة: {answer}', '👁 El host kashaf el egaba: {answer}');

  // ---------- الترتيب ----------
  static const liveRanking = LText('الترتيب لايف', 'LIVE RANKING');
  static const rankingHint = LText('الأقل كروت هو الأول', 'El a2al kroot howa el awel');
  static const cardsShort = LText('{n} كارت', '{n} kart');

  // ---------- محرر زرار التصفيق والإجابة ----------
  static const clapButton = LText('👏 زرار التصفيق (التسقيف)', '👏 Zorar el tasfee2');
  static const clapButtonHint = LText(
    'لما الكارت يتقلب بيظهر زرار، وكل لاعب يدوس عليه من موبايله. اللعبة بتسجل مين صقّف الأول ومين الأخير، والهوست بيقفل التصفيق.',
    'Lama el kart yet2eleb byezhar zorar, w kol la3eb ydoos 3aleh men mobilo. El le3ba btsaggel meen sa22af el awel w meen el akher, wel host bye2fel el tasfee2.',
  );
  static const clapNotAllowed = LText('متاح بس للكروت اللي بتنتهي باختيار خسران (تصفيق / اختيار / يدّيه لحد)', 'Meta7 bas lel kroot elly btentehy b ekhtyar khasran');
  static const clapDesign = LText('شكل زرار التصفيق', 'Shakl zorar el tasfee2');
  static const clapTextAr = LText('كلام الزرار (عربي)', 'Kalam el zorar (3araby)');
  static const clapTextFr = LText('كلام الزرار (فرانكو)', 'Kalam el zorar (Franco)');
  static const clapIcon = LText('إيموجي الزرار', 'Emoji el zorar');
  static const clapBg = LText('لون الزرار', 'Lon el zorar');
  static const clapFg = LText('لون الكلام', 'Lon el kalam');
  static const clapSize = LText('الحجم', 'El 7agm');
  static const sizeS = LText('صغير', 'Soghayar');
  static const sizeM = LText('وسط', 'Wasat');
  static const sizeL = LText('كبير', 'Kebeer');
  static const clapShape = LText('الشكل', 'El shakl');
  static const shapeCircle = LText('دايرة', 'Dayra');
  static const shapeRounded = LText('مدوّر', 'Medawwar');
  static const shapePill = LText('كبسولة', 'Kabsoola');
  static const shapeSquare = LText('مربع', 'Morabba3');
  static const clapRadius = LText('استدارة الزوايا', 'Estedaret el zawaya');
  static const clapPosition = LText('مكانه في الكارت', 'Makano fel kart');
  static const posTop = LText('فوق', 'Fo2');
  static const posCenter = LText('النص', 'El nos');
  static const posBottom = LText('تحت', 'Ta7t');
  static const clapBorder = LText('حدود وظل', '7odood w dell');
  static const clapAnimate = LText('نبض خفيف', 'Nabd khafeef');
  static const previewClap = LText('👏 الزرار', '👏 El zorar');
  static const answerAr = LText('الإجابة (عربي) - اختياري', 'El egaba (3araby) - ekhtyary');
  static const answerFr = LText('الإجابة (فرانكو) - اختياري', 'El egaba (Franco) - ekhtyary');
  static const answerHint = LText(
    'الإجابة بتفضل مخفية في اللعب لحد ما الهوست يدوس "اكشف الإجابة"، وبعدها بتظهر لكل اللاعيبة.',
    'El egaba betfdal makhfeya fel le3b le7ad ma el host ydoos "ekshef el egaba", w ba3daha btezhar le kol el la3eeba.',
  );

  // ---------- الشات والرسايل الصوتية ----------
  static const chat = LText('الشات', 'El chat');
  static const lobbyChat = LText('شات الانتظار', 'Chat el entezar');
  static const gameChat = LText('شات اللعب', 'Chat el le3b');
  static const chatHint = LText('اكتب رسالة...', 'Ekteb resala...');
  static const chatEmpty = LText('لسه محدش كتب حاجة. ابدأ إنت 👋', 'Lessa ma7adesh katab 7aga. Ebda2 enta 👋');
  static const chatOff = LText('الشات مقفول من الأدمن', 'El chat ma2fool men el admin');
  static const sending = LText('بيتبعت...', 'Byetba3at...');
  static const notDelivered = LText('ماوصلتش', 'Mawsaletsh');
  static const retry = LText('إعادة', 'E3ada');
  static const discard = LText('امسح', 'Emsa7');
  static const rejectTooFast = LText('بالراحة! استنى شوية قبل الرسالة الجاية', 'Bel ra7a! Estanna shwaya');
  static const rejectMuted = LText('الهوست كتمك في الشات', 'El host katamak fel chat');
  static const rejectTooLong = LText('الرسالة طويلة أوي', 'El resala taweela awy');
  static const rejectOff = LText('الشات مقفول', 'El chat ma2fool');
  static const youWord = LText('إنت', 'enta');
  static const roomPeople = LText('اللي في القعدة', 'Elly fel 2a3da');
  static const host = LText('الهوست', 'El host');
  static const online = LText('متصل', 'Motassel');
  static const offline = LText('فصل', 'Fasal');
  static const mute = LText('كتم', 'Katm');
  static const unmute = LText('فك الكتم', 'Fok el katm');
  static const kick = LText('طرد', 'Tard');
  static const kickConfirm = LText('تطرد {name} من القعدة؟', 'Tetrod {name} men el 2a3da?');
  static const kickedOut = LText('الهوست طلّعك من القعدة', 'El host tala3ak men el 2a3da');
  static const roomClosedMsg = LText('الهوست قفل القعدة', 'El host 2afal el 2a3da');
  static const yourName = LText('اسمك في الشات', 'Esmak fel chat');
  static const lobbyTitle = LText('القعدة مفتوحة', 'El 2a3da maftoo7a');
  static const lobbyHint = LText(
    'ابعت الكود أو الـ QR للاعيبة يدخلوا ويتكلموا في الشات وإنت بتكتب الأسامي.',
    'Eb3at el code aw el QR lel la3eeba yedkhlo w yetkallemo fel chat w enta btekteb el asamy.',
  );
  static const nobodyYet = LText('لسه محدش دخل', 'Lessa ma7adesh dakhal');
  static const record = LText('سجّل رسالة صوتية', 'Sagel resala sawtya');
  static const recording = LText('بيسجل...', 'Bysaggel...');
  static const stopRecording = LText('وقّف', 'Wa22af');
  static const sendVoice = LText('ابعت', 'Eb3at');
  static const uploadingVoice = LText('بيترفع...', 'Byetrefe3...');
  static const voiceOff = LText('الرسايل الصوتية مقفولة', 'El rasayel el sawtya ma2foola');
  static const voiceNote = LText('رسالة صوتية', 'Resala sawtya');
  static const saveToLibrary = LText('احفظ في مكتبتي', 'Ehfaz fe maktabty');
  static const savedToLibrary = LText('اتحفظت في مكتبتك', 'Et7afazet fe maktabtak');
  static const voiceLibrary = LText('رسايلي الصوتية', 'Rasayly el sawtya');
  static const publicVoices = LText('رسايل عامة', 'Rasayel 3amma');
  static const noVoices = LText('مفيش رسايل محفوظة لسه', 'Mafeesh rasayel mahfooza lessa');
  static const makePublic = LText('خليها عامة', 'Khalleeha 3amma');
  static const makePrivate = LText('خليها خاصة', 'Khalleeha khassa');
  static const pendingReview = LText('مستنية موافقة الأدمن', 'Mestanneya mowaf2et el admin');
  static const rejected = LText('اترفضت', 'Etrafadet');
  static const rename = LText('غيّر الاسم', 'Ghayyar el esm');
  static const sendToChat = LText('ابعتها في الشات', 'Eb3atha fel chat');
  static const sentToChat = LText('اتبعتت في الشات', 'Etba3tet fel chat');
  static const noRoomForVoice = LText('ادخل قعدة أونلاين الأول عشان تبعتها', 'Odkhol 2a3da online el awel');
  static const approve = LText('وافق', 'Wafe2');
  static const reject = LText('ارفض', 'Erfod');
  static const deleteLabel = LText('امسح', 'Emsa7');
  static const micDenied = LText('لازم تسمح للمايك عشان تسجل', 'Lazem tesma7 lel mic 3ashan tsaggel');

  // ---------- إعدادات الأونلاين (الأدمن) ----------
  static const onlineSettings = LText('إعدادات الأونلاين والشات', 'E3dadat el online wel chat');
  static const onlineEnabled = LText('وضع أكتر من موبايل (أونلاين)', 'Wad3 aktar men mobile (online)');
  static const chatOnlineLabel = LText('الشات في القعدات الأونلاين', 'El chat fel 2a3dat el online');
  static const chatOfflineNote = LText(
    'في وضع موبايل واحد مفيش شات: كلكم على نفس الموبايل، فمفيش حد تبعتله.',
    'Fe wad3 mobile wa7ed mafeesh chat: kollokom 3ala nafs el mobile.',
  );
  static const chatMaxLength = LText('أقصى طول للرسالة', 'A2sa tool lel resala');
  static const chatPerMinute = LText('أقصى رسايل في الدقيقة لكل لاعب', 'A2sa rasayel fel de2ee2a');
  static const voiceOnlineLabel = LText('الرسايل الصوتية في الأونلاين', 'El rasayel el sawtya fel online');
  static const voiceMaxSeconds = LText('أقصى مدة للتسجيل (ثانية)', 'A2sa modda (sanya)');
  static const voiceMaxKB = LText('أقصى حجم (KB)', 'A2sa 7agm (KB)');
  static const voiceAllowSave = LText('اللاعيبة يحفظوا رسايلهم', 'El la3eeba ye7fazo rasayelhom');
  static const voiceAllowPublic = LText('يقدروا يخلوها عامة', 'Ye2daro ykhallooha 3amma');
  static const voiceModeration = LText('الرسايل العامة محتاجة موافقتي', 'El rasayel el 3amma me7taga mowaf2ty');
  static const reviewVoices = LText('مراجعة الرسايل العامة', 'Moraga3et el rasayel el 3amma');
  static const nothingSavedNote = LText(
    'مفيش حاجة بتتحفظ: الشات والرسايل الصوتية بيتبعتوا جوه القعدة على طول، ومابيترفعوش على أي سيرفر، وبيتمسحوا أول ما اللعبة تتقفل.',
    'Mafeesh 7aga betet7efez: el chat wel rasayel el sawtya byetba3to gowa el 2a3da 3ala tool, w mabyetrefe3oosh 3ala ay server, w byetmes7o awel ma el le3ba tet2efel.',
  );
  static const voiceUnavailable = LText('🎤 الرسالة مش متاحة (اتبعتت قبل ما تدخل)', '🎤 El resala mesh meta7a');
  static const formatsNote = LText('الصيغ: WebM/Opus على الويب و M4A/AAC على الموبايل (أصغر حجم).', 'El seyagh: WebM/Opus 3al web w M4A/AAC 3al mobile.');

  // ---------- مكتبة الصور ----------
  static const assetLibrary = LText('مكتبة الصور', 'Maktabet el sowar');
  static const fromLibrary = LText('🖼 من المكتبة', '🖼 Men el maktaba');
  static const assetName = LText('الاسم', 'El esm');
  static const assetTags = LText('كلمات للبحث (افصل بينها بفاصلة)', 'Kalemat lel ba7s (bfasla)');
  static const builtInAsset = LText('جاهزة في التطبيق', 'Gahza fel app');
  static const uploadedAsset = LText('مرفوعة', 'Marfoo3a');
  static const usedIn = LText('مستخدمة في', 'Mostakhdama fe');
  static const editDetails = LText('تعديل الاسم والتصنيف', 'Ta3deel el esm wel tasneef');
  static const replaceImage = LText('استبدال الصورة', 'Estebdal el soora');
  static const deleted = LText('اتمسحت', 'Etmasa7et');
  static const upload = LText('رفع', 'Raf3');
  static const search = LText('بحث...', 'Ba7s...');
  static const all = LText('الكل', 'El kol');
  static const noResults = LText('مفيش نتايج', 'Mafeesh nataye2');
}
