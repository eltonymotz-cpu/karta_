// =================================================================
// عقل اللعبة (GameController)
// -----------------------------------------------------------------
// هنا كل منطق اللعب. الواجهة بتقرا الحالة من هنا وبتنادي الدوال بس.
// لما الحالة تتغير بننادي notifyListeners() فالواجهة تتحدث تلقائياً.
//
// مراحل الكارت (CardPhase) - كل الضغطات بتكون على الكارت نفسه:
//
//   back ──دوس──► front ──دوس──► (حسب نوع القاعدة)
//                                  assign/free → choosing (اختيار الخسران جوه الكارت)
//                                  self        → الكارت لصاحب الدور ← back
//                                  cadu        → الدور اللي بعده ← back
//                                  bomb        → bombTicking ──انفجار──► bombExploded ──دوس──► choosing
//   كروت التصفيق (5 و 6 و 7): أول ما تتقلب بتبقى clapGo على طول ──دوس──► choosing
//   choosing ──اختيار لاعب أو "محدش خسر"──► back (الدور اللي بعده)
// =================================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_modes.dart';
import '../data/texts.dart';
import '../models.dart';
import '../services/room_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';

/// الشاشات الموجودة في التطبيق
/// home = اختيار طريقة اللعب، admin = لوحة الأدمن المخفية
enum AppScreen { home, setup, game, results, admin }

/// مراحل الكارت (شوف الرسمة فوق)
enum CardPhase { back, front, choosing, bombTicking, bombExploded, clapGo }

class GameController extends ChangeNotifier {
  // ---------------- الثوابت ----------------
  static const suits = ['♠', '♥', '♦', '♣'];
  static const ranks = ['A', 'K', 'Q', 'J', '10', '9', '8', '7', '6', '5', '4', '3', '2'];
  static const minPlayers = 3;
  static const maxPlayers = 8;
  static const bombMinSeconds = 15;
  static const bombMaxSeconds = 120;

  // ---------------- الحالة العامة ----------------
  AppLang lang = AppLang.ar;            // اللغة الحالية
  AppScreen screen = AppScreen.home;    // الشاشة الظاهرة
  String modeId = 'classic';            // النمط المختار
  List<String> lastNames = [];          // آخر أسامي اتلعب بيها (عشان نرجعها في الإعداد)

  // ---------------- أكتر من موبايل ----------------
  bool multiDevice = false;             // هل الهوست اختار "أكتر من موبايل"؟
  bool isViewer = false;                // هل الجهاز ده متفرج (دخل بكود)؟
  RoomService? room;                    // القعدة أونلاين (لو موجودة)
  bool viewerHasState = false;          // المتفرج استلم أول حالة من الهوست؟
  LText? _viewerModeName;               // اسم النمط عند المتفرج (جاي من الهوست)

  // ---------------- حالة الدور ----------------
  List<Player> players = [];            // اللاعيبة
  int currentIndex = 0;                 // رقم صاحب الدور
  List<PlayingCard> deck = [];          // الكروت الباقية
  PlayingCard? currentCard;             // الكارت المسحوب حالياً (null = الكارت مقلوب)
  CardRule? currentRule;                // قاعدة الكارت المسحوب
  CardPhase phase = CardPhase.back;     // مرحلة الكارت
  final List<PlayingCard> caduCards = []; // كروت الكادو المستنية أول خسران
  int silentIndex = -1;                 // رقم اللاعب في وضع الصمت (-1 = محدش)
  final List<LText> log = [];           // سجل الأحداث (الأحدث في الأول)

  // ---------------- أدوات داخلية ----------------
  Timer? _bombTimer;                    // مؤقت انفجار القنبلة
  Timer? _tickTimer;                    // مؤقت صوت التكة
  DateTime _lastTap = DateTime(2000);   // وقت آخر ضغطة (لمنع الضغط المزدوج بالغلط)
  final _random = Random();
  final sound = SoundService.instance;

  // ---------------- قيم محسوبة ----------------
  bool get caduActive => caduCards.isNotEmpty;
  Player get currentPlayer => players[currentIndex];
  GameMode get mode => allModes[modeId] ?? builtInModes['classic']!;
  LText get modeName => _viewerModeName ?? mode.name;
  String? get roomCode => room?.code;

  /// اتجاه الكتابة: العربي من اليمين، والفرانكو من الشمال
  TextDirection get textDirection => lang == AppLang.ar ? TextDirection.rtl : TextDirection.ltr;

  /// ترجمة نص للغة الحالية
  String t(LText text) => text.of(lang);

