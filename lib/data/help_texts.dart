// =================================================================
// نصوص صفحة المساعدة (عربي + فرانكو)
// -----------------------------------------------------------------
// الأجزاء العامة مكتوبة هنا. أما الأنماط والكروت فبتتعرض من بيانات اللعبة
// نفسها (allModes) فأي كارت أو نمط الأدمن يضيفه أو يعدّله بيظهر هنا تلقائياً.
// =================================================================
import 'game_modes.dart';
import 'texts.dart';

class HelpText {
  static const title = LText('إزاي نلعب كارتة؟', 'Ezay nel3ab Karta?');

  // ---------- الفكرة ----------
  static const goalTitle = LText('الفكرة', 'El Fekra');
  static const goal = LText(
    'كارتة لعبة قعدات: كل لاعب في دوره بيسحب كارت ويعمل اللي مكتوب عليه. اللي يخسر التحدي بياخد الكارت كعقوبة. '
        'لما الكومة تخلص، اللي معاه أقل كروت هو الكسبان 🏆 واللي معاه أكتر كروت هو الخسران 🤡.',
    'Karta le3bet 2a3dat: kol la3eb fe doro byes7ab kart w ye3mel elly maktoob 3aleh. Elly yekhsar el ta7addy byakhod el kart k 3o2ooba. '
        'Lama el koma tekhlas, elly ma3ah a2al kroot howa el kasban 🏆 w elly ma3ah aktar kroot howa el khasran 🤡.',
  );

  // ---------- البداية ----------
  static const startTitle = LText('إزاي تبدأ', 'Ezay tebda2');
  static const start = LText(
    '1) في الشاشة الأولى اختار "موبايل واحد" (الموبايل في النص والكل بيلعب عليه) أو "أكتر من موبايل".\n'
        '2) اكتب أسامي اللاعيبة (من 3 لـ 8). الاسم الفاضي بيبقى "لاعب 1" وهكذا، ومينفعش اسمين زي بعض.\n'
        '3) اختار نمط اللعب، وظبط إعدادات اللعبة (مؤقت الأسئلة ووقت القنبلة).\n'
        '4) دوس "يلا نلعب".',
    '1) Fel shasha el oola ekhtar "Mobile wa7ed" (el mobile fel nos wel kol byel3ab 3aleh) aw "Aktar men mobile".\n'
        '2) Ekteb asamy el la3eeba (men 3 le 8). El esm el fady byeb2a "La3eb 1" w hakaza, w mayenfa3sh esmeen zay ba3d.\n'
        '3) Ekhtar namat el le3b, w zabbat e3dadat el le3ba (mo2a2et el as2ela w wa2t el 2onbela).\n'
        '4) Dos "Yalla nel3ab".',
  );

  // ---------- الدور ----------
  static const turnTitle = LText('الدور ماشي إزاي', 'El dor mashy ezay');
  static const turn = LText(
    '• صاحب الدور (اسمه أصفر ومكتوب تحته "دورك") يدوس على الكارت عشان يسحب.\n'
        '• الكارت بيتقلب وبيظهر عليه القاعدة. اقروها ونفّذوها.\n'
        '• دوسة تانية على الكارت بتكمّل: يا الكارت يروح لحد على طول، يا بيظهر اختيار الخسران.\n'
        '• الهوست بيختار مين خسر (أو "محدش خسر") والكارت بيروح للخسران.\n'
        '• الدور بيلف على اللي بعده مع عقارب الساعة.\n'
        '• اللعبة بتخلص لما الكومة تخلص، أو لما الهوست يدوس ✕ فوق.',
    '• Sa7eb el dor (esmo asfar w maktoob ta7to "Dorak") ydoos 3al kart 3ashan yes7ab.\n'
        '• El kart byet2eleb w byezhar 3aleh el 2a3da. E2roha w naffezoha.\n'
        '• Dosa tanya 3al kart betkammel: ya el kart yerooh le 7ad 3ala tool, ya byezhar ekhtyar el khasran.\n'
        '• El host byekhtar meen khesr (aw "Ma7adesh khesr") wel kart byrooh lel khasran.\n'
        '• El dor bylef 3ala elly ba3do ma3 3a2areb el sa3a.\n'
        '• El le3ba btekhlas lama el koma tekhlas, aw lama el host ydoos ✕ fo2.',
  );

