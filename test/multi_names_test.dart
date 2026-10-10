// أكتر من موبايل: كل لاعب بيكتب اسمه بنفسه، والهوست بيبدأ بالأسامي دي،
// وكل موبايل بيمسك اللاعب بتاعه على طول (من غير "إنت مين؟")
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/screens/setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('players come from the phones that joined, each phone owns its own seat', () {
    final host = GameController()..sound.enabled = false;
    host.chatForTest = true;
    // موبايلين دخلوا وكتبوا أساميهم
    host.handleRemoteAction({'type': 'ping', 'device': 'p-sara', 'name': 'Sara'});
    host.handleRemoteAction({'type': 'ping', 'device': 'p-omar', 'name': 'Omar'});
    host.startMultiGame(hostName: 'Ali', phones: [('p-sara', 'Sara'), ('p-omar', 'Omar')]);
    expect(host.players.map((p) => p.name), ['Ali', 'Sara', 'Omar']);
    expect(host.claims, {0: host.deviceId, 1: 'p-sara', 2: 'p-omar'});
    expect(host.myPlayerIndex, 0);

    // موبايل سارة بيستلم الحالة ويعرف إنه "سارة" لوحده
    final sara = GameController()..sound.enabled = false;
    sara.isViewer = true;
    sara.deviceId = 'p-sara';
    sara.applySnapshotForTest(host.snapshotForTest());
    expect(sara.myPlayerIndex, 1);

    // الهوست مش بيلعب: كل اللاعيبة من الموبايلات
    final referee = GameController()..sound.enabled = false;
    referee.startMultiGame(phones: [('a', 'A'), ('b', 'B'), ('c', 'C')], extra: ['Mona']);
    expect(referee.players.map((p) => p.name), ['A', 'B', 'C', 'Mona']);
    expect(referee.myPlayerIndex, isNull);
    expect(referee.claims.containsKey(3), isFalse); // منى من غير موبايل
  });

  test('a phone can change its name before the game starts', () {
    final host = GameController()..sound.enabled = false;
    host.handleRemoteAction({'type': 'ping', 'device': 'p1', 'name': 'Guest'});
    host.handleRemoteAction({'type': 'ping', 'device': 'p1', 'name': 'Karim'});
    expect(host.lobby['p1']!.name, 'Karim');
  });

  testWidgets('multi-phone setup lists the joined names instead of name fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    final game = GameController()..sound.enabled = false;
    game.multiDevice = true;
    game.onlineForTest = true;
    game.handleRemoteAction({'type': 'ping', 'device': 'p1', 'name': 'Sara'});
    game.handleRemoteAction({'type': 'ping', 'device': 'p2', 'name': 'Omar'});
    await tester.pumpWidget(MaterialApp(home: SetupScreen(game: game)));
    await tester.pump();
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Omar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // خانة اسم الهوست بس، مفيش خانات أسامي للاعيبة
    await tester.binding.setSurfaceSize(null);
    game.dispose();
  });
}
