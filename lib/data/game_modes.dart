// =================================================================
// أنماط اللعب وقواعد الكروت
// -----------------------------------------------------------------
// كل نمط (GameMode) فيه قاعدة (CardRule) لكل قيمة كارت (A, K, Q ...).
// لإضافة نمط جديد: انسخ نمط "party" في آخر الملف وغيّر اللي إنت عايزه.
// الخاصية basedOn: أي كارت مش موجود في النمط بياخد قاعدته من النمط المذكور.
//
// أنواع القواعد (RuleType):
//   assign → اللاعيبة يختاروا الخسران (وفيه زرار "محدش خسر")
//   free   → صاحب الدور يدي الكارت لأي حد (لازم حد ياخده)
//   self   → الكارت يروح لصاحب الدور على طول
//   cadu   → كادو: أول خسران بعد كده ياخد الكارت ده معاه
//   bomb    → قنبلة موقوتة بوقت مخفي
//   clap    → اختبار سرعة: آخر واحد يصقف يخسر
//   silence → صاحب الدور ياخد الكارت ويبقى صامت، واللي يكلّمه ياخد منه الكارت
//             ويبقى هو الصامت (بيتنقل بزرار 🤐 فوق)
// =================================================================
import 'texts.dart';

enum RuleType { assign, free, self, cadu, bomb, clap, silence }

/// قاعدة كارت واحد
class CardRule {
  final String emoji;        // إيموجي يظهر على الكارت
  final LText title;         // عنوان القاعدة
  final LText description;   // الشرح ({player} = اسم صاحب الدور)
  final RuleType type;       // نوع التعامل مع الكارت
  final LText? prompt;       // السؤال اللي يظهر فوق أسامي اللاعيبة وقت الاختيار
  final bool setsSilence;    // لو true: صاحب الدور يدخل وضع "الصمت"

  const CardRule({
    required this.emoji,
    required this.title,
    required this.description,
    required this.type,
    this.prompt,
    this.setsSilence = false,
  });

  /// تحويل لـ JSON (للحفظ في Supabase وللإرسال للموبايلات التانية)
  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'title': title.toJson(),
        'description': description.toJson(),
        'type': type.name,
        if (prompt != null) 'prompt': prompt!.toJson(),
        'silence': setsSilence,
      };

  /// قراءة من JSON
  factory CardRule.fromJson(Map<String, dynamic> json) => CardRule(
        emoji: json['emoji'] as String? ?? '🃏',
        title: LText.fromJson(Map<String, dynamic>.from(json['title'] as Map)),
        description: LText.fromJson(Map<String, dynamic>.from(json['description'] as Map)),
        type: RuleType.values.firstWhere((t) => t.name == json['type'], orElse: () => RuleType.assign),
        prompt: json['prompt'] == null ? null : LText.fromJson(Map<String, dynamic>.from(json['prompt'] as Map)),
        setsSilence: json['silence'] as bool? ?? false,
      );
}

/// نمط لعب كامل
class GameMode {
  final String emoji;                  // إيموجي النمط في شاشة الإعداد
  final LText name;
  final LText description;
  final String? basedOn;               // النمط اللي بنورث منه القواعد الناقصة
  final Map<String, CardRule> rules;   // المفتاح = قيمة الكارت

  const GameMode({
    required this.emoji,
    required this.name,
    required this.description,
    this.basedOn,
    required this.rules,
  });

  /// تحويل لـ JSON (الأنماط اللي الأدمن بيضيفها بتتحفظ بالشكل ده)
  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'name': name.toJson(),
        'description': description.toJson(),
        'rules': {for (final e in rules.entries) e.key: e.value.toJson()},
      };

  /// قراءة من JSON
  factory GameMode.fromJson(Map<String, dynamic> json) {
    final rules = Map<String, dynamic>.from(json['rules'] as Map);
    return GameMode(
      emoji: json['emoji'] as String? ?? '🃏',
      name: LText.fromJson(Map<String, dynamic>.from(json['name'] as Map)),
      description: LText.fromJson(Map<String, dynamic>.from(json['description'] as Map)),
      basedOn: 'classic', // احتياط: لو كارت ناقص ياخد قاعدته من الكلاسيك
      rules: {
        for (final e in rules.entries) e.key: CardRule.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
    );
  }
}

/// قيم الكروت الـ 13 بالترتيب (كل نمط جديد لازم يحدد قاعدة لكل واحدة)
const cardRanks = ['A', 'K', 'Q', 'J', '10', '9', '8', '7', '6', '5', '4', '3', '2'];