  // ---------- النتيجة ----------
  static const scoreTitle = LText('النقط والكسب والخسارة', 'El no2at wel kasb wel khsara');
  static const score = LText(
    '• كل كارت بتاخده = عقوبة. الرقم اللي جنب اسمك هو عدد كروتك.\n'
        '• الهوست بس هو اللي بيحدد مين ياخد الكارت، ومحدش يقدر يغيّر كروته بنفسه.\n'
        '• لو الهوست ادّى كارت لحد بالغلط: يدوس على اسم اللاعب، ويدوس ✕ جنب الكارت، فيتشال من غير ما اللعبة تبدأ من الأول (والتصحيح بيتسجل في السجل).\n'
        '• في الآخر اللي معاه أقل كروت بيكسب.',
    '• Kol kart btakhdo = 3o2ooba. El ra2am elly ganb esmak howa 3adad kroutak.\n'
        '• El host bas howa elly byhadded meen yakhod el kart, w ma7adesh ye2dar yghayyar kroutoh bnafso.\n'
        '• Law el host adda kart le 7ad bel ghalat: ydoos 3ala esm el la3eb, w ydoos ✕ ganb el kart, fyetshal men gher ma el le3ba tebda2 men el awel (wel tas7ee7 byetsaggel fel sigel).\n'
        '• Fel akher elly ma3ah a2al kroot byeksab.',
  );

  // ---------- الهوست ----------
  static const hostTitle = LText('الهوست (الحَكَم)', 'El Host (el 7akam)');
  static const host = LText(
    'الهوست هو الموبايل اللي في النص (في وضع موبايل واحد) أو الموبايل اللي فتح القعدة (في وضع أكتر من موبايل). الهوست بس اللي يقدر:\n'
        '• يختار الخسران أو "محدش خسر".\n'
        '• يعمل سكيب للكارت الحالي (زرار "⏭ سكيب للكارت" فوق): الكارت بيتعدّى من غير ما حد ياخده، والدور بيتنقل للي بعده.\n'
        '• يصحح الكروت (دوسة على اسم أي لاعب).\n'
        '• ينقل كارت الصمت (Q) للي كلّم الصامت.\n'
        '• ينهي اللعبة.',
    'El host howa el mobile elly fel nos (fe wad3 mobile wa7ed) aw el mobile elly fata7 el 2a3da (fe wad3 aktar men mobile). El host bas elly ye2dar:\n'
        '• Yekhtar el khasran aw "Ma7adesh khesr".\n'
        '• Ye3mel skip lel kart el 7aly (zorar "⏭ Skip lel kart" fo2): el kart byet3adda men gher ma 7ad yakhdo, wel dor byetna2al lel ba3do.\n'
        '• Ysa7a7 el kroot (dosa 3ala esm ay la3eb).\n'
        '• Yen2el kart el samt (Q) lel elly kallem el samet.\n'
        '• Yenhy el le3ba.',
  );

  // ---------- الأزرار ----------
  static const buttonsTitle = LText('الأزرار', 'El Azrar');
  static const buttons = LText(
    '🕘 السجل: كل اللي حصل في اللعبة (مين سحب إيه ومين خسر والتصحيحات).\n'
        '🔊 الصوت: تشغيل/إيقاف الأصوات.\n'
        'عربي | Franco: لغة الكلام.\n'
        'QR (عند الهوست في وضع أكتر من موبايل): كود القعدة عشان الباقيين يدخلوا.\n'
        '✕: إنهاء اللعبة (عند موبايل اللاعب: خروج من القعدة).\n'
        '⏭ سكيب للكارت: للهوست بس، وبيظهر طول ما فيه كارت مقلوب.\n'
        '🎁 كادو / 📥 على جنب / 🤐 صامت: شارات بتوضح حالة اللعبة.\n'
        '? في الشاشة الأولى: الصفحة دي.',
    '🕘 El sigel: kol elly 7asal fel le3ba (meen sa7ab eh w meen khesr wel tas7ee7at).\n'
        '🔊 El sot: tashgheel/ee2af el aswat.\n'
        '3araby | Franco: loghet el kalam.\n'
        'QR (3and el host fe wad3 aktar men mobile): code el 2a3da 3ashan el ba2yeen yedkholo.\n'
        '✕: enha2 el le3ba (3and mobile el la3eb: khoroog men el 2a3da).\n'
        '⏭ Skip lel kart: lel host bas, w byezhar tool ma fe kart ma2loob.\n'
        '🎁 Kado / 📥 3ala ganb / 🤐 Samet: sharat btewadda7 7alet el le3ba.\n'
        '? fel shasha el oola: el saf7a di.',
  );

