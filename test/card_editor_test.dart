// محرر الكروت: إعدادات زرار التصفيق والإجابة بتظهر والمعاينة بتعرض الزرار
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karta/data/texts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/screens/card_editor_screen.dart';
import 'package:karta/widgets/card_face.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('clap card shows the clap button settings and a live clap preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    final game = GameController()..sound.enabled = false;
    await tester.pumpWidget(MaterialApp(home: CardEditorScreen(game: game, modeId: 'classic', label: '5')));
    await tester.pump();

    // المحتوى: خانات الإجابة موجودة
    expect(find.text(UiText.answerAr.ar), findsOneWidget);

    // تاب اللعب: زرار التصفيق متفعّل لكارت التصفيق
    await tester.tap(find.text(UiText.tabGameplay.ar));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text(UiText.clapButton.ar), findsOneWidget);
    expect(find.text(UiText.clapDesign.ar), findsOneWidget);

    // معاينة الزرار
    await tester.tap(find.text(UiText.previewClap.ar));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ClapButtonView), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
    game.dispose();
  });
}
