// =================================================================
// مكتبة الصور: أيقونات البيكسل ارت الجاهزة + الصور اللي الأدمن بيرفعها
// -----------------------------------------------------------------
// - الأيقونات الجاهزة جوه التطبيق نفسه (assets/images/pixel)، فبتشتغل من غير نت
//   ومش بتاخد أي مساحة من Supabase.
// - المرجع بتاع أي صورة (اللي بيتحفظ في بيانات الكارت) نص واحد:
//     "asset:pixel/skull.png"  ← أيقونة جاهزة
//     "https://..."            ← صورة مرفوعة على Supabase Storage
//   فنفس الصورة تتستخدم في أماكن كتير من غير ما تترفع تاني.
// =================================================================
import 'texts.dart';

/// تصنيفات الصور
enum AssetCategory { characters, memes, cards, objects, text, effects, other }

class LibraryAsset {
  final String ref;            // المرجع اللي بيتحفظ
  final LText name;
  final AssetCategory category;
  final List<String> tags;     // كلمات للبحث
  final String? id;            // للصور المرفوعة بس (رقمها في الجدول)
  const LibraryAsset({required this.ref, required this.name, required this.category, this.tags = const [], this.id});

  bool get builtIn => ref.startsWith(assetPrefix);

  /// يطابق البحث؟ (في الاسمين والكلمات)
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.ar.toLowerCase().contains(q) || name.fr.toLowerCase().contains(q) || tags.any((t) => t.toLowerCase().contains(q));
  }
}

const assetPrefix = 'asset:';

/// مسار الأيقونة الجاهزة جوه التطبيق
String assetPath(String ref) => 'assets/images/${ref.substring(assetPrefix.length)}';

LText categoryName(AssetCategory c) => switch (c) {
      AssetCategory.characters => const LText('شخصيات', 'Shakhsyat'),
      AssetCategory.memes => const LText('ميمز', 'Memes'),
      AssetCategory.cards => const LText('كروت', 'Kroot'),
      AssetCategory.objects => const LText('حاجات', '7agat'),
      AssetCategory.text => const LText('كلام', 'Kalam'),
      AssetCategory.effects => const LText('مؤثرات', 'Mo2asserat'),
      AssetCategory.other => const LText('تانية', 'Tanya'),
    };

/// الأيقونات الجاهزة (اتقطعت من الصورة اللي اتبعتت، كل واحدة في ملف لوحدها)
const builtInAssets = <LibraryAsset>[
  LibraryAsset(ref: 'asset:pixel/minions.png', name: LText('مينيونز', 'Minions'), category: AssetCategory.characters, tags: ['minion', 'yellow']),
  LibraryAsset(ref: 'asset:pixel/minion.png', name: LText('مينيون', 'Minion'), category: AssetCategory.characters, tags: ['minion', 'yellow']),
  LibraryAsset(ref: 'asset:pixel/banana_cat.png', name: LText('قطة الموزة', 'Banana cat'), category: AssetCategory.characters, tags: ['cat', 'banana']),
  LibraryAsset(ref: 'asset:pixel/bird_coffee.png', name: LText('عصفورة بالقهوة', 'Bird coffee'), category: AssetCategory.characters, tags: ['bird', 'coffee', 'tea']),
  LibraryAsset(ref: 'asset:pixel/doge.png', name: LText('دوج', 'Doge'), category: AssetCategory.memes, tags: ['dog', 'shiba']),
  LibraryAsset(ref: 'asset:pixel/crying_cat.png', name: LText('قطة بتعيط', 'Crying cat'), category: AssetCategory.memes, tags: ['cat', 'sad', 'thumbs']),
  LibraryAsset(ref: 'asset:pixel/kermit_fire.png', name: LText('كيرميت والنار', 'Kermit fire'), category: AssetCategory.memes, tags: ['frog', 'fire', 'panic']),
  LibraryAsset(ref: 'asset:pixel/frog_dog.png', name: LText('كلب الضفدع', 'Frog dog'), category: AssetCategory.memes, tags: ['frog', 'dog', 'pond']),
  LibraryAsset(ref: 'asset:pixel/joker.png', name: LText('جوكر', 'Joker'), category: AssetCategory.cards, tags: ['jester', 'card', 'gold']),
  LibraryAsset(ref: 'asset:pixel/red_card.png', name: LText('كارت أحمر', 'Red card'), category: AssetCategory.cards, tags: ['penalty', 'red', 'foul']),
  LibraryAsset(ref: 'asset:pixel/money_bill.png', name: LText('فلوس', 'Money'), category: AssetCategory.objects, tags: ['coin', 'cash', 'dollar', 'coins']),
  LibraryAsset(ref: 'asset:pixel/news.png', name: LText('جرنال', 'News'), category: AssetCategory.objects, tags: ['newspaper', 'news']),
  LibraryAsset(ref: 'asset:pixel/skull.png', name: LText('جمجمة', 'Skull'), category: AssetCategory.objects, tags: ['dead', 'danger', 'lose']),
  LibraryAsset(ref: 'asset:pixel/clover.png', name: LText('برسيم الحظ', 'Clover'), category: AssetCategory.objects, tags: ['luck', 'green']),
  LibraryAsset(ref: 'asset:pixel/hearts.png', name: LText('قلوب', 'Hearts'), category: AssetCategory.objects, tags: ['life', 'health', 'heart']),
  LibraryAsset(ref: 'asset:pixel/game_over.png', name: LText('جيم أوفر', 'Game over'), category: AssetCategory.text, tags: ['lose', 'end']),
  LibraryAsset(ref: 'asset:pixel/oops.png', name: LText('أوبس', 'Oops'), category: AssetCategory.text, tags: ['oops', 'mistake']),
  LibraryAsset(ref: 'asset:pixel/campfire.png', name: LText('نار', 'Campfire'), category: AssetCategory.effects, tags: ['fire', 'flame', 'hot']),
];