// قاعدة التصفيق: نستخدمها لكروت 7 و 6 و 5
const clapRule = CardRule(
  emoji: '👏',
  title: LText('صقّف!', 'Sa22af!'),
  description: LText(
    'أول ما الكارت يتقلب صقّفوا كلكم! آخر واحد يصقّف ياخد الكارت!',
    'Awel ma el kart yet2eleb sa22afo kollokom! Akher wa7ed ysa22af yakhod el kart!',
  ),
  type: RuleType.clap,
  prompt: LText('مين آخر واحد صقّف؟', 'Meen akher wa7ed sa22af?'),
);

/// الأنماط الأساسية المكتوبة في الكود (المفتاح هو اسم النمط البرمجي)
const Map<String, GameMode> builtInModes = {
  // ---------------- النمط الكلاسيكي ----------------
  'classic': GameMode(
    emoji: '🃏',
    name: LText('كلاسيك', 'Classic'),
    description: LText('القواعد الأصلية للعبة', 'El 2awa3ed el asleya lel le3ba'),
    rules: {
      'A': CardRule(
        emoji: '❓',
        title: LText('سؤال تعجيزي', 'So2al Ta3gizy'),
        description: LText(
          '{player} يختار حد ويسأله سؤال تعجيزي! لو معرفش يجاوب ياخد الكارت، ولو جاوب صح الكارت يرجع على {player}.',
          '{player} yekhtar 7ad w yes2alo so2al ta3gizy! Law ma3rafsh yegaweb yakhod el kart, w law gaweb sa7 el kart yerga3 3ala {player}.',
        ),
        type: RuleType.assign,
        prompt: LText('مين خسر التحدي؟', 'Meen khesr el ta7addy?'),
      ),
      'K': CardRule(
        emoji: '😂',
        title: LText('نكتة', 'Nokta'),
        description: LText(
          '{player} لازم يقول نكتة! لو محدش ضحك الكارت عليه. لو ضحكوا اختاروا "محدش خسر".',
          '{player} lazem y2ol nokta! Law ma7adesh de7ek el kart 3aleh. Law de7ko ekhtaro "Ma7adesh khesr".',
        ),
        type: RuleType.assign,
        prompt: LText('حد خسر؟', '7ad khesr?'),
      ),
      'Q': CardRule(
        emoji: '🤐',
        title: LText('صمت تام', 'Samt Tam'),
        description: LText(
          '{player} خد الكارت وبقى صامت! ممنوع حد يكلّمه أو يرد عليه. اللي يكلّمه ياخد منه الكارت ويبقى هو الصامت (دوسوا على 🤐 فوق).',
          '{player} khad el kart w ba2a samet! Mamno3 7ad ykallemo aw yrod 3aleh. Elly ykallemo yakhod meno el kart w yeb2a howa el samet (doso 3ala 🤐 fo2).',
        ),
        type: RuleType.silence,
      ),
      'J': CardRule(
        emoji: '💣',
        title: LText('القنبلة الموقوتة', 'El 2onbela El Maw2ota'),
        description: LText(
          'شغّلوا القنبلة ومرّروا الموبايل بسرعة! اللي الموبايل في إيده وقت الانفجار ياخد الكارت.',
          'Shaghalo el 2onbela w marraro el mobile besor3a! Elly el mobile fe edo wa2t el enfegar yakhod el kart.',
        ),
        type: RuleType.bomb,
        prompt: LText('مين كان ماسك الموبايل؟', 'Meen kan mask el mobile?'),
      ),
      '10': CardRule(
        emoji: '🎁',
        title: LText('كادو', 'Kado'),
        description: LText(
          'هدية مسمومة! الكارت ده مستني... أول واحد يخسر كارت بعد كده هياخد الكادو معاه!',
          'Hedeya masmooma! El kart da mestanny... Awel wa7ed yekhsar kart ba3d keda hayakhod el kado ma3ah!',
        ),
        type: RuleType.cadu,
      ),
      '9': CardRule(
        emoji: '🎤',
        title: LText('وزن وقافية', 'Wazn w 2afya'),
        description: LText(
          '{player} يقول كلمة، وكل واحد بالدور يقول كلمة على نفس القافية. اللي يقف أو يكرر ياخد الكارت.',
          '{player} y2ol kelma, w kol wa7ed bel dor y2ol kelma 3ala nafs el 2afya. Elly ye2af aw ykarrar yakhod el kart.',
        ),
        type: RuleType.assign,
        prompt: LText('مين وقف أو كرر؟', 'Meen we2ef aw karrar?'),
      ),
      '8': CardRule(
        emoji: '🏷️',
        title: LText('براندات', 'Brandat'),
        description: LText(
          '{player} يختار فئة (عربيات، لبس، مطاعم...) وكل واحد بالدور يقول براند منها. اللي يقف أو يكرر ياخد الكارت.',
          '{player} yekhtar fe2a (3arabeyat, lebs, mata3em...) w kol wa7ed bel dor y2ol brand menha. Elly ye2af aw ykarrar yakhod el kart.',
        ),
        type: RuleType.assign,
        prompt: LText('مين وقف أو كرر؟', 'Meen we2ef aw karrar?'),
      ),
      '7': clapRule,
      '6': clapRule,
      '5': clapRule,
      '4': CardRule(
        emoji: '🙅',
        title: LText('عمري ما', '3omry Ma'),
        description: LText(
          '{player} يقول "عمري ما..." وحاجة عمره ما عملها. اللي عملها فعلاً ياخد الكارت (لو أكتر من واحد اختاروا واحد).',
          '{player} y2ol "3omry ma..." w 7aga 3omro ma 3amalha. Elly 3amalha fe3lan yakhod el kart (law aktar men wa7ed ekhtaro wa7ed).',
        ),
        type: RuleType.assign,
        prompt: LText('مين عملها؟', 'Meen 3amalha?'),
      ),
      '3': CardRule(
        emoji: '🍀',
        title: LText('حظ سعيد', '7az Sa3eed'),
        description: LText(
          'كارت الحظ! {player} يدي الكارت ده لأي حد يختاره.',
          'Kart el 7az! {player} yeddy el kart da le ay 7ad yekhtaro.',
        ),
        type: RuleType.free,
        prompt: LText('هتديه لمين؟', 'Hatedeeh le meen?'),
      ),
      '2': CardRule(
        emoji: '💀',
        title: LText('حظ وحش', '7az We7esh'),
        description: LText(
          'للأسف يا {player}... الكارت ده ليك على طول!',
          'Lel asaf ya {player}... El kart da leek 3ala tool!',
        ),
        type: RuleType.self,
      ),
    },
  ),

  // ---------------- مثال لنمط إضافي: بارتي ----------------
  // بيورث كل حاجة من classic وبيغيّر كارتين بس
  'party': GameMode(
    emoji: '🎉',
    name: LText('بارتي', 'Party'),
    description: LText(
      'زي الكلاسيك، بس K بقت تحدي و 4 بقت "مين الأكتر احتمالاً"',
      'Zay el classic, bas K ba2et ta7addy w 4 ba2et "Meen el aktar e7temalan"',
    ),
    basedOn: 'classic',
    rules: {
      'K': CardRule(
        emoji: '🔥',
        title: LText('تحدي', 'Ta7addy'),
        description: LText(
          'الكل يختار تحدي لـ {player}. لو رفض أو فشل ياخد الكارت!',
          'El kol yekhtar ta7addy le {player}. Law rafad aw feshel yakhod el kart!',
        ),
        type: RuleType.assign,
        prompt: LText('فشل في التحدي؟', 'Feshel fel ta7addy?'),
      ),
      '4': CardRule(
        emoji: '👉',
        title: LText('مين الأكتر احتمالاً', 'Meen El Aktar E7temalan'),
        description: LText(
          '{player} يسأل "مين الأكتر احتمالاً إنه...؟" وعلى 3 الكل يشاور. اللي عليه أكتر صوابع ياخد الكارت.',
          '{player} yes2al "Meen el aktar e7temalan eno...?" w 3ala 3 el kol yshawer. Elly 3aleh aktar sawabe3 yakhod el kart.',
        ),
        type: RuleType.assign,
        prompt: LText('مين خد أكتر صوابع؟', 'Meen khad aktar sawabe3?'),
      ),
    },
  ),
};

