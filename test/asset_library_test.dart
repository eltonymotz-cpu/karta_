// مكتبة الصور: كل أيقونة جاهزة ليها ملف حقيقي، والبحث شغال، ومعرفة الأماكن اللي الصورة مستخدمة فيها
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/pixel_assets.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/services/asset_library.dart';
import 'package:karta/services/storage_service.dart';

void main() {
  tearDown(() => customModes.clear());

  test('every built-in pixel icon points to a real PNG with a unique reference', () {
    expect(builtInAssets.length, 18);
    expect(builtInAssets.map((a) => a.ref).toSet().length, builtInAssets.length);
    for (final asset in builtInAssets) {
      final file = File(assetPath(asset.ref));
      expect(file.existsSync(), isTrue, reason: asset.ref);
      final bytes = file.readAsBytesSync();
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: '${asset.ref} is not a PNG');
    }
  });

  test('search matches Arabic, Franco and tags, and filters by category', () {
    expect(builtInAssets.where((a) => a.matches('جمجمة')).single.ref, 'asset:pixel/skull.png');
    expect(builtInAssets.where((a) => a.matches('coins')).single.ref, 'asset:pixel/money_bill.png');
    expect(builtInAssets.where((a) => a.category == AssetCategory.memes).length, 4);
  });

  test('usages find cards and modes that use an image (so it is not deleted while in use)', () {
    customModes['pix'] = GameMode(
      emoji: '🖼',
      name: const LText('بيكسل', 'Pixel'),
      description: const LText('', ''),
      basedOn: 'classic',
      image: 'asset:pixel/joker.png',
      rules: {'K': getRule('classic', 'K').copyWith(design: const CardDesign(iconUrl: 'asset:pixel/skull.png'))},
    );
    expect(AssetLibrary.usages('asset:pixel/skull.png').single, contains('K'));
    expect(AssetLibrary.usages('asset:pixel/joker.png').single, contains('بيكسل'));
    expect(AssetLibrary.usages('asset:pixel/clover.png'), isEmpty);
  });

  test('library files are recognised from their storage URL', () {
    const url = 'https://x.supabase.co/storage/v1/object/public/karta-images/library/1_2.png';
    expect(StorageService.pathFromUrl(url), 'library/1_2.png');
  });
}