  /// هل ينفع دلوقتي نختار الخسران؟ (الأسامي حوالين الكارت بتبقى قابلة للضغط)
  bool get canPickLoser {
    if (isViewer) return false; // المتفرج بيتفرج بس
    switch (phase) {
      case CardPhase.choosing:
      case CardPhase.bombExploded:
        return true;
      case CardPhase.front:
        return currentRule!.type == RuleType.assign || currentRule!.type == RuleType.free;
      default:
        return false;
    }
  }

  /// هل نعرض زرار "محدش خسر"؟ (بس في القواعد من نوع assign)
  bool get allowNobody => currentRule?.type == RuleType.assign;

  // =================================================================
  // الإعدادات العامة
  // =================================================================

  /// التبديل بين العربي والفرانكو
  void toggleLang() {
    lang = lang == AppLang.ar ? AppLang.franco : AppLang.ar;
    notifyListeners();
  }

  /// تشغيل/إيقاف الصوت
  void toggleSound() {
    sound.enabled = !sound.enabled;
    notifyListeners();
  }

  void setMode(String id) {
    modeId = id;
    notifyListeners();
  }

  // =================================================================
  // الشاشة الأولى: موبايل واحد / أكتر من موبايل / دخول بكود
  // =================================================================

  /// موبايل واحد في النص
  void chooseSingleDevice() {
    multiDevice = false;
    screen = AppScreen.setup;
    notifyListeners();
  }

  /// أكتر من موبايل: الجهاز ده هو الهوست (القعدة بتتفتح لما اللعبة تبدأ)
  void chooseMultiDevice() {
    multiDevice = true;
    screen = AppScreen.setup;
    notifyListeners();
  }

  /// الدخول كمتفرج بكود القعدة
  void joinRoom(String code) {
    if (!AppConfig.hasSupabase) return;
    _closeRoom();
    isViewer = true;
    viewerHasState = false;
    players = [];
    screen = AppScreen.game;
    room = RoomService.join(code: code.trim().toUpperCase(), onState: _applySnapshot);
    notifyListeners();
  }

  /// الرجوع للشاشة الأولى (وقفل القعدة لو موجودة)
  void goHome() {
    _cancelTimers();
    _closeRoom();
    isViewer = false;
    multiDevice = false;
    _viewerModeName = null;
    screen = AppScreen.home;
    notifyListeners();
  }

  /// فتح/قفل لوحة الأدمن
  void openAdmin() {
    screen = AppScreen.admin;
    notifyListeners();
  }

  void closeAdmin() {
    screen = AppScreen.home;
    notifyListeners();
  }

  void _closeRoom() {
    room?.close();
    room = null;
  }

  // =================================================================
  // بداية ونهاية اللعبة
  // =================================================================

  /// تبدأ لعبة جديدة بالأسامي دي
  void startGame(List<String> names) {
    _cancelTimers();
    lastNames = List.of(names);
    players = [
      for (var i = 0; i < names.length; i++) Player(names[i], AppColors.playerColors[i % AppColors.playerColors.length]),
    ];
    currentIndex = 0;
    deck = _buildDeck();
    currentCard = null;
    currentRule = null;
    phase = CardPhase.back;
    caduCards.clear();
    silentIndex = -1;
    log.clear();
    _addLog(UiText.logStart, {'mode': mode.name});
    screen = AppScreen.game;
    // أكتر من موبايل: نفتح القعدة أونلاين (مرة واحدة، وبتفضل مفتوحة لو لعبتوا تاني)
    if (multiDevice && room == null && AppConfig.hasSupabase) {
      room = RoomService.host(code: RoomService.newCode(), onHello: _broadcastState, onConnected: notifyListeners);
    }
    notifyListeners();
  }

  /// تعمل 52 كارت (13 قيمة × 4 أشكال) وتخلطهم
  List<PlayingCard> _buildDeck() {
    final cards = [
      for (final suit in suits)
        for (final rank in ranks) PlayingCard(rank, suit),
    ];
    cards.shuffle(_random);
    return cards;
  }

  /// تنهي اللعبة وتروح لشاشة النتائج
  void finishGame() {
    _cancelTimers();
    screen = AppScreen.results;
    sound.play(Sfx.fanfare);
    notifyListeners();
  }

  void playAgain() => startGame(lastNames);

  void backToSetup() {
    _cancelTimers();
    screen = AppScreen.setup;
    notifyListeners();
  }

  // =================================================================
  // الضغط على الكارت: هنا كل التحكم في اللعبة
  // =================================================================
  void tapCard() {
    if (isViewer) return; // المتفرج مش بيتحكم في الكارت
    // نتجاهل الضغطة لو جت بسرعة جداً بعد اللي قبلها (ضغطة مزدوجة بالغلط)
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 280) return;
    _lastTap = now;

