// اختبار: حفظ نمط على الجهاز وتحميله تاني (من غير Supabase)
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/data/game_modes.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/services/mode_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('custom mode survives save and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final mode = GameMode(
      emoji: '🎲',
      name: const LText('تجربة', 'Test'),
      description: const LText('', ''),
      rules: {for (final r in cardRanks) r: getRule('classic', r)},
    );
    await ModeStore.saveLocal('custom_1', mode);
    customModes.clear();
    await ModeStore.loadLocal();
    expect(customModes.keys, ['custom_1']);
    expect(customModes['custom_1']!.rules.length, 13);
    expect(customModes['custom_1']!.rules['J']!.type, RuleType.bomb);
  });

  test('admin edit of classic overrides it, and reset restores it', () async {
    SharedPreferences.setMockInitialValues({});
    customModes.clear();
    final original = getRule('classic', 'K').title.ar;

    // الأدمن يعدّل عنوان K في الكلاسيك
    const newK = CardRule(
      emoji: '🎯',
      title: LText('تحدي جديد', 'Ta7addy gedeed'),
      description: LText('', ''),
      type: RuleType.assign,
    );
    final edited = GameMode(
      emoji: '🃏',
      name: const LText('كلاسيك', 'Classic'),
      description: const LText('', ''),
      basedOn: 'classic',
      rules: {for (final r in cardRanks) r: r == 'K' ? newK : getRule('classic', r)},
    );
    await ModeStore.saveLocal('classic', edited);

    expect(getRule('classic', 'K').title.ar, 'تحدي جديد');
    expect(isEdited('classic'), isTrue);
    // البارتي بياخد الكروت اللي مش عنده من الكلاسيك المعدّل
    expect(getRule('party', 'A').title.ar, getRule('classic', 'A').title.ar);

    await ModeStore.delete('classic');
    expect(getRule('classic', 'K').title.ar, original);
    expect(isEdited('classic'), isFalse);
  });
}