  // ---------- أكتر من موبايل ----------
  static const multiTitle = LText('أكتر من موبايل', 'Aktar men mobile');
  static const multi = LText(
    '• الهوست يختار "أكتر من موبايل" ويبدأ اللعب، ويدوس زرار الـ QR الأصفر فوق.\n'
        '• الباقيين يعملوا سكان للـ QR بكاميرا الموبايل، أو يكتبوا الكود في خانة "عندك كود قعدة؟".\n'
        '• كل واحد يختار هو مين (دوسة على الشريط اللي فوق). بعدها يقدر يسحب الكارت من موبايله لما ييجي دوره بس.\n'
        '• كل الموبايلات بتشوف نفس الكارت ونفس الكروت في نفس اللحظة، والهوست هو اللي بيحدد الخسران.',
    '• El host yekhtar "Aktar men mobile" w yebda2 el le3b, w ydoos zorar el QR el asfar fo2.\n'
        '• El ba2yeen ye3melo scan lel QR b camera el mobile, aw yektebo el code fe khanet "3andak code 2a3da?".\n'
        '• Kol wa7ed yekhtar howa meen (dosa 3al shereet elly fo2). Ba3daha ye2dar yes7ab el kart men mobilo lama yeegy doro bas.\n'
        '• Kol el mobilat btshoof nafs el kart w nafs el kroot fe nafs el la7za, wel host howa elly byhadded el khasran.',
  );

  // ---------- المؤقتات ----------
  static const timersTitle = LText('المؤقتات والقنبلة', 'El mo2a2tat wel 2onbela');
  static const timers = LText(
    '⏱ مؤقت الأسئلة: كروت الأسئلة (زي وزن وقافية والبراندات) بتشغّل عداد أول ما تتقلب، ومدته بتتحدد من إعدادات اللعبة (أو مدة خاصة بالكارت لو الأدمن حددها). '
        'لما الوقت يخلص بيظهر "الوقت خلص!" وبيتفتح اختيار الخسران، ومفيش عقوبة تلقائية: الهوست هو اللي بيقرر.\n'
        '💣 القنبلة (J): لما تشتغل بيتختار وقت سري عشوائي (من 10 لـ 30 أو من 10 لـ 40 ثانية حسب الإعدادات). '
        'مرّروا الموبايل بسرعة! في آخر 5 ثواني التكة بتسرّع والقنبلة بتحمر. اللي الموبايل في إيده وقت الانفجار بيخسر.',
    '⏱ Mo2a2et el as2ela: kroot el as2ela (zay wazn w 2afya wel brandat) btshaghal 3addad awel ma tet2eleb, w moddeto btet7added men e3dadat el le3ba (aw modda khassa bel kart law el admin 7addedha). '
        'Lama el wa2t yekhlas byezhar "El wa2t khelis!" w byetfete7 ekhtyar el khasran, w mafeesh 3o2ooba tel2a2eya: el host howa elly by2arrar.\n'
        '💣 El 2onbela (J): lama teshtaghal byetkhtar wa2t serry 3ashwa2y (men 10 le 30 aw men 10 le 40 sanya 7asab el e3dadat). '
        'Marraro el mobile besor3a! Fe akher 5 sawany el tekka btesarra3 wel 2onbela bte7mar. Elly el mobile fe edo wa2t el enfegar byekhsar.',
  );