/// الأنماط اللي الأدمن ضافها أو عدّلها (بتتحمّل من Supabase أو من ذاكرة الجهاز - شوف mode_store.dart)
/// لو فيها نمط بنفس اسم نمط أساسي (مثلاً 'classic') يبقى ده تعديل الأدمن عليه، وبيتاخد بداله.
final Map<String, GameMode> customModes = {};

/// كل الأنماط: الأساسية + اللي الأدمن ضافها (والتعديلات بتغطي على الأصلي)
Map<String, GameMode> get allModes => {...builtInModes, ...customModes};

/// هل ده نمط أساسي (classic / party)؟
bool isBuiltIn(String modeId) => builtInModes.containsKey(modeId);

/// هل الأدمن عدّل النمط الأساسي ده؟
bool isEdited(String modeId) => isBuiltIn(modeId) && customModes.containsKey(modeId);

/// تجيب قاعدة كارت معيّن في نمط معيّن (مع دعم الوراثة basedOn)
CardRule getRule(String modeId, String rank) {
  final mode = allModes[modeId] ?? builtInModes['classic']!;
  final rule = mode.rules[rank];
  if (rule != null) return rule;
  // الكارت مش موجود في النمط: ناخده من النمط الأب
  final parentId = mode.basedOn ?? 'classic';
  if (parentId == modeId) {
    // تعديل الأدمن على نمط أساسي ناقصه كارت → ناخده من النسخة الأصلية
    return builtInModes[parentId]!.rules[rank] ?? builtInModes['classic']!.rules[rank]!;
  }
  return getRule(parentId, rank);
}
