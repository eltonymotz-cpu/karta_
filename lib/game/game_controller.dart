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
//                                  silence     → صاحب الدور ياخد الـ Q ويبقى صامت ← back
//   كروت التصفيق (5 و 6 و 7): أول ما تتقلب بتبقى clapGo على طول ──دوس──► choosing
//   choosing ──اختيار لاعب أو "محدش خسر"──► back (الدور اللي بعده)
//
// الصلاحيات:
//   - الهوست (الموبايل اللي في النص أو اللي فتح القعدة) هو الحَكَم: هو بس اللي
//     بيختار الخسران، وبيعمل سكيب للكارت، وبيصحح الكروت.
//   - في وضع أكتر من موبايل: كل لاعب ينفع يسحب الكارت من موبايله في دوره بس.
//     الموبايل بيبعت "طلب" والهوست بيتأكد إن ده فعلاً دوره قبل ما ينفذه.
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
import 'game_settings.dart';

/// الشاشات الموجودة في التطبيق
/// home = اختيار طريقة اللعب، admin = لوحة الأدمن المخفية
enum AppScreen { home, setup, game, results, admin }

/// مراحل الكارت (شوف الرسمة فوق)
enum CardPhase { back, front, choosing, bombTicking, bombExploded, clapGo }

/// أحداث بتشغّل الأنيميشن على كل الموبايلات (بتيجي من منطق اللعبة الحقيقي بس)
enum GameEventKind { loss, nobody, correction, skip, timeout }