  // ---------- الكروت الخاصة ----------
  static const specialTitle = LText('الكروت الخاصة', 'El kroot el khassa');
  static const special = LText(
    '🤐 الصمت (Q): اللي يسحبها ياخدها ويبقى صامت، وممنوع حد يكلّمه. لو حد كلّمه، الهوست يدوس على شارة 🤐 فوق ويختار اللي اتكلم: الكارت بيتنقل له ويبقى هو الصامت. '
        'علامة 🤐 بتختفي طول ما فيه كارت شغال وبترجع لما الكارت يخلص (الصمت نفسه شغال طول الوقت).\n'
        '🎁 الكادو (10): بيتحط على جنب، وأول حد يخسر كارت بعده بياخده معاه.\n'
        '👏 التصفيق (5 و 6 و 7): أول ما الكارت يتقلب الكل يصقّف، وآخر واحد يخسر. لو مش عارفين مين، "حطّه على جنب": نفس اللاعب يعيد الدور وأول خسران ياخد الكارتين.\n'
        '🍀 حظ سعيد (3): صاحب الدور يدّي الكارت لأي حد.\n'
        '💀 حظ وحش (2): الكارت لصاحب الدور على طول.\n'
        '⚡ كروت الأكشن: ضهرها لونه مختلف ومكتوب عليه "أكشن"، عشان تعرف إن الجاي كارت أكشن من غير ما تعرف هو أنهي واحد.',
    '🤐 El samt (Q): elly yes7abha yakhodha w yeb2a samet, w mamno3 7ad ykallemo. Law 7ad kallemo, el host ydoos 3ala sharet 🤐 fo2 w yekhtar elly etkallem: el kart byetna2al lo w yeb2a howa el samet. '
        '3alamet 🤐 btekhtefy tool ma fe kart shaghal w betraga3 lama el kart yekhlas (el samt nafso shaghal tool el wa2t).\n'
        '🎁 El kado (10): byet7at 3ala ganb, w awel 7ad yekhsar kart ba3do byakhdo ma3ah.\n'
        '👏 El tasfee2 (5 w 6 w 7): awel ma el kart yet2eleb el kol ysa22af, w akher wa7ed yekhsar. Law mesh 3arfeen meen, "7otto 3ala ganb": nafs el la3eb y3eed el dor w awel khasran yakhod el karteen.\n'
        '🍀 7az sa3eed (3): sa7eb el dor yeddy el kart le ay 7ad.\n'
        '💀 7az we7esh (2): el kart le sa7eb el dor 3ala tool.\n'
        '⚡ Kroot el action: dahrha loono mokhtalef w maktoob 3aleh "ACTION", 3ashan te3raf en el gay kart action men gher ma te3raf howa anhy wa7ed.',
  );

  // ---------- الأنماط والكروت ----------
  static const modesTitle = LText('الأنماط وكل الكروت', 'El anmat w kol el kroot');
  static const modesHint = LText(
    'دي كل الأنماط الموجودة دلوقتي وكروت كل نمط. أي تعديل من لوحة الأدمن بيظهر هنا على طول.',
    'Di kol el anmat el mawgooda delwa2ty w kroot kol namat. Ay ta3deel men lo7et el admin byezhar hena 3ala tool.',
  );
  static const disabled = LText('مقفول (مش في الكومة)', 'Ma2fool (mesh fel koma)');
  static const copies = LText('× {n} في الكومة', '× {n} fel koma');
  static const timedTag = LText('⏱ بمؤقت', '⏱ b mo2a2et');
  static const playerWord = LText('صاحب الدور', 'sa7eb el dor');

  /// شرح كل نوع كارت
  static LText typeExplain(RuleType type) => switch (type) {
        RuleType.assign => const LText('اللاعيبة ينفذوا، والهوست يختار مين خسر (أو "محدش خسر").',
            'El la3eeba ynaffezo, wel host yekhtar meen khesr (aw "Ma7adesh khesr").'),
        RuleType.free => const LText('صاحب الدور يدّي الكارت لأي حد.', 'Sa7eb el dor yeddy el kart le ay 7ad.'),
        RuleType.self => const LText('الكارت لصاحب الدور على طول.', 'El kart le sa7eb el dor 3ala tool.'),
        RuleType.cadu => const LText('كادو: أول خسران بعد كده ياخده معاه.', 'Kado: awel khasran ba3d keda yakhdo ma3ah.'),
        RuleType.bomb => const LText('قنبلة بوقت سري: اللي الموبايل في إيده وقت الانفجار يخسر.',
            '2onbela b wa2t serry: elly el mobile fe edo wa2t el enfegar yekhsar.'),
        RuleType.clap => const LText('تصفيق: آخر واحد يصقّف يخسر.', 'Tasfee2: akher wa7ed ysa22af yekhsar.'),
        RuleType.silence => const LText('صمت: صاحب الدور ياخده، واللي يكلّمه ياخده منه.',
            'Samt: sa7eb el dor yakhdo, w elly ykallemo yakhdo meno.'),
      };
}
