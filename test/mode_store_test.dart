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
}