    switch (phase) {
      case CardPhase.back:
        _drawCard();
        break;
      case CardPhase.front:
        _continueFromFront();
        break;
      case CardPhase.bombExploded:
        phase = CardPhase.choosing;
        notifyListeners();
        break;
      case CardPhase.clapGo:
        sound.play(Sfx.clap);
        HapticFeedback.heavyImpact();
        phase = CardPhase.choosing;
        notifyListeners();
        break;
      case CardPhase.choosing:
      case CardPhase.bombTicking:
        // في المراحل دي الضغط على الكارت نفسه مالوش لازمة
        break;
    }
  }

  /// سحب كارت جديد وقلبه
  void _drawCard() {
    if (deck.isEmpty) {
      finishGame();
      return;
    }
    final card = deck.removeLast();
    final rule = getRule(modeId, card.rank);
    currentCard = card;
    currentRule = rule;
    phase = CardPhase.front;

    // صوت القلب (ماعدا كروت التصفيق: ليها صوت الإنذار لوحده عشان يبان على طول)
    if (rule.type != RuleType.clap) {
      sound.play(Sfx.flip);
      HapticFeedback.selectionClick();
    }
    _addLog(UiText.logDraw, {'name': currentPlayer.name, 'card': card.label, 'rule': rule.title});

    // قاعدة الصمت: صاحب الدور يبقى "صامت" (والصمت القديم يتلغي)
    if (rule.setsSilence) silentIndex = currentIndex;

    // صوت خاص لبعض الكروت أول ما تتقلب
    switch (rule.type) {
      case RuleType.self:
        Future.delayed(const Duration(milliseconds: 250), () => sound.play(Sfx.quack));
        break;
      case RuleType.free:
        Future.delayed(const Duration(milliseconds: 200), () => sound.play(Sfx.ding));
        break;
      case RuleType.cadu:
        caduCards.add(card); // الكادو يتفعّل على طول
        Future.delayed(const Duration(milliseconds: 200), () => sound.play(Sfx.gift));
        break;
      case RuleType.clap:
        // التصفيق بيبدأ في نفس لحظة قلب الكارت: الزرار الكبير يظهر على طول
        phase = CardPhase.clapGo;
        sound.play(Sfx.alarm);
        HapticFeedback.heavyImpact();
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// الضغطة التانية على الكارت (بعد ما اتقلب)
  void _continueFromFront() {
    switch (currentRule!.type) {
      case RuleType.assign:
      case RuleType.free:
      case RuleType.clap:
        phase = CardPhase.choosing; // نعرض أسامي اللاعيبة جوه الكارت
        notifyListeners();
        break;
      case RuleType.self:
        pickLoser(currentIndex); // الكارت لصاحب الدور
        break;
      case RuleType.cadu:
        _addLog(UiText.logCaduWait, {});
        _nextTurn();
        break;
      case RuleType.bomb:
        _startBomb();
        break;
    }
  }

  // =================================================================
  // اختيار الخسران
  // =================================================================

  /// تدي الكارت الحالي للاعب رقم index (ومعاه الكادو لو موجود)
  void pickLoser(int index) {
    final card = currentCard;
    if (card == null || isViewer) return;
    final player = players[index];
    player.cards.add(card);
    _addLog(UiText.logTake, {'name': player.name, 'card': card.label});

    // الكادو: أول خسران ياخده (إلا لو الكارت نفسه هو الكادو)
    if (caduActive && currentRule!.type != RuleType.cadu) {
      player.cards.addAll(caduCards);
      _addLog(UiText.logCadu, {'name': player.name, 'cards': caduCards.map((c) => c.label).join(' ')});
      caduCards.clear();
    }

    sound.playPenalty(); // مرة بطة، مرة زمارة، مرة بوم...
    HapticFeedback.mediumImpact();
    _nextTurn();
  }

  /// محدش خسر: الكارت يتحرق
  void pickNobody() {
    if (isViewer) return;
    _addLog(UiText.logNobody, {});
    sound.play(Sfx.ding);
    _nextTurn();
  }

  /// الانتقال للدور اللي بعده
  void _nextTurn() {
    _cancelTimers();
    currentCard = null;
    currentRule = null;
    phase = CardPhase.back;
    if (deck.isEmpty) {
      finishGame();
      return;
    }
    currentIndex = (currentIndex + 1) % players.length; // بعد آخر لاعب نرجع للأول
    notifyListeners();
  }

  // =================================================================
  // القنبلة الموقوتة (J)
  // =================================================================
  void _startBomb() {
    phase = CardPhase.bombTicking;
    final seconds = bombMinSeconds + _random.nextInt(bombMaxSeconds - bombMinSeconds + 1); // وقت سري
    sound.play(Sfx.tick);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => sound.play(Sfx.tick));
    _bombTimer = Timer(Duration(seconds: seconds), _explode);
    notifyListeners();
  }

  void _explode() {
    _cancelTimers();
    phase = CardPhase.bombExploded;
    sound.play(Sfx.boom);
    HapticFeedback.heavyImpact();
    _addLog(UiText.logBoom, {});
    notifyListeners();
  }

  // =================================================================
  // أدوات مساعدة
  // =================================================================
  void _addLog(LText template, Map<String, Object> vars) {
    log.insert(0, fillText(template, vars));
  }

  void _cancelTimers() {
    _bombTimer?.cancel();
    _tickTimer?.cancel();
    _bombTimer = null;
    _tickTimer = null;
  }

  // =================================================================
  // مزامنة الموبايلات (أكتر من موبايل)
  // =================================================================

  /// كل ما الحالة تتغير: الواجهة تتحدث، ولو إحنا الهوست نبعت الحالة للمتفرجين
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (room != null && room!.isHost) _broadcastState();
  }

  void _broadcastState() => room?.sendState(_toSnapshot());

  /// نسخة من حالة اللعبة في شكل JSON (اللي المتفرجين محتاجينه عشان يرسموا الشاشة)
  Map<String, dynamic> _toSnapshot() => {
        'screen': screen == AppScreen.game || screen == AppScreen.results ? screen.name : 'waiting',
        'mode': mode.name.toJson(),
        'players': [
          for (final p in players) {'name': p.name, 'cards': [for (final c in p.cards) c.label]},
        ],
        'current': currentIndex,
        'deck': deck.length,
        'card': currentCard?.label,
        'rule': currentRule?.toJson(),
        'phase': phase.name,
        'cadu': [for (final c in caduCards) c.label],
        'silent': silentIndex,
        'log': [for (final l in log.take(40)) l.toJson()],
      };

  /// المتفرج: بيطبّق الحالة اللي جاية من الهوست
  void _applySnapshot(Map<String, dynamic> s) {
    final oldCard = currentCard?.label;
    final oldPhase = phase;
    final oldScreen = screen;

    final screenName = s['screen'] as String? ?? 'waiting';
    if (screenName == 'waiting') {
      viewerHasState = false;
      screen = AppScreen.game;
      notifyListeners();
      return;
    }

    viewerHasState = true;
    screen = screenName == 'results' ? AppScreen.results : AppScreen.game;
    _viewerModeName = LText.fromJson(Map<String, dynamic>.from(s['mode'] as Map));
    final list = (s['players'] as List).cast<Map>();
    players = [
      for (var i = 0; i < list.length; i++)
        Player(list[i]['name'] as String, AppColors.playerColors[i % AppColors.playerColors.length])
          ..cards.addAll([for (final l in (list[i]['cards'] as List)) PlayingCard.fromLabel(l as String)]),
    ];
    currentIndex = s['current'] as int? ?? 0;
    // الكومة: المتفرج محتاج العدد بس، فبنعمل كروت وهمية بنفس العدد
    deck = List.filled(s['deck'] as int? ?? 0, const PlayingCard('2', '♠'));
    final cardLabel = s['card'] as String?;
    currentCard = cardLabel == null ? null : PlayingCard.fromLabel(cardLabel);
    currentRule = s['rule'] == null ? null : CardRule.fromJson(Map<String, dynamic>.from(s['rule'] as Map));
    phase = CardPhase.values.firstWhere((p) => p.name == s['phase'], orElse: () => CardPhase.back);
    caduCards
      ..clear()
      ..addAll([for (final l in (s['cadu'] as List? ?? [])) PlayingCard.fromLabel(l as String)]);
    silentIndex = s['silent'] as int? ?? -1;
    log
      ..clear()
      ..addAll([for (final l in (s['log'] as List? ?? [])) LText.fromJson(Map<String, dynamic>.from(l as Map))]);

    // أصوات عند المتفرج كمان
    if (currentCard != null && currentCard!.label != oldCard && phase != CardPhase.clapGo) sound.play(Sfx.flip);
    if (phase != oldPhase) {
      if (phase == CardPhase.bombExploded) sound.play(Sfx.boom);
      if (phase == CardPhase.clapGo) sound.play(Sfx.alarm);
    }
    if (screen == AppScreen.results && oldScreen != AppScreen.results) sound.play(Sfx.fanfare);
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimers();
    _closeRoom();
    super.dispose();
  }
}