class GameEvent {
  final int id;             // رقم بيزيد مع كل حدث (عشان الواجهة تعرف إنه جديد)
  final GameEventKind kind;
  final int player;         // اللاعب المقصود (-1 = محدش)
  final int count;          // عدد الكروت اللي اتضافت/اتشالت
  const GameEvent(this.id, this.kind, this.player, this.count);

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind.name, 'player': player, 'count': count};

  static GameEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    return GameEvent(
      (json['id'] as num?)?.toInt() ?? 0,
      GameEventKind.values.firstWhere((k) => k.name == json['kind'], orElse: () => GameEventKind.nobody),
      (json['player'] as num?)?.toInt() ?? -1,
      (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class GameController extends ChangeNotifier {
  // ---------------- الثوابت ----------------
  static const suits = ['♠', '♥', '♦', '♣'];
  static const ranks = cardRanks;
  static const minPlayers = 3;
  static const maxPlayers = 8;

  // ---------------- الحالة العامة ----------------
  AppLang lang = AppLang.ar;            // اللغة الحالية
  AppScreen screen = AppScreen.home;    // الشاشة الظاهرة
  String modeId = 'classic';            // النمط المختار
  List<String> lastNames = [];          // آخر أسامي اتلعب بيها (عشان نرجعها في الإعداد)
  GameSettings settings = GameSettings(); // مؤقت الأسئلة ومدة القنبلة

  // ---------------- أكتر من موبايل ----------------
  bool multiDevice = false;             // هل الهوست اختار "أكتر من موبايل"؟
  bool isViewer = false;                // هل الجهاز ده موبايل لاعب (دخل بكود)؟
  RoomService? room;                    // القعدة أونلاين (لو موجودة)
  bool viewerHasState = false;          // موبايل اللاعب استلم أول حالة من الهوست؟
  LText? _viewerModeName;               // اسم النمط عند اللاعب (جاي من الهوست)
  final String deviceId = _newDeviceId(); // رقم مميز للموبايل ده
  Map<int, String> claims = {};         // مين ماسك أنهي لاعب: رقم اللاعب ← رقم الموبايل
  int? myPlayerIndex;                   // موبايل اللاعب: أنا أنهي لاعب؟
  bool drawPending = false;             // موبايل اللاعب: طلب السحب اتبعت ومستني الهوست
  Map<String, dynamic>? _viewerNext;    // موبايل اللاعب: شكل ضهر الكارت الجاي

  // ---------------- حالة الدور ----------------
  List<Player> players = [];            // اللاعيبة
  int currentIndex = 0;                 // رقم صاحب الدور
  List<PlayingCard> deck = [];          // الكروت الباقية
  PlayingCard? currentCard;             // الكارت المسحوب حالياً (null = الكارت مقلوب)
  CardRule? currentRule;                // قاعدة الكارت المسحوب
  CardPhase phase = CardPhase.back;     // مرحلة الكارت
  final List<PlayingCard> caduCards = []; // كروت الكادو المستنية أول خسران
  final List<PlayingCard> asideCards = []; // كروت اتحطت على جنب (مش عارفين مين خسر) - أول خسران ياخدها
  int silentIndex = -1;                 // رقم اللاعب في وضع الصمت (-1 = محدش)
  PlayingCard? silentCard;              // كارت الـ Q اللي مع الصامت (بيتنقل للي يكلّمه)
  final List<LText> log = [];           // سجل الأحداث (الأحدث في الأول)
  GameEvent? lastEvent;                 // آخر حدث (للأنيميشن)

  // ---------------- المؤقتات ----------------
  DateTime? questionEndsAt;             // وقت نهاية مؤقت السؤال (null = مفيش مؤقت شغال)
  bool timedOut = false;                // وقت السؤال خلص؟
  DateTime? bombEndsAt;                 // وقت انفجار القنبلة (مخفي، بيستخدم بس للتحذير في الآخر)

  // ---------------- أدوات داخلية ----------------
  Timer? _bombTimer;                    // مؤقت انفجار القنبلة
  Timer? _tickTimer;                    // مؤقت صوت التكة
  Timer? _questionTimer;                // مؤقت السؤال
  Timer? _pendingTimer;                 // موبايل اللاعب: لو الهوست مردش على طلب السحب
  int _cardSeq = 0;                     // رقم بيزيد مع كل كارت (عشان مؤقت قديم مايأثرش على كارت جديد)
  int _eventSeq = 0;
  DateTime _lastTap = DateTime(2000);   // وقت آخر ضغطة (لمنع الضغط المزدوج بالغلط)
  bool _busy = false;                   // بيمنع تنفيذ عمليتين في نفس اللحظة (سكيب مرتين مثلاً)
  int _silentBeforeDraw = -1;           // الصمت قبل الكارت (عشان لو اتعمل سكيب نرجّعه)
  PlayingCard? _silentCardBeforeDraw;
  final _random = Random();
  final sound = SoundService.instance;

  static String _newDeviceId() {
    final r = Random();
    return List.generate(12, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  // ---------------- قيم محسوبة ----------------
  bool get caduActive => caduCards.isNotEmpty;
  Player get currentPlayer => players[currentIndex];
  GameMode get mode => allModes[modeId] ?? builtInModes['classic']!;
  LText get modeName => _viewerModeName ?? mode.name;
  String? get roomCode => room?.code;

  /// الجهاز ده هو الهوست (الحَكَم)؟
  bool get isHost => !isViewer;

  /// موبايل اللاعب: ده دوري؟
  bool get isMyTurn => isViewer && myPlayerIndex != null && myPlayerIndex == currentIndex;

  /// علامة 🤐 بتظهر بس والكارت مقلوب (وبتختفي طول ما فيه كارت شغال)
  bool get showSilenceMarker => silentIndex >= 0 && currentCard == null;

  /// اتجاه الكتابة: العربي من اليمين، والفرانكو من الشمال
  TextDirection get textDirection => lang == AppLang.ar ? TextDirection.rtl : TextDirection.ltr;

  /// ترجمة نص للغة الحالية
  String t(LText text) => text.of(lang);

  /// هل ينفع دلوقتي نختار الخسران؟ (الأسامي حوالين الكارت بتبقى قابلة للضغط)
  bool get canPickLoser {
    if (isViewer) return false; // الهوست بس هو اللي بيحدد الخسران
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

  /// هل ينفع ننقل كارت الصمت دلوقتي؟ (فيه حد صامت ومعاه الكارت، ومفيش كارت شغال، وإحنا الهوست)
  bool get canPassSilence => isHost && silentIndex >= 0 && silentCard != null && currentCard == null;

  /// هل نعرض زرار "مش عارفين؟ حطّه على جنب"؟ (في كروت التصفيق وقت اختيار الخسران)
  bool get canSetAside => isHost && phase == CardPhase.choosing && currentRule?.type == RuleType.clap;

  /// هل نعرض زرار "محدش خسر"؟ (بس في القواعد من نوع assign)
  bool get allowNobody => currentRule?.type == RuleType.assign;

  /// الهوست ينفع يعمل سكيب دلوقتي؟
  bool get canSkip => isHost && currentCard != null;

  /// شكل ضهر الكارت الجاي: تصنيفه (عادي/أكشن) ولونه الخاص لو الأدمن غيّره
  CardCategory get nextCategory {
    if (isViewer) {
      final name = _viewerNext?['cat'] as String?;
      return CardCategory.values.firstWhere((c) => c.name == name, orElse: () => CardCategory.normal);
    }
    final rule = _nextRule;
    return rule?.category ?? CardCategory.normal;
  }

  int? get nextBackColor => isViewer ? (_viewerNext?['back'] as num?)?.toInt() : _nextRule?.design.back;
  String get nextBackPattern =>
      isViewer ? (_viewerNext?['bp'] as String? ?? 'auto') : (_nextRule?.design.backPattern ?? 'auto');
  LText? get nextTitleOnBack {
    if (isViewer) {
      final title = _viewerNext?['title'];
      return title is Map ? LText.fromJson(Map<String, dynamic>.from(title)) : null;
    }
    final rule = _nextRule;
    return rule != null && rule.design.titleOnBack ? rule.title : null;
  }

  CardRule? get _nextRule => deck.isEmpty ? null : getRule(modeId, deck.last.rank);

  /// مدة السؤال لكارت معيّن (مدة الكارت الخاصة أو مدة الإعدادات)
  int questionSecondsFor(CardRule rule) => rule.timerSeconds ?? settings.questionSeconds;

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

  /// تغيير إعدادات اللعبة (وحفظها على الجهاز)
  void updateSettings({int? questionSeconds, int? bombMaxSeconds}) {
    if (questionSeconds != null) settings.questionSeconds = questionSeconds;
    if (bombMaxSeconds != null) settings.bombMaxSeconds = bombMaxSeconds;
    settings.save();
    notifyListeners();
  }

  /// الأدمن غيّر كروت أو أنماط (من لوحة الأدمن أو من جهاز تاني): نحدّث الشاشة
  void modesChanged() {
    if (!allModes.containsKey(modeId)) modeId = 'classic';
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

  /// الدخول بكود القعدة من موبايل لاعب
  void joinRoom(String code) {
    if (!AppConfig.hasSupabase) return;
    _closeRoom();
    isViewer = true;
    viewerHasState = false;
    myPlayerIndex = null;
    claims = {};
    players = [];
    screen = AppScreen.game;
    room = RoomService.join(code: code.trim().toUpperCase(), onState: _applySnapshot);
    notifyListeners();
  }

  /// الرجوع للشاشة الأولى (وقفل القعدة لو موجودة)
  void goHome() {
    _cancelTimers();
    if (isViewer) room?.sendAction({'type': 'release', 'device': deviceId});
    _closeRoom();
    isViewer = false;
    multiDevice = false;
    myPlayerIndex = null;
    claims = {};
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
    asideCards.clear();
    silentIndex = -1;
    silentCard = null;
    lastEvent = null;
    timedOut = false;
    log.clear();
    // لو عدد اللاعيبة قل، نشيل المسكات اللي لأرقام مبقتش موجودة
    claims.removeWhere((index, _) => index >= players.length);
    _addLog(UiText.logStart, {'mode': mode.name});
    screen = AppScreen.game;
    // أكتر من موبايل: نفتح القعدة أونلاين (مرة واحدة، وبتفضل مفتوحة لو لعبتوا تاني)
    if (multiDevice && room == null && AppConfig.hasSupabase) {
      room = RoomService.host(
        code: RoomService.newCode(),
        onHello: _broadcastState,
        onAction: handleRemoteAction,
        onConnected: notifyListeners,
      );
    }
    notifyListeners();
  }

  /// تعمل الكومة: كل كارت مفعّل × 4 أشكال + الكروت الزيادة المفعّلة، وتخلطهم
  List<PlayingCard> _buildDeck() {
    final cards = _deckCards(modeId, onlyEnabled: true);
    // احتياط: لو الأدمن قفل كل الكروت، نلعب بالكومة كلها بدل ما اللعبة تخلص فوراً
    final result = cards.isEmpty ? _deckCards(modeId, onlyEnabled: false) : cards;
    result.shuffle(_random);
    return result;
  }

  static List<PlayingCard> _deckCards(String modeId, {required bool onlyEnabled}) {
    final mode = allModes[modeId] ?? builtInModes['classic']!;
    return [
      for (final rank in ranks)
        if (!onlyEnabled || getRule(modeId, rank).enabled)
          for (final suit in suits) PlayingCard(rank, suit),
      for (final extra in mode.extraCards)
        if (!onlyEnabled || extra.rule.enabled)
          for (var i = 0; i < extra.copies; i++) PlayingCard(extra.label, extraSuit),
    ];
  }

  /// عدد كروت الكومة في نمط معيّن (الكروت المفعّلة بس)
  static int deckSize(String modeId) {
    final count = _deckCards(modeId, onlyEnabled: true).length;
    return count == 0 ? _deckCards(modeId, onlyEnabled: false).length : count;
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
    if (isViewer) {
      _requestDraw(); // موبايل اللاعب: يطلب يسحب لو ده دوره
      return;
    }
    // نتجاهل الضغطة لو جت بسرعة جداً بعد اللي قبلها (ضغطة مزدوجة بالغلط)
    if (!_debounce()) return;

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

  bool _debounce() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 280) return false;
    _lastTap = now;
    return true;
  }

  /// سحب كارت جديد وقلبه
  void _drawCard() {
    if (deck.isEmpty) {
      finishGame();
      return;
    }
    final card = deck.removeLast();
    final rule = getRule(modeId, card.rank);
    _cardSeq++;
    currentCard = card;
    currentRule = rule;
    phase = CardPhase.front;
    timedOut = false;
    _silentBeforeDraw = silentIndex;
    _silentCardBeforeDraw = silentCard;

    // صوت القلب (ماعدا كروت التصفيق: ليها صوت الإنذار لوحده عشان يبان على طول)
    if (rule.type != RuleType.clap) {
      sound.play(Sfx.flip);
      HapticFeedback.selectionClick();
    }
    _addLog(UiText.logDraw, {'name': currentPlayer.name, 'card': card.label, 'rule': rule.title});

    // خيار "يفعّل وضع الصمت" (للأنماط اللي الأدمن بيعملها): صاحب الدور يبقى صامت
    // من غير كارت بيتنقل (والصمت القديم يتلغي)
    if (rule.setsSilence) {
      silentIndex = currentIndex;
      silentCard = null;
    }

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

    // كروت الأسئلة: مؤقت الإجابة بيبدأ أول ما الكارت يتقلب
    if (rule.timed && phase == CardPhase.front) {
      final seconds = questionSecondsFor(rule);
      if (seconds > 0) _startQuestionTimer(seconds);
    }
    notifyListeners();
  }

  /// الضغطة التانية على الكارت (بعد ما اتقلب)
  void _continueFromFront() {
    _stopQuestionTimer(); // الدور خلص: نوقف مؤقت السؤال
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
      case RuleType.silence:
        _takeSilence();
        break;
    }
  }

  // =================================================================
  // مؤقت كروت الأسئلة
  // =================================================================
  void _startQuestionTimer(int seconds) {
    _questionTimer?.cancel();
    final seq = _cardSeq;
    questionEndsAt = DateTime.now().add(Duration(seconds: seconds));
    _questionTimer = Timer(Duration(seconds: seconds), () {
      // لو الكارت اتغير أو الدور خلص قبل الوقت، المؤقت ده مالوش لازمة
      if (seq != _cardSeq || phase != CardPhase.front) return;
      _questionTimeout();
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    questionEndsAt = null;
  }

  /// الوقت خلص: بنعرض "الوقت خلص" ونفتح اختيار الخسران (من غير عقوبة تلقائية)
  void _questionTimeout() {
    _stopQuestionTimer();
    timedOut = true;
    sound.play(Sfx.alarm);
    HapticFeedback.heavyImpact();
    _addLog(UiText.logTimeout, {'name': currentPlayer.name});
    _emit(GameEventKind.timeout, currentIndex, 0);
    final type = currentRule?.type;
    if (type == RuleType.assign || type == RuleType.free) phase = CardPhase.choosing;
    notifyListeners();
  }

  // =================================================================
  // الصمت (Q): الكارت بيتنقل للي يكلّم الصامت
  // =================================================================

  /// صاحب الدور ياخد الـ Q ويبقى صامت (الصامت القديم بيحتفظ بالـ Q بتاعته)
  void _takeSilence() {
    final card = currentCard!;
    currentPlayer.cards.add(card);
    silentIndex = currentIndex;
    silentCard = card;
    _addLog(UiText.logSilentTake, {'name': currentPlayer.name, 'card': card.label});
    _emit(GameEventKind.loss, currentIndex, 1);
    sound.play(Sfx.boing);
    HapticFeedback.mediumImpact();
    _nextTurn();
  }

  /// حد كلّم الصامت: ياخد منه الـ Q (ومعاها الكادو لو موجود) ويبقى هو الصامت
  /// (ينفع تتنادى والكارت مقلوب، من زرار 🤐 فوق)
  void passSilence(int toIndex) {
    final card = silentCard;
    if (!canPassSilence || card == null || toIndex == silentIndex) return;
    final from = players[silentIndex];
    final to = players[toIndex];
    final before = to.cards.length;

    from.cards.remove(card);
    to.cards.add(card);
    _addLog(UiText.logSilencePass, {'from': from.name, 'to': to.name, 'card': card.label});

    // اللي كلّمه خسر، فلو فيه كادو مستني ياخده هو كمان
    if (caduActive) {
      to.cards.addAll(caduCards);
      _addLog(UiText.logCadu, {'name': to.name, 'cards': caduCards.map((c) => c.label).join(' ')});
      caduCards.clear();
    }
    _giveAsideCards(to);

    silentIndex = toIndex;
    _emit(GameEventKind.loss, toIndex, to.cards.length - before);
    sound.playPenalty();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  // =================================================================
  // اختيار الخسران (الهوست بس)
  // =================================================================

  /// تدي الكارت الحالي للاعب رقم index (ومعاه الكادو لو موجود)
  void pickLoser(int index) {
    final card = currentCard;
    if (card == null || isViewer || index < 0 || index >= players.length) return;
    final player = players[index];
    final before = player.cards.length;
    player.cards.add(card);
    _addLog(UiText.logTake, {'name': player.name, 'card': card.label});

    // الكادو: أول خسران ياخده (إلا لو الكارت نفسه هو الكادو)
    if (caduActive && currentRule!.type != RuleType.cadu) {
      player.cards.addAll(caduCards);
      _addLog(UiText.logCadu, {'name': player.name, 'cards': caduCards.map((c) => c.label).join(' ')});
      caduCards.clear();
    }
    _giveAsideCards(player);

    _emit(GameEventKind.loss, index, player.cards.length - before);
    sound.playPenalty(); // مرة بطة، مرة زمارة، مرة بوم...
    HapticFeedback.mediumImpact();
    _nextTurn();
  }

  /// الخسران ياخد الكروت اللي اتحطت على جنب (لو فيه)
  void _giveAsideCards(Player player) {
    if (asideCards.isEmpty) return;
    player.cards.addAll(asideCards);
    _addLog(UiText.logAsideTaken, {'name': player.name, 'cards': asideCards.map((c) => c.label).join(' ')});
    asideCards.clear();
  }

  /// محدش خسر: الكارت يتحرق
  void pickNobody() {
    if (isViewer || currentCard == null) return;
    _addLog(UiText.logNobody, {});
    _emit(GameEventKind.nobody, -1, 0);
    sound.play(Sfx.ding);
    _nextTurn();
  }

  /// مش عارفين مين خسر (في التصفيق): الكارت يتحط على جنب، ونفس اللاعب يعيد الدور،
  /// وأول حد يخسر بعد كده ياخد الكروت اللي على جنب مع الكارت بتاعه
  void setAside() {
    final card = currentCard;
    if (!canSetAside || card == null) return;
    asideCards.add(card);
    _addLog(UiText.logAside, {'card': card.label, 'name': currentPlayer.name});
    sound.play(Sfx.boing);
    _nextTurn(sameTurn: true);
  }

  // =================================================================
  // سكيب الكارت (الهوست بس)
  // =================================================================

  /// الهوست بيعدّي الكارت الحالي من غير ما يتلعب: محدش بياخده، والدور بيتنقل للي بعده.
  /// بترجع true لو السكيب اتنفذ.
  bool skipCard() {
    final card = currentCard;
    if (!canSkip || card == null || _busy) return false;
    _busy = true; // يمنع سكيب مرتين ورا بعض
    try {
      // لو الكارت ده كادو كان اتفعّل لما اتقلب، نشيله
      caduCards.remove(card);
      // لو الكارت كان شغّل وضع صمت، نرجّع الصمت زي ما كان قبله
      if (currentRule?.setsSilence ?? false) {
        silentIndex = _silentBeforeDraw;
        silentCard = _silentCardBeforeDraw;
      }
      _addLog(UiText.logSkip, {'card': card.label, 'name': currentPlayer.name});
      _emit(GameEventKind.skip, currentIndex, 0);
      sound.play(Sfx.boing);
      _nextTurn();
      return true;
    } finally {
      _busy = false;
    }
  }

  // =================================================================
  // تصحيح الكروت (الهوست بس)
  // =================================================================

  /// الهوست بيشيل كارت اتدى لحد بالغلط (من غير ما يبدأ اللعبة من الأول)
  bool removeCardFrom(int playerIndex, int cardIndex) {
    if (isViewer || playerIndex < 0 || playerIndex >= players.length) return false;
    final player = players[playerIndex];
    if (cardIndex < 0 || cardIndex >= player.cards.length) return false;
    final card = player.cards.removeAt(cardIndex);
    // لو الكارت ده هو الـ Q اللي مع الصامت، الصمت بيخلص
    if (identical(card, silentCard)) {
      silentCard = null;
      silentIndex = -1;
    }
    _addLog(UiText.logCorrection, {'name': player.name, 'card': card.label});
    _emit(GameEventKind.correction, playerIndex, 1);
    sound.play(Sfx.ding);
    notifyListeners();
    return true;
  }

  /// الانتقال للدور اللي بعده (أو إعادة نفس الدور لو sameTurn = true)
  void _nextTurn({bool sameTurn = false}) {
    _cancelTimers();
    currentCard = null;
    currentRule = null;
    phase = CardPhase.back;
    timedOut = false;
    if (deck.isEmpty) {
      finishGame();
      return;
    }
    if (!sameTurn) {
      currentIndex = (currentIndex + 1) % players.length; // بعد آخر لاعب نرجع للأول
    }
    notifyListeners();
  }

  // =================================================================
  // القنبلة الموقوتة (J)
  // =================================================================
  void _startBomb() {
    phase = CardPhase.bombTicking;
    // وقت سري بيتختار مرة واحدة لما القنبلة تشتغل (من 10 لأقصى وقت في الإعدادات)
    final min = GameSettings.bombMinSeconds;
    final max = settings.bombMaxSeconds;
    final seconds = min + _random.nextInt(max - min + 1);
    final seq = _cardSeq;
    bombEndsAt = DateTime.now().add(Duration(seconds: seconds));
    sound.play(Sfx.tick);
    // التكة كل ثانية، وفي آخر 5 ثواني بتسرّع (كل نص ثانية) كتحذير
    var halfSeconds = 0;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      halfSeconds++;
      final left = bombEndsAt?.difference(DateTime.now()) ?? Duration.zero;
      if (left.inMilliseconds <= 5000 || halfSeconds.isEven) sound.play(Sfx.tick);
    });
    _bombTimer = Timer(Duration(seconds: seconds), () {
      if (seq == _cardSeq) _explode();
    });
    notifyListeners();
  }

  void _explode() {
    // حماية: الانفجار يحصل مرة واحدة بس
    if (phase != CardPhase.bombTicking) return;
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

  void _emit(GameEventKind kind, int player, int count) {
    lastEvent = GameEvent(++_eventSeq, kind, player, count);
  }

  void _cancelTimers() {
    _bombTimer?.cancel();
    _tickTimer?.cancel();
    _bombTimer = null;
    _tickTimer = null;
    bombEndsAt = null;
    _stopQuestionTimer();
  }

  // =================================================================
  // أكتر من موبايل: طلبات موبايلات اللاعيبة (الهوست بيتأكد منها)
  // =================================================================

  /// موبايل اللاعب: "أنا اللاعب ده"
  void claimSeat(int index) {
    if (!isViewer || index < 0 || index >= players.length) return;
    final owner = claims[index];
    if (owner != null && owner != deviceId) return; // حد تاني ماسكه
    myPlayerIndex = index;
    room?.sendAction({'type': 'claim', 'player': index, 'device': deviceId});
    notifyListeners();
  }

  /// موبايل اللاعب: يغيّر اللاعب اللي هو ماسكه
  void releaseSeat() {
    if (!isViewer) return;
    myPlayerIndex = null;
    room?.sendAction({'type': 'release', 'device': deviceId});
    notifyListeners();
  }

  /// موبايل اللاعب: طلب سحب كارت (بيتبعت للهوست وهو اللي بيقرر)
  void _requestDraw() {
    if (!isMyTurn || phase != CardPhase.back || drawPending || claims[currentIndex] != deviceId) return;
    drawPending = true;
    room?.sendAction({'type': 'draw', 'player': currentIndex, 'device': deviceId});
    // لو الهوست مردش في 4 ثواني (النت فصل مثلاً)، نسمح بمحاولة تانية
    _pendingTimer?.cancel();
    _pendingTimer = Timer(const Duration(seconds: 4), () {
      drawPending = false;
      notifyListeners();
    });
    notifyListeners();
  }

  /// الهوست: طلب جاي من موبايل لاعب (أي طلب مش مسموح بيتجاهل)
  /// (public عشان الاختبارات تقدر تجرّب طلبات مش مسموحة)
  void handleRemoteAction(Map<String, dynamic> action) {
    if (isViewer) return;
    final type = action['type'] as String?;
    final device = action['device'] as String?;
    final player = (action['player'] as num?)?.toInt();
    if (device == null || device.isEmpty) return;

    switch (type) {
      case 'claim':
        if (player == null || player < 0 || player >= players.length) return;
        final owner = claims[player];
        if (owner != null && owner != device) {
          notifyListeners(); // نبعت الحالة عشان الموبايل يعرف إن اللاعب ده محجوز
          return;
        }
        claims.removeWhere((_, d) => d == device); // كل موبايل ماسك لاعب واحد بس
        claims[player] = device;
        notifyListeners();
        break;
      case 'release':
        claims.removeWhere((_, d) => d == device);
        notifyListeners();
        break;
      case 'draw':
        // مسموح بس: في شاشة اللعب، والكارت مقلوب، والطلب من الموبايل الماسك صاحب الدور
        if (screen != AppScreen.game || phase != CardPhase.back) return;
        if (player != currentIndex || claims[currentIndex] != device) return;
        if (!_debounce()) return;
        _drawCard();
        break;
      default:
        // أي طلب تاني (سكيب، اختيار خسران، تعديل كروت...) مش مسموح من موبايل لاعب
        break;
    }
  }

  // =================================================================
  // مزامنة الموبايلات (أكتر من موبايل)
  // =================================================================

  /// كل ما الحالة تتغير: الواجهة تتحدث، ولو إحنا الهوست نبعت الحالة للاعيبة
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (room != null && room!.isHost) _broadcastState();
  }

  void _broadcastState() => room?.sendState(_toSnapshot());

  /// نسخة من حالة اللعبة في شكل JSON (اللي موبايلات اللاعيبة محتاجينه عشان يرسموا الشاشة)
  Map<String, dynamic> _toSnapshot() {
    final next = _nextRule;
    return {
      'screen': screen == AppScreen.game || screen == AppScreen.results ? screen.name : 'waiting',
      'mode': mode.name.toJson(),
      'players': [
        for (final p in players) {'name': p.name, 'cards': [for (final c in p.cards) c.label]},
      ],
      'current': currentIndex,
      'deck': deck.length,
      'deckTotal': deckSize(modeId),
      'card': currentCard?.label,
      'rule': currentRule?.toJson(),
      'phase': phase.name,
      'cadu': [for (final c in caduCards) c.label],
      'aside': [for (final c in asideCards) c.label],
      'silent': silentIndex,
      'log': [for (final l in log.take(40)) l.toJson()],
      'qEnds': questionEndsAt?.millisecondsSinceEpoch,
      'timedOut': timedOut,
      'bombEnds': bombEndsAt?.millisecondsSinceEpoch,
      'event': lastEvent?.toJson(),
      'claims': {for (final e in claims.entries) '${e.key}': e.value},
      // شكل ضهر الكارت الجاي (من غير ما نكشف هو أنهي كارت)
      'next': next == null
          ? null
          : {
              'cat': next.category.name,
              if (next.design.back != null) 'back': next.design.back,
              if (next.design.backPattern != 'auto') 'bp': next.design.backPattern,
              if (next.design.titleOnBack) 'title': next.title.toJson(),
            },
    };
  }

  int _viewerDeckTotal = 52;
  int get deckTotal => isViewer ? _viewerDeckTotal : deckSize(modeId);

  /// موبايل اللاعب: بيطبّق الحالة اللي جاية من الهوست
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
    // الكومة: موبايل اللاعب محتاج العدد بس، فبنعمل كروت وهمية بنفس العدد
    deck = List.filled(s['deck'] as int? ?? 0, const PlayingCard('2', '♠'));
    _viewerDeckTotal = (s['deckTotal'] as num?)?.toInt() ?? 52;
    final cardLabel = s['card'] as String?;
    currentCard = cardLabel == null ? null : PlayingCard.fromLabel(cardLabel);
    currentRule = s['rule'] == null ? null : CardRule.fromJson(Map<String, dynamic>.from(s['rule'] as Map));
    phase = CardPhase.values.firstWhere((p) => p.name == s['phase'], orElse: () => CardPhase.back);
    caduCards
      ..clear()
      ..addAll([for (final l in (s['cadu'] as List? ?? [])) PlayingCard.fromLabel(l as String)]);
    asideCards
      ..clear()
      ..addAll([for (final l in (s['aside'] as List? ?? [])) PlayingCard.fromLabel(l as String)]);
    silentIndex = s['silent'] as int? ?? -1;
    log
      ..clear()
      ..addAll([for (final l in (s['log'] as List? ?? [])) LText.fromJson(Map<String, dynamic>.from(l as Map))]);
    final qEnds = (s['qEnds'] as num?)?.toInt();
    questionEndsAt = qEnds == null ? null : DateTime.fromMillisecondsSinceEpoch(qEnds);
    timedOut = s['timedOut'] as bool? ?? false;
    final bombEnds = (s['bombEnds'] as num?)?.toInt();
    bombEndsAt = bombEnds == null ? null : DateTime.fromMillisecondsSinceEpoch(bombEnds);
    lastEvent = GameEvent.fromJson(s['event']);
    final rawClaims = s['claims'];
    claims = rawClaims is Map
        ? {for (final e in rawClaims.entries) int.parse(e.key as String): e.value as String}
        : {};
    final next = s['next'];
    _viewerNext = next is Map ? Map<String, dynamic>.from(next) : null;

    // الهوست ماأكدش إني ماسك اللاعب ده (حد سبقني)، أو اللاعب اتشال
    if (myPlayerIndex != null && claims[myPlayerIndex] != deviceId && claims.containsKey(myPlayerIndex)) {
      myPlayerIndex = null;
    }
    if (myPlayerIndex != null && myPlayerIndex! >= players.length) myPlayerIndex = null;
    // الهوست رد على طلب السحب (الكارت اتغير)
    if (cardLabel != oldCard || phase != oldPhase) {
      drawPending = false;
      _pendingTimer?.cancel();
    }

    // أصوات عند موبايل اللاعب كمان
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
    _pendingTimer?.cancel();
    _closeRoom();
    super.dispose();
  }
}
