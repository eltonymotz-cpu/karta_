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
import '../services/app_settings.dart';
import 'chat.dart';
import 'economy.dart';
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

/// حالة دور لاعب (ساعة كل لاعب)
enum TurnStatus { active, answered, noAnswer, finished, skipped }

/// دور واحد: مين لعب، أنهي كارت، وقته (كل الأوقات بساعة الهوست بالملي ثانية)
class TurnRecord {
  final int player;
  final String? card;
  final int startedAt;
  int? endedAt;          // null = الدور لسه شغال
  int pausedMs;          // الوقت اللي الساعة كانت واقفة فيه
  int? pausedAt;         // الساعة واقفة دلوقتي من الوقت ده
  TurnStatus status;

  TurnRecord({
    required this.player,
    required this.card,
    required this.startedAt,
    this.endedAt,
    this.pausedMs = 0,
    this.pausedAt,
    this.status = TurnStatus.active,
  });

  bool get isActive => endedAt == null;
  bool get isPaused => pausedAt != null && endedAt == null;

  /// الوقت اللي فات من الدور (بيتحسب من الأوقات المسجلة، مش من عداد شغال)
  int elapsedMs(int now) {
    final end = endedAt ?? pausedAt ?? now;
    return max(0, end - startedAt - pausedMs);
  }

  Map<String, dynamic> toJson() => {
        'p': player,
        if (card != null) 'c': card,
        's': startedAt,
        if (endedAt != null) 'e': endedAt,
        if (pausedMs != 0) 'pm': pausedMs,
        if (pausedAt != null) 'pa': pausedAt,
        'st': status.name,
      };

  static TurnRecord fromJson(Map json) => TurnRecord(
        player: (json['p'] as num).toInt(),
        card: json['c'] as String?,
        startedAt: (json['s'] as num).toInt(),
        endedAt: (json['e'] as num?)?.toInt(),
        pausedMs: (json['pm'] as num?)?.toInt() ?? 0,
        pausedAt: (json['pa'] as num?)?.toInt(),
        status: TurnStatus.values.firstWhere((t) => t.name == json['st'], orElse: () => TurnStatus.finished),
      );
}

/// ضغطة على زرار التصفيق من موبايل لاعب (الترتيب = ترتيب وصولها للهوست)
class ClapTap {
  final int player;
  final int at;
  const ClapTap(this.player, this.at);
}

/// تغيير في رصيد لاعب للأنيميشن ("-50 🪙" فوق اسمه) - بيوصل لكل الموبايلات
class CoinFx {
  final int id;
  final int player;
  final int delta;
  const CoinFx(this.id, this.player, this.delta);
}

/// زرار سريع اتداس: إيموجي بيظهر في نص اللعبة عند الكل
class Reaction {
  final int id;
  final String emoji;
  final String name;
  const Reaction(this.id, this.emoji, this.name);
}

/// موبايل في القعدة (اللوبي)
class LobbyMember {
  final String name;
  int lastSeen;          // آخر مرة وصل منه حاجة (بساعة الهوست)
  final bool muted;
  LobbyMember(this.name, this.lastSeen, {this.muted = false});
}

/// رسالة بعتها وبستنى الهوست يأكدها
class PendingChat {
  final String id;
  final String text;
  ChatRejection? failed; // null = بتتبعت
  Timer? timer;
  PendingChat({required this.id, required this.text});
}

/// مكان لاعب في الترتيب (الأقل كروت هو الأول، والمتعادلين ليهم نفس المركز)
class RankEntry {
  final int player;
  final int rank;
  final int cards;
  const RankEntry(this.player, this.rank, this.cards);
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
  String deviceId = savedDeviceId ?? _newDeviceId(); // رقم مميز للموبايل ده (بيتحفظ عشان لو الصفحة اتعملها ريفريش يرجع لنفس مكانه)
  static String? savedDeviceId;         // بيتحمل من الجهاز قبل ما التطبيق يبدأ (main.dart)
  static String savedNickname = '';
  static void Function()? onSessionClosed; // بيمسح رقم الموبايل المتخزن لما اللعبة تتقفل
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
  final List<TurnRecord> turns = [];    // كل الأدوار اللي اتلعبت (ساعة كل لاعب)
  bool clapOpen = false;                // مرحلة التصفيق مفتوحة (الضغطات بتتسجل)
  int? innerTurn;                       // الدور جوه الكارت (وزن وقافية، براندات...): مين عليه الدور دلوقتي
  List<String> lastClapOrder = [];      // ترتيب آخر تصفيق (بيظهر على ضهر الكارت لحد الكارت الجاي)

  // ---------------- الكوينز ----------------
  final Economy economy = Economy();    // الهوست بيحسب، واللاعيبة بيعرضوا اللي جاي منه
  final List<CoinFx> coinFx = [];       // آخر تغييرات في الأرصدة (للأنيميشن على كل الموبايلات)
  int _coinFxSeq = 0;
  final Map<String, Completer<String?>> _coinWaiters = {}; // موبايل اللاعب: مستني رد الهوست
  int _coinReqSeq = 0;

  // ---------------- الإيقاف المؤقت ----------------
  bool paused = false;                  // الهوست وقّف اللعبة (مفيش سحب ولا عدادات)
  Duration? _pausedQuestionLeft;
  Duration? _pausedBombLeft;
  bool _turnPausedByGame = false;

  // ---------------- الأزرار السريعة ----------------
  /// الـ 5 زراير بتوعي (كل لاعب بيختارهم، وبيتنسوا لما اللعبة تتقفل)
  List<String> reactionButtons = List.of(defaultReactions);
  static const defaultReactions = ['😂', '👏', '🔥', '😱', '👀'];
  final List<Reaction> reactionFeed = [];  // آخر الإيموجي اللي اتبعتت (للأنيميشن)
  int _reactionSeq = 0;
  final Map<String, List<int>> _reactionTimes = {}; // الهوست: سرعة كل موبايل

  // ---------------- الشات واللوبي ----------------
  final ChatRoom chat = ChatRoom();     // الهوست: الرسايل المقبولة (هو المرجع)
  final List<ChatMessage> chatView = []; // موبايل اللاعب: الرسايل اللي وصلت من الهوست
  final Map<String, PendingChat> pendingChat = {}; // رسايلي اللي لسه ماتأكدتش
  int chatUnread = 0;                   // رسايل جديدة ماتشافتش
  bool chatOpen = false;                // نافذة الشات مفتوحة؟
  String nickname = savedNickname;      // اسمي في الشات (لو مش ماسك لاعب)
  final Map<String, LobbyMember> lobby = {}; // الموبايلات اللي في القعدة
  final Set<String> kicked = {};        // موبايلات الهوست طردها
  bool roomClosed = false;              // موبايل اللاعب: الهوست قفل القعدة
  bool wasKicked = false;               // موبايل اللاعب: الهوست طردني
  int _chatSeq = 0;
  Timer? _pingTimer;
  final List<ClapTap> clapTaps = [];    // ضغطات التصفيق بالترتيب
  bool answerShown = false;             // الهوست كشف إجابة الكارت الحالي؟
  int clockOffset = 0;                  // موبايل اللاعب: فرق ساعته عن ساعة الهوست

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
  bool get canSetAside => isHost && phase == CardPhase.choosing && (currentRule?.usesClap ?? false);

  /// هل نعرض زرار "محدش خسر"؟ (بس في القواعد من نوع assign)
  bool get allowNobody => currentRule?.type == RuleType.assign;

  /// الهوست ينفع يعمل سكيب دلوقتي؟
  bool get canSkip => isHost && currentCard != null;

  /// الهوست ينفع يعدّي دور لاعب (من غير ما يسحب)؟
  bool get canSkipPlayer => isHost && currentCard == null && players.isNotEmpty && screen == AppScreen.game;

  /// الوقت دلوقتي بساعة الهوست (موبايل اللاعب بيصلّح فرق الساعة)
  int get nowMs => DateTime.now().millisecondsSinceEpoch + clockOffset;

  /// الدور الشغال دلوقتي (لو فيه)
  TurnRecord? get activeTurn => turns.isNotEmpty && turns.last.isActive ? turns.last : null;

  /// آخر دور (شغال أو خلص) - الهوست يقدر يغيّر حالته
  TurnRecord? get lastTurn => turns.isEmpty ? null : turns.last;

  /// الوقت الكلي للاعب في كل أدواره
  int playerTotalMs(int player) {
    final now = nowMs;
    return turns.where((t) => t.player == player).fold(0, (sum, t) => sum + t.elapsedMs(now));
  }

  /// الترتيب: الأقل كروت هو الأول، والمتعادلين ليهم نفس المركز (1، 1، 3)
  List<RankEntry> get ranking {
    final order = List.generate(players.length, (i) => i)
      ..sort((a, b) {
        final byCards = players[a].cards.length.compareTo(players[b].cards.length);
        return byCards != 0 ? byCards : a.compareTo(b); // التعادل: بترتيب القعدة
      });
    final result = <RankEntry>[];
    for (var k = 0; k < order.length; k++) {
      final count = players[order[k]].cards.length;
      final rank = k > 0 && result[k - 1].cards == count ? result[k - 1].rank : k + 1;
      result.add(RankEntry(order[k], rank, count));
    }
    return result;
  }

  /// الكارت الحالي فيه زرار تصفيق شغال؟
  bool get clapActive => currentRule?.usesClap ?? false;

  /// أول واحد صقّف (بيظهر على طول)
  int? get clapFirst => clapTaps.isEmpty ? null : clapTaps.first.player;

  /// آخر واحد صقّف: بيتحدد بس بعد ما الهوست يقفل التصفيق (عشان مايتقالش بدري)
  int? get clapLast => clapOpen || clapTaps.isEmpty ? null : clapTaps.last.player;

  /// موبايل اللاعب: أنا صقّفت خلاص؟
  bool get iClapped => myPlayerIndex != null && clapTaps.any((t) => t.player == myPlayerIndex);

  /// موبايل اللاعب: ينفع أصقّف دلوقتي؟
  bool get canClap => clapOpen && phase == CardPhase.clapGo && myPlayerIndex != null && !iClapped;

  /// الكارت الحالي ليه إجابة؟
  bool get hasAnswer => currentRule?.answer != null;

  /// حالة القعدة: lobby (لسه في الإعداد) / inGame / finished / closed
  String get roomStatus {
    if (room == null) return 'closed';
    return switch (screen) { AppScreen.game => 'inGame', AppScreen.results => 'finished', _ => 'lobby' };
  }

  /// الشات متاح دلوقتي؟ (قعدة أونلاين + الأدمن مفعّله)
  bool get chatAvailable => (room != null || chatForTest) && AppSettings.current.chatOnline;

  /// للاختبارات: نعتبر إن فيه قعدة مفتوحة (من غير نت)
  @visibleForTesting
  bool chatForTest = false;

  /// كل رسايل الشات اللي تتعرض (الهوست: المرجع، اللاعب: اللي وصل + رسايلي اللي لسه بتتبعت)
  List<ChatMessage> get chatMessages => isViewer ? chatView : chat.messages;

  /// اسمي في الشات: اسم اللاعب اللي ماسكه، أو الاسم اللي كتبته، أو "الهوست"
  String get chatName {
    if (isHost) return nickname.isNotEmpty ? nickname : 'Host';
    final mine = myPlayerIndex;
    if (mine != null && mine < players.length) return players[mine].name;
    return nickname.isNotEmpty ? nickname : 'Guest';
  }

  ChatContext get _chatContext => screen == AppScreen.game || screen == AppScreen.results ? ChatContext.game : ChatContext.lobby;

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

  /// أكتر من موبايل: الجهاز ده هو الهوست. القعدة بتتفتح على طول (اللوبي)،
  /// فاللاعيبة يقدروا يدخلوا ويتكلموا في الشات وإنت لسه بتكتب الأسامي
  void chooseMultiDevice() {
    multiDevice = true;
    screen = AppScreen.setup;
    _openHostRoom();
    notifyListeners();
  }

  void _openHostRoom() {
    if (room != null || !AppConfig.hasSupabase || !AppSettings.current.onlineEnabled) return;
    chat.clear();
    lobby.clear();
    kicked.clear();
    room = RoomService.host(
      code: RoomService.newCode(),
      onHello: _onHello,
      onAction: handleRemoteAction,
      onConnected: notifyListeners,
    );
  }

  /// موبايل جديد دخل (أو رجع بعد ما فصل): نسجله في اللوبي ونبعتله الحالة والشات
  void _onHello(Map<String, dynamic> hello) {
    final device = hello['device'] as String?;
    if (device != null && device.isNotEmpty && !kicked.contains(device)) {
      lobby[device] = LobbyMember(_cleanName(hello['name']), nowMs);
    }
    _broadcastState(withChat: true);
  }

  static String _cleanName(Object? name) {
    final text = name is String ? name.trim() : '';
    if (text.isEmpty) return 'Guest';
    return text.length > ChatRoom.nameMax ? text.substring(0, ChatRoom.nameMax) : text;
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
    roomClosed = false;
    wasKicked = false;
    chatView.clear();
    pendingChat.clear();
    chatUnread = 0;
    room = RoomService.join(
      code: code.trim().toUpperCase(),
      onState: _applySnapshot,
      onEvent: _onRoomEvent,
      hello: {'device': deviceId, 'name': chatName},
    );
    // كل 20 ثانية بنقول للهوست إننا لسه موجودين (عشان يعرف مين متصل)
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      room?.sendAction({'type': 'ping', 'device': deviceId, 'name': chatName});
    });
    notifyListeners();
  }

  /// الرجوع للشاشة الأولى (وقفل القعدة لو موجودة)
  void goHome() {
    _cancelTimers();
    if (isViewer) room?.sendAction({'type': 'release', 'device': deviceId});
    // الهوست: نقول لكل اللاعيبة إن القعدة اتقفلت قبل ما نقفلها
    if (isHost && room != null) room!.sendState({'screen': 'closed'});
    _pingTimer?.cancel();
    _closeRoom();
    // اللعبة اتقفلت: كل حاجة ليها علاقة بالقعدة بتتمسح من الذاكرة (مفيش حاجة متحفظة أصلاً)
    chat.clear();
    chatView.clear();
    pendingChat.clear();
    lobby.clear();
    kicked.clear();
    economy.clear();
    coinFx.clear();
    paused = false;
    reactionFeed.clear();
    _reactionTimes.clear();
    reactionButtons = List.of(defaultReactions);
    chatOpen = false;
    chatUnread = 0;
    nickname = '';
    deviceId = _newDeviceId(); // رقم جديد للقعدة الجاية (القديم مالوش أي لازمة)
    onSessionClosed?.call();
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
      for (var i = 0; i < names.length; i++) Player(names[i], i),
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
    turns.clear();
    clapTaps.clear();
    clapOpen = false;
    answerShown = false;
    paused = false;
    innerTurn = null;
    lastClapOrder = [];
    _pausedQuestionLeft = null;
    _pausedBombLeft = null;
    // الكوينز: رصيد جديد لكل لاعب في كل لعبة (ومفيش حاجة بتتحفظ بعد اللعبة)
    // الفلوس بس في الأنماط اللي الأدمن فاتح فيها "بالفلوس"، وإلا اللعب بالنقط (عدد الكروت)
    final ecoConfig = AppSettings.current.economyFor(online: multiDevice);
    economy.start(names.length, ecoConfig.copyWith({'enabled': ecoConfig.enabled && mode.money}), nowMs);
    coinFx.clear();
    log.clear();
    // لو عدد اللاعيبة قل، نشيل المسكات اللي لأرقام مبقتش موجودة
    claims.removeWhere((index, _) => index >= players.length);
    _addLog(UiText.logStart, {'mode': mode.name});
    screen = AppScreen.game;
    // أكتر من موبايل: القعدة بتبقى مفتوحة من اللوبي (ولو لسه مااتفتحتش نفتحها)
    if (multiDevice) _openHostRoom();
    notifyListeners();
  }

  /// أكتر من موبايل: اللاعيبة هما اللي دخلوا بالكود (كل واحد كاتب اسمه بنفسه)
  /// + الهوست لو بيلعب + لاعيبة من غير موبايل. كل موبايل بيمسك اللاعب بتاعه على طول.
  void startMultiGame({String? hostName, required List<(String, String)> phones, List<String> extra = const []}) {
    final names = <String>[?hostName, for (final p in phones) p.$2, ...extra];
    startGame(names);
    claims = {};
    var index = 0;
    if (hostName != null) {
      claims[0] = deviceId;
      myPlayerIndex = 0;
      index = 1;
    } else {
      myPlayerIndex = null;
    }
    for (final p in phones) {
      claims[index++] = p.$1;
    }
    notifyListeners();
  }

  /// موبايل اللاعب: يغيّر اسمه (والهوست بيعرف على طول)
  void renameMe(String name) {
    setNickname(name);
    if (isViewer && nickname.isNotEmpty) room?.sendAction({'type': 'ping', 'device': deviceId, 'name': nickname});
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
    paused = false;
    // آخر اللعبة: الحصالة ومكافأة الكسبان (الأقل كروت) + رجوع رهانات التحديات اللي ماخلصتش
    if (isHost && players.isNotEmpty) {
      _coins(economy.endGame([for (final r in ranking) if (r.rank == 1) r.player], nowMs));
    }
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
      // موبايل اللاعب: يصقّف لو التصفيق مفتوح، أو يطلب يسحب لو ده دوره
      if (paused) return;
      if (phase == CardPhase.clapGo) {
        requestClap();
      } else {
        _requestDraw();
      }
      return;
    }
    if (paused) return; // اللعبة واقفة مؤقتاً
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
        // أكتر من موبايل: الهوست لاعب زي الباقيين، دوسته = تصفيقه هو.
        // الكارت مابيتقفلش من أي حد: بيتقفل لوحده لما الكل يصقّف.
        if (clapNeedsEveryone) {
          final mine = myPlayerIndex;
          if (mine != null) {
            HapticFeedback.heavyImpact();
            registerClap(mine);
          }
          break;
        }
        // موبايل واحد: الدوسة = التصفيق خلص ونختار الخسران (زي الأول)
        sound.play(Sfx.clap);
        HapticFeedback.heavyImpact();
        _closeClap();
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
    answerShown = false;
    clapTaps.clear();
    clapOpen = false;
    lastClapOrder = [];
    innerTurn = rule.hasPassAround ? currentIndex : null; // السهم بيبدأ عند صاحب الكارت
    _startTurn(card.label);
    _silentBeforeDraw = silentIndex;
    _silentCardBeforeDraw = silentCard;

    // صوت القلب (ماعدا كروت التصفيق: ليها صوت الإنذار لوحده عشان يبان على طول)
    if (!rule.usesClap) {
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
      default:
        break;
    }
    // زرار التصفيق (أي كارت الأدمن فعّل عليه الزرار): التصفيق بيبدأ في نفس لحظة قلب الكارت،
    // والضغطات من موبايلات اللاعيبة بتتسجل لحد ما الهوست يقفل
    if (rule.usesClap) {
      phase = CardPhase.clapGo;
      clapOpen = true;
      sound.play(Sfx.alarm);
      HapticFeedback.heavyImpact();
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
    // كارت سؤال: أول دوسة بتكشف الإجابة للكل، والدوسة اللي بعدها تكمّل (اختيار الخسران)
    if (currentRule?.answer != null && !answerShown) {
      _stopQuestionTimer();
      answerShown = true;
      _addLog(UiText.logAnswerShown, {'answer': currentRule!.answer!});
      sound.play(Sfx.ding);
      notifyListeners();
      return;
    }
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
  void _startQuestionTimer(int seconds) => _armQuestionTimer(Duration(seconds: seconds));

  void _armQuestionTimer(Duration duration) {
    _questionTimer?.cancel();
    final seq = _cardSeq;
    questionEndsAt = DateTime.now().add(duration);
    _questionTimer = Timer(duration, () {
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
    _loseCoins('card$_cardSeq', currentIndex, card.label);
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
    // اللي كلّم الصامت خسر جولة: ضريبة (مفتاح مميز للنقلة دي عشان ماتتكررش)
    _loseCoins('pass$_cardSeq-$toIndex-${to.cards.length}', toIndex, card.label);
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
    // ضريبة الخسارة (مرة واحدة للكارت ده) + التحديات اللي اللاعب ده فيها
    _loseCoins('card$_cardSeq', index, card.label);

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
    // محدش خسر: مكافأة لصاحب الدور (لو الأدمن مفعّلها)
    _coin(economy.reward('nobody$_cardSeq', currentIndex, economy.config.rewardNobodyLost, 'nobodyLost', nowMs));
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
  // ساعة كل لاعب (الأدوار)
  // -----------------------------------------------------------------
  // الدور بيبدأ لما صاحب الدور يسحب الكارت، وبيخلص لما الكارت يخلص (أو الهوست ينهيه).
  // كل دور بيتسجل لوحده، فوقت لاعب مابيتمسحش لما لاعب تاني يبدأ.
  // =================================================================
  void _startTurn(String? card) {
    if (activeTurn != null) return; // مفيش دورين شغالين في نفس الوقت
    turns.add(TurnRecord(player: currentIndex, card: card, startedAt: nowMs));
  }

  void _endTurn() {
    final turn = activeTurn;
    if (turn == null) return;
    final now = nowMs;
    if (turn.pausedAt != null) {
      turn.pausedMs += now - turn.pausedAt!;
      turn.pausedAt = null;
    }
    turn.endedAt = now;
    if (turn.status == TurnStatus.active) turn.status = TurnStatus.finished;
    if (turn.player < players.length) {
      _addLog(UiText.logTurnEnded, {'name': players[turn.player].name, 'time': formatClock(turn.elapsedMs(now))});
    }
  }

  /// الهوست: إيقاف/تكملة ساعة الدور الشغال
  void toggleTurnPause() {
    final turn = activeTurn;
    if (isViewer || turn == null) return;
    final now = nowMs;
    if (turn.pausedAt == null) {
      turn.pausedAt = now;
    } else {
      turn.pausedMs += now - turn.pausedAt!;
      turn.pausedAt = null;
    }
    notifyListeners();
  }

  /// الهوست: ينهي ساعة الدور الحالي (الكارت نفسه بيكمل عادي)
  void endTurnNow() {
    if (isViewer || activeTurn == null) return;
    _endTurn();
    notifyListeners();
  }

  /// الهوست: يسجل إن صاحب الدور جاوب أو ماجاوبش (على الدور الشغال أو آخر دور)
  void markTurn(TurnStatus status) {
    final turn = lastTurn;
    if (isViewer || turn == null || turn.status == TurnStatus.skipped) return;
    if (status != TurnStatus.answered && status != TurnStatus.noAnswer) return;
    turn.status = status;
    // مكافأة "جاوب" (ولو الهوست غيّرها لـ "ماجاوبش" بتترجع)
    final rewardKey = 'answered${turns.indexOf(turn)}';
    if (status == TurnStatus.answered) {
      _coin(economy.reward(rewardKey, turn.player, economy.config.rewardAnswered, 'answered', nowMs));
    } else {
      _coin(economy.revokeReward(rewardKey, nowMs));
    }
    if (turn.player < players.length) {
      _addLog(UiText.logTurnStatus, {
        'name': players[turn.player].name,
        'status': status == TurnStatus.answered ? UiText.turnAnswered : UiText.turnNoAnswer,
      });
    }
    notifyListeners();
  }

  /// الهوست: يعدّي دور لاعب من غير ما يسحب (الدور بيتسجل "اتعدّى")
  void skipPlayer() {
    if (!canSkipPlayer || _busy) return;
    final now = nowMs;
    turns.add(TurnRecord(player: currentIndex, card: null, startedAt: now, endedAt: now, status: TurnStatus.skipped));
    _addLog(UiText.logPlayerSkipped, {'name': currentPlayer.name});
    sound.play(Sfx.boing);
    currentIndex = (currentIndex + 1) % players.length;
    notifyListeners();
  }

  // =================================================================
  // زرار التصفيق (التسقيف): أول وآخر واحد صقّف
  // =================================================================

  /// موبايل اللاعب: صقّفت (بتتبعت للهوست وهو اللي بيسجل الترتيب)
  void requestClap() {
    if (!canClap) return;
    // نعرض "صقّفت" على طول، والهوست بيأكد في الحالة الجاية
    clapTaps.add(ClapTap(myPlayerIndex!, nowMs));
    HapticFeedback.mediumImpact();
    room?.sendAction({'type': 'clap', 'player': myPlayerIndex, 'device': deviceId});
    notifyListeners();
  }

  /// الهوست: تسجيل ضغطة تصفيق (ضغطة واحدة لكل لاعب، والترتيب = ترتيب الوصول)
  bool registerClap(int player) {
    if (isViewer || !clapOpen || phase != CardPhase.clapGo || !clapActive) return false;
    if (player < 0 || player >= players.length) return false;
    if (clapTaps.any((t) => t.player == player)) return false; // صقّف قبل كده
    clapTaps.add(ClapTap(player, nowMs));
    sound.play(Sfx.clap);
    // الكل صقّف: التصفيق بيتقفل لوحده ويظهر الأول والأخير
    if (clapNeedsEveryone && clapWaitingFor.isEmpty) {
      _closeClap();
      phase = CardPhase.choosing;
    }
    notifyListeners();
    return true;
  }

  /// أكتر من موبايل والهوست أو حد ماسك لاعب: التصفيق محتاج الكل يدوسوا
  bool get clapNeedsEveryone => (room != null || onlineForTest) && clapPlayers.isNotEmpty;

  /// للاختبارات: نعتبر إننا في قعدة أونلاين (من غير نت)
  @visibleForTesting
  bool onlineForTest = false;

  /// فيه قعدة أونلاين مفتوحة؟
  bool get inOnlineRoom => room != null || onlineForTest;

  /// اللاعيبة اللي لازم يصقّفوا: كل لاعب ليه موبايل متصل (والهوست لو اختار هو مين)
  Set<int> get clapPlayers {
    final now = nowMs;
    return {
      for (final e in claims.entries)
        if (e.key < players.length && (e.value == deviceId || isViewer || now - (lobby[e.value]?.lastSeen ?? 0) < 50000)) e.key,
    };
  }

  /// لسه مين ماصقّفش
  Set<int> get clapWaitingFor => clapPlayers.difference({for (final t in clapTaps) t.player});

  /// قفل التصفيق: الترتيب بيتثبت وبيتحدد أول وآخر واحد
  void _closeClap() {
    if (!clapOpen) return;
    clapOpen = false;
    if (clapTaps.isNotEmpty) {
      lastClapOrder = [for (final t in clapTaps) if (t.player < players.length) players[t.player].name];
      _coin(economy.reward('clap$_cardSeq', clapTaps.first.player, economy.config.rewardClapFirst, 'clapFirst', nowMs));
      _addLog(UiText.logClapResult, {
        'first': players[clapTaps.first.player].name,
        'last': players[clapTaps.last.player].name,
      });
    }
  }

  /// الهوست: يفتح التصفيق تاني (لو اتقفل بدري) - الضغطات القديمة بتفضل
  void reopenClap() {
    if (isViewer || !clapActive || clapOpen || currentCard == null) return;
    clapOpen = true;
    phase = CardPhase.clapGo;
    notifyListeners();
  }

  // =================================================================
  // الأزرار السريعة: كل لاعب بيدوس إيموجي فيظهر في نص اللعبة عند الكل
  // (مابيتحفظش في أي مكان، والهوست بيتأكد من الإيموجي والسرعة)
  // =================================================================

  /// الزراير متاحة؟ (الأدمن ممكن يقفلها)
  bool get reactionsOn => AppSettings.current.reactionsEnabled && screen == AppScreen.game;

  /// إيموجي مقبول: كلام قصير مفيهوش حروف أو أرقام (عشان محدش يبعت رسايل من هنا)
  static bool isValidReaction(Object? emoji) {
    if (emoji is! String) return false;
    final text = emoji.trim();
    if (text.isEmpty || text.runes.length > 8) return false;
    return !RegExp(r'[A-Za-z0-9؀-ۿ<>]').hasMatch(text);
  }

  /// تغيير زرار من الـ 5
  void setReactionButton(int index, String emoji) {
    if (index < 0 || index >= reactionButtons.length || !isValidReaction(emoji)) return;
    reactionButtons[index] = emoji.trim();
    notifyListeners();
  }

  /// دوست زرار: الهوست بيعرضه ويبعته للكل، واللاعب بيبعته للهوست
  void sendReaction(String emoji) {
    if (!reactionsOn || !isValidReaction(emoji)) return;
    if (isHost) {
      _acceptReaction(emoji, chatName, deviceId);
    } else {
      room?.sendAction({'type': 'react', 'device': deviceId, 'name': chatName, 'emoji': emoji.trim()});
    }
  }

  /// الهوست: يقبل الإيموجي (أقصى واحد كل 0.6 ثانية و 30 في الدقيقة لكل موبايل)
  bool _acceptReaction(Object? emoji, String name, String device) {
    if (!AppSettings.current.reactionsEnabled || !isValidReaction(emoji) || chat.muted.contains(device)) return false;
    final now = nowMs;
    final times = _reactionTimes.putIfAbsent(device, () => []);
    times.removeWhere((t) => now - t > 60000);
    if (times.isNotEmpty && now - times.last < 600) return false;
    if (times.length >= 30) return false;
    times.add(now);
    final text = (emoji as String).trim();
    _pushReaction(text, name);
    room?.sendEvent('react', {'e': text, 'n': name});
    return true;
  }

  void _pushReaction(String emoji, String name) {
    reactionFeed.add(Reaction(++_reactionSeq, emoji, name));
    if (reactionFeed.length > 20) reactionFeed.removeAt(0);
    notifyListeners();
  }

  /// للاختبارات: الهوست بيستقبل إيموجي من موبايل
  @visibleForTesting
  bool acceptReactionForTest(Object? emoji, String name, String device) => _acceptReaction(emoji, name, device);

  // =================================================================
  // الكوينز
  // =================================================================

  /// الكوينز شغالة في اللعبة دي؟
  bool get coinsOn => economy.config.enabled && economy.wallets.isNotEmpty;

  /// ضريبة الخسارة + التحديات (للاعب اللي خد كارت)
  void _loseCoins(String roundKey, int player, String card) {
    if (isViewer) return;
    _coins(economy.settleRound(roundKey, [player],
        category: currentRule?.category, turnPlayer: currentIndex, card: card, amount: currentRule?.cost, now: nowMs));
    _coins(economy.onCardTaken(player, nowMs));
  }

  void _coin(CoinChange? change) {
    if (change != null) _coins([change]);
  }

  /// تسجيل التغييرات للأنيميشن (آخر 12 بس)
  void _coins(List<CoinChange> changes) {
    for (final c in changes) {
      if (c.delta == 0) continue;
      coinFx.add(CoinFx(++_coinFxSeq, c.player, c.delta));
    }
    if (coinFx.length > 12) coinFx.removeRange(0, coinFx.length - 12);
  }

  String _newCoinId() => '$deviceId-${DateTime.now().millisecondsSinceEpoch}-${_coinReqSeq++}';

  /// تحويل كوينز. الهوست بينفذ على طول، وموبايل اللاعب بيبعت طلب ويستنى الرد.
  /// بيرجع كود الخطأ أو null لو تم.
  Future<String?> transferCoins(int from, int to, int amount) =>
      _coinRequest({'type': 'coinTransfer', 'from': from, 'to': to, 'amount': amount}, (id) => economy.transfer(id, from, to, amount, nowMs));

  Future<String?> inviteChallenge(int from, int to, int stake) =>
      _coinRequest({'type': 'challenge', 'from': from, 'to': to, 'stake': stake}, (id) => economy.invite(id, from, to, stake, nowMs));

  Future<String?> replyChallenge(String challengeId, bool accept) =>
      _coinRequest({'type': 'challengeReply', 'challenge': challengeId, 'accept': accept}, (_) => economy.respond(challengeId, accept, nowMs));

  Future<String?> cancelChallenge(String challengeId) {
    final c = economy.challenges.where((c) => c.id == challengeId).firstOrNull;
    if (c == null) return Future.value('invalid');
    return _coinRequest({'type': 'challengeCancel', 'challenge': challengeId},
        (_) => economy.cancelInvite(challengeId, c.from) ? null : 'invalid');
  }

  /// الهوست: تعديل يدوي لرصيد لاعب (لازم سبب، وبيتسجل في العمليات بالرصيد قبل وبعد)
  String? adjustCoins(int player, int delta, String reason) {
    if (isViewer) return 'invalid';
    final before = economy.balanceOf(player);
    final error = economy.adjust(_newCoinId(), player, delta, reason, nowMs);
    if (error == null) {
      _coins([CoinChange(player, economy.balanceOf(player) - before)]);
      notifyListeners();
    }
    return error;
  }

  Future<String?> _coinRequest(Map<String, dynamic> action, String? Function(String id) hostRun) async {
    final id = _newCoinId();
    if (isHost) {
      final before = [for (var i = 0; i < players.length; i++) economy.balanceOf(i)];
      final error = hostRun(id);
      if (error == null) _recordBalanceChanges(before);
      notifyListeners();
      return error;
    }
    final waiter = Completer<String?>();
    _coinWaiters[id] = waiter;
    room?.sendAction({...action, 'id': id, 'device': deviceId});
    return waiter.future.timeout(const Duration(seconds: 6), onTimeout: () {
      _coinWaiters.remove(id);
      return 'timeout';
    });
  }

  /// بعد عملية: نسجل تغيير كل لاعب للأنيميشن
  void _recordBalanceChanges(List<int> before) {
    _coins([
      for (var i = 0; i < before.length; i++)
        if (economy.balanceOf(i) != before[i]) CoinChange(i, economy.balanceOf(i) - before[i]),
    ]);
  }

  /// الهوست: طلب كوينز من موبايل لاعب (بنتأكد إنه ماسك اللاعب اللي بيدفع أو بيرد)
  void _receiveCoinAction(String type, Map<String, dynamic> action, String device) {
    final id = action['id'];
    if (id is! String || id.length > 60) return;
    int? number(String key) => (action[key] as num?)?.toInt();
    String? error;
    final before = [for (var i = 0; i < players.length; i++) economy.balanceOf(i)];
    switch (type) {
      case 'coinTransfer':
        final from = number('from'), to = number('to'), amount = number('amount');
        if (from == null || to == null || amount == null || claims[from] != device) {
          error = 'notYours';
        } else {
          error = economy.transfer(id, from, to, amount, nowMs);
        }
      case 'challenge':
        final from = number('from'), to = number('to'), stake = number('stake');
        if (from == null || to == null || stake == null || claims[from] != device) {
          error = 'notYours';
        } else {
          error = economy.invite(id, from, to, stake, nowMs);
        }
      case 'challengeReply':
        final c = economy.challenges.where((c) => c.id == action['challenge']).firstOrNull;
        if (c == null || claims[c.to] != device) {
          error = 'notYours';
        } else {
          error = economy.respond(c.id, action['accept'] == true, nowMs);
        }
      case 'challengeCancel':
        final c = economy.challenges.where((c) => c.id == action['challenge']).firstOrNull;
        if (c == null || claims[c.from] != device) {
          error = 'notYours';
        } else if (!economy.cancelInvite(c.id, c.from)) {
          error = 'invalid';
        }
    }
    if (error == null) _recordBalanceChanges(before);
    room?.sendEvent('coinResult', {'id': id, 'device': device, 'error': ?error});
    notifyListeners();
  }

  // =================================================================
  // إيقاف اللعبة مؤقتاً (الهوست)
  // =================================================================
  void togglePause() {
    if (isViewer || screen != AppScreen.game) return;
    final now = DateTime.now();
    if (!paused) {
      paused = true;
      // نحفظ الوقت الفاضل في مؤقت السؤال والقنبلة ونوقفهم
      if (questionEndsAt != null) {
        _pausedQuestionLeft = questionEndsAt!.difference(now);
        _stopQuestionTimer();
      }
      if (phase == CardPhase.bombTicking && bombEndsAt != null) {
        _pausedBombLeft = bombEndsAt!.difference(now);
        _bombTimer?.cancel();
        _tickTimer?.cancel();
        _bombTimer = null;
        _tickTimer = null;
      }
      final turn = activeTurn;
      if (turn != null && !turn.isPaused) {
        turn.pausedAt = nowMs;
        _turnPausedByGame = true;
      }
      _addLog(UiText.logPaused, {});
    } else {
      paused = false;
      final q = _pausedQuestionLeft;
      _pausedQuestionLeft = null;
      if (q != null && phase == CardPhase.front) _armQuestionTimer(q);
      final b = _pausedBombLeft;
      _pausedBombLeft = null;
      if (b != null && phase == CardPhase.bombTicking) _armBomb(b);
      final turn = activeTurn;
      if (_turnPausedByGame && turn != null && turn.pausedAt != null) {
        turn.pausedMs += nowMs - turn.pausedAt!;
        turn.pausedAt = null;
      }
      _turnPausedByGame = false;
      _addLog(UiText.logResumed, {});
    }
    notifyListeners();
  }

  // =================================================================
  // الدور جوه الكارت: سهم بيلف على اللاعيبة والهوست بيحركه
  // (مؤقت السؤال بيبدأ من الأول مع كل لاعب)
  // =================================================================
  void moveInnerTurn(int step) {
    final current = innerTurn;
    if (isViewer || current == null || players.isEmpty || paused) return;
    innerTurn = (current + step) % players.length;
    if (innerTurn! < 0) innerTurn = innerTurn! + players.length;
    final rule = currentRule;
    if (rule != null && rule.timed && phase == CardPhase.front) {
      final seconds = questionSecondsFor(rule);
      if (seconds > 0) _startQuestionTimer(seconds);
    }
    sound.play(Sfx.tick);
    notifyListeners();
  }

  // =================================================================
  // الإجابة: الهوست بيكشفها للكل
  // =================================================================
  void toggleAnswer() {
    final answer = currentRule?.answer;
    if (isViewer || answer == null || currentCard == null) return;
    answerShown = !answerShown;
    if (answerShown) _addLog(UiText.logAnswerShown, {'answer': answer});
    notifyListeners();
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
    // الكارت اتدى بالغلط: الضريبة بتاعته بترجع
    _coin(economy.refundTaxForCard(playerIndex, card.label, nowMs));
    _emit(GameEventKind.correction, playerIndex, 1);
    sound.play(Sfx.ding);
    notifyListeners();
    return true;
  }

  /// الانتقال للدور اللي بعده (أو إعادة نفس الدور لو sameTurn = true)
  void _nextTurn({bool sameTurn = false}) {
    _cancelTimers();
    _endTurn();
    currentCard = null;
    currentRule = null;
    phase = CardPhase.back;
    timedOut = false;
    answerShown = false;
    clapOpen = false;
    clapTaps.clear();
    innerTurn = null;
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
    _armBomb(Duration(seconds: seconds));
    notifyListeners();
  }

  /// تشغيل عداد القنبلة (من الأول، أو من الوقت الفاضل بعد الإيقاف المؤقت)
  void _armBomb(Duration duration) {
    final seq = _cardSeq;
    bombEndsAt = DateTime.now().add(duration);
    sound.play(Sfx.tick);
    // التكة كل ثانية، وفي آخر 5 ثواني بتسرّع (كل نص ثانية) كتحذير
    var halfSeconds = 0;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      halfSeconds++;
      final left = bombEndsAt?.difference(DateTime.now()) ?? Duration.zero;
      if (left.inMilliseconds <= 5000 || halfSeconds.isEven) sound.play(Sfx.tick);
    });
    _bombTimer = Timer(duration, () {
      if (seq == _cardSeq) _explode();
    });
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
    if (index < 0 || index >= players.length) return;
    final owner = claims[index];
    if (owner != null && owner != deviceId) return; // حد تاني ماسكه
    myPlayerIndex = index;
    if (isHost) {
      // الهوست لاعب كمان (في التصفيق مثلاً): بيمسك اللاعب بتاعه على طول
      claims.removeWhere((_, d) => d == deviceId);
      claims[index] = deviceId;
    } else {
      room?.sendAction({'type': 'claim', 'player': index, 'device': deviceId});
    }
    notifyListeners();
  }

  /// موبايل اللاعب: يغيّر اللاعب اللي هو ماسكه
  void releaseSeat() {
    myPlayerIndex = null;
    if (isHost) {
      claims.removeWhere((_, d) => d == deviceId);
    } else {
      room?.sendAction({'type': 'release', 'device': deviceId});
    }
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
    if (kicked.contains(device)) return; // موبايل مطرود: أي طلب منه بيتجاهل
    // أي طلب = الموبايل ده لسه متصل
    final member = lobby[device];
    if (member != null) {
      member.lastSeen = nowMs;
    } else if (type != 'release') {
      lobby[device] = LobbyMember(_cleanName(action['name']), nowMs);
    }

    switch (type) {
      case 'ping':
        lobby[device] = LobbyMember(_cleanName(action['name'] ?? lobby[device]?.name), nowMs);
        break;
      case 'chat':
        _receiveChat(action, device);
        break;
      case 'react':
        _acceptReaction(action['emoji'], lobby[device]?.name ?? _cleanName(action['name']), device);
        break;
      // الكوينز: كل طلب لازم يكون من الموبايل الماسك اللاعب اللي بيدفع/بيرد
      case 'coinTransfer':
      case 'challenge':
      case 'challengeReply':
      case 'challengeCancel':
        _receiveCoinAction(type!, action, device);
        break;
      case 'chatDelete':
        final id = action['id'];
        if (id is String && chat.delete(id, byDevice: device, byHost: false)) {
          room?.sendEvent('chatDel', {'id': id});
          notifyListeners();
        }
        break;
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
        lobby.remove(device);
        notifyListeners();
        break;
      case 'draw':
        // مسموح بس: في شاشة اللعب، والكارت مقلوب، والطلب من الموبايل الماسك صاحب الدور
        if (paused || screen != AppScreen.game || phase != CardPhase.back) return;
        if (player != currentIndex || claims[currentIndex] != device) return;
        if (!_debounce()) return;
        _drawCard();
        break;
      case 'clap':
        // مسموح بس: التصفيق مفتوح، والطلب من الموبايل الماسك اللاعب ده، وأول ضغطة ليه
        if (paused || screen != AppScreen.game || player == null || claims[player] != device) return;
        registerClap(player);
        break;
      default:
        // أي طلب تاني (سكيب، اختيار خسران، تعديل كروت...) مش مسموح من موبايل لاعب
        break;
    }
  }

  // =================================================================
  // الشات: الهوست بيقبل/يرفض، واللاعيبة بيبعتوا ويستقبلوا
  // =================================================================

  /// بعت رسالة (كلام أو صوت). الهوست بيضيفها على طول، واللاعب بيبعتها للهوست.
  /// بترجع سبب الرفض لو اترفضت عند الهوست نفسه.
  ChatRejection? sendChat(String text) {
    final settings = AppSettings.current;
    final clean = text.trim();
    if (clean.isEmpty) return ChatRejection.empty;
    if (clean.length > settings.chatMaxLength) return ChatRejection.tooLong;
    final id = '$deviceId-${DateTime.now().millisecondsSinceEpoch}-${_chatSeq++}';
    if (isHost) {
      final rejected = chat.accept(
        id: id,
        device: deviceId,
        name: chatName,
        text: clean,
        context: _chatContext,
        now: nowMs,
        enabled: chatAvailable,
        maxLength: settings.chatMaxLength,
        perMinute: settings.chatPerMinute,
        fromHost: true,
      );
      if (rejected == null) {
        room?.sendEvent('chat', chat.messages.last.toJson());
        notifyListeners();
      }
      return rejected;
    }
    final pending = PendingChat(id: id, text: clean);
    pendingChat[id] = pending;
    _sendPending(pending);
    notifyListeners();
    return null;
  }

  /// إعادة إرسال رسالة فشلت (بنفس الـ id، فالهوست مابيكررهاش)
  void retryChat(String id) {
    final pending = pendingChat[id];
    if (pending == null) return;
    pending.failed = null;
    _sendPending(pending);
    notifyListeners();
  }

  void discardChat(String id) {
    pendingChat.remove(id);
    notifyListeners();
  }

  void _sendPending(PendingChat pending) {
    room?.sendAction({
      'type': 'chat',
      'device': deviceId,
      'name': chatName,
      'id': pending.id,
      'text': pending.text,
    });
    // لو الهوست مردش في 6 ثواني: الرسالة "ماوصلتش" وتقدر تعيد
    pending.timer?.cancel();
    pending.timer = Timer(const Duration(seconds: 6), () {
      if (pendingChat.containsKey(pending.id) && pending.failed == null) {
        pending.failed = ChatRejection.invalid;
        notifyListeners();
      }
    });
  }

  /// الهوست: رسالة جاية من موبايل لاعب
  void _receiveChat(Map<String, dynamic> action, String device) {
    final id = action['id'];
    final text = action['text'];
    if (id is! String) return;
    final settings = AppSettings.current;
    final rejected = chat.accept(
      id: id,
      device: device,
      name: lobby[device]?.name ?? _cleanName(action['name']),
      text: text is String ? text : '',
      context: _chatContext,
      now: nowMs,
      enabled: chatAvailable,
      maxLength: settings.chatMaxLength,
      perMinute: settings.chatPerMinute,
    );
    if (rejected != null) {
      room?.sendEvent('chatReject', {'id': id, 'device': device, 'reason': rejected.name});
      return;
    }
    // الرسالة المقبولة (أو المكررة اللي اتقبلت قبل كده) بتتبعت للكل
    final message = chat.messages.lastWhere((m) => m.id == id, orElse: () => chat.messages.last);
    room?.sendEvent('chat', message.toJson());
    if (!chatOpen) chatUnread++;
    notifyListeners();
  }

  /// مسح رسالة: صاحبها أو الهوست
  void deleteChat(String id) {
    if (isHost) {
      if (chat.delete(id, byDevice: deviceId, byHost: true)) {
        room?.sendEvent('chatDel', {'id': id});
        notifyListeners();
      }
    } else {
      room?.sendAction({'type': 'chatDelete', 'device': deviceId, 'id': id});
    }
  }

  /// الهوست: كتم/فك كتم موبايل في الشات
  void toggleMute(String device) {
    if (isViewer) return;
    if (!chat.muted.remove(device)) chat.muted.add(device);
    notifyListeners();
  }

  /// الهوست: طرد موبايل من القعدة (بيفقد اللاعب اللي ماسكه ومايقدرش يبعت حاجة تاني)
  void kick(String device) {
    if (isViewer || device == deviceId) return;
    kicked.add(device);
    lobby.remove(device);
    claims.removeWhere((_, d) => d == device);
    notifyListeners();
  }

  /// فتح/قفل نافذة الشات (والرسايل بتبقى "اتقرت")
  void setChatOpen(bool open) {
    chatOpen = open;
    if (open) chatUnread = 0;
    notifyListeners();
  }

  void setNickname(String name) {
    nickname = _cleanName(name);
    if (nickname == 'Guest') nickname = '';
    notifyListeners();
  }

  /// موبايل اللاعب: حدث صغير من الهوست
  void _onRoomEvent(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'chat':
        final message = ChatMessage.fromJson(data);
        if (message == null) return;
        pendingChat.remove(message.id)?.timer?.cancel();
        if (chatView.any((m) => m.id == message.id)) return; // وصلت قبل كده
        chatView.add(message);
        if (chatView.length > ChatRoom.historySize) chatView.removeAt(0);
        if (!chatOpen && message.device != deviceId) chatUnread++;
        break;
      case 'chatDel':
        chatView.removeWhere((m) => m.id == data['id']);
        break;
      case 'react':
        final emoji = data['e'], name = data['n'];
        if (!isValidReaction(emoji) || name is! String) return;
        _pushReaction(emoji as String, name);
        break;
      case 'coinResult':
        if (data['device'] != deviceId) return;
        final waiter = _coinWaiters.remove(data['id']);
        waiter?.complete(data['error'] as String?);
        return;
      case 'chatReject':
        if (data['device'] != deviceId) return;
        final pending = pendingChat[data['id']];
        if (pending == null) return;
        pending.timer?.cancel();
        pending.failed = ChatRejection.values.firstWhere((r) => r.name == data['reason'], orElse: () => ChatRejection.invalid);
        break;
      default:
        return;
    }
    notifyListeners();
  }

  /// موبايل اللاعب: اللوبي والشات من الحالة
  void _applyLobby(Map<String, dynamic> s) {
    final rawLobby = s['lobby'];
    if (rawLobby is List) {
      lobby
        ..clear()
        ..addEntries([
          for (final m in rawLobby)
            if (m is Map && m['d'] is String)
              MapEntry(m['d'] as String, LobbyMember(_cleanName(m['n']), (m['on'] == true) ? nowMs : 0, muted: m['m'] == true)),
        ]);
    }
    final rawKicked = s['kicked'];
    if (rawKicked is List && rawKicked.contains(deviceId)) {
      wasKicked = true;
      viewerHasState = false;
      _wipeViewerSession();
      room?.close();
      return;
    }
    final history = s['chat'];
    if (history is List) {
      // دمج: الرسايل اللي عندي + اللي جاية (من غير تكرار)، بالترتيب
      final byId = {for (final m in chatView) m.id: m};
      for (final raw in history) {
        final m = ChatMessage.fromJson(raw);
        if (m != null) {
          final mine = byId[m.id];
          if (mine == null) byId[m.id] = m;
          pendingChat.remove(m.id)?.timer?.cancel();
        }
      }
      chatView
        ..clear()
        ..addAll(byId.values.toList()..sort((a, b) => a.at.compareTo(b.at)));
    }
  }

  void _wipeViewerSession() {
    for (final p in pendingChat.values) {
      p.timer?.cancel();
    }
    chatView.clear();
    pendingChat.clear();
    lobby.clear();
    chatUnread = 0;
  }

  /// للاختبارات: حدث من الهوست وصل للموبايل
  @visibleForTesting
  void onRoomEventForTest(String event, Map<String, dynamic> data) => _onRoomEvent(event, data);

  // =================================================================
  // مزامنة الموبايلات (أكتر من موبايل)
  // =================================================================

  /// كل ما الحالة تتغير: الواجهة تتحدث، ولو إحنا الهوست نبعت الحالة للاعيبة
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (room != null && room!.isHost) _broadcastState();
  }

  void _broadcastState({bool withChat = false}) {
    final snapshot = _toSnapshot();
    // الشات القديم بيتبعت بس لما حد يدخل/يرجع (مش مع كل تغيير، عشان الرسايل تفضل صغيرة وسريعة)
    if (withChat) snapshot['chat'] = [for (final m in chat.messages) m.toJson()];
    room?.sendState(snapshot);
  }

  /// نسخة الحالة اللي بتتبعت للموبايلات (للاختبارات)
  @visibleForTesting
  Map<String, dynamic> snapshotForTest() => _toSnapshot();

  /// موبايل لاعب بيطبّق حالة جاية من الهوست (للاختبارات)
  @visibleForTesting
  void applySnapshotForTest(Map<String, dynamic> s) => _applySnapshot(s);

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
      // الإجابة مابتتبعتش للموبايلات غير بعد ما الهوست يكشفها
      'rule': (answerShown ? currentRule : currentRule?.withoutAnswer())?.toJson(),
      'answerShown': answerShown,
      'now': DateTime.now().millisecondsSinceEpoch,
      'turns': [for (final t in turns.length > 80 ? turns.sublist(turns.length - 80) : turns) t.toJson()],
      'clapOpen': clapOpen,
      'clapTaps': [for (final t in clapTaps) [t.player, t.at]],
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
      'status': roomStatus,
      'paused': paused,
      'inner': innerTurn,
      'clapOrder': lastClapOrder,
      'eco': economy.toJson(),
      'coinFx': [for (final c in coinFx) [c.id, c.player, c.delta]],
      'lobby': [
        for (final e in lobby.entries)
          {'d': e.key, 'n': e.value.name, 'on': nowMs - e.value.lastSeen < 50000, if (chat.muted.contains(e.key)) 'm': true},
      ],
      'kicked': kicked.toList(),
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
    if (screenName == 'closed') {
      roomClosed = true;
      viewerHasState = false;
      _wipeViewerSession(); // القعدة اتقفلت: الشات واللوبي بيتمسحوا من الموبايل على طول
      notifyListeners();
      return;
    }
    // اللوبي والشات بيتحدثوا حتى والهوست لسه في الإعداد
    _applyLobby(s);
    if (wasKicked) {
      notifyListeners();
      return;
    }
    if (screenName == 'waiting') {
      viewerHasState = false;
      screen = AppScreen.game;
      notifyListeners();
      return;
    }

    viewerHasState = true;
    // فرق ساعة الموبايل عن ساعة الهوست (عشان العدادات تبقى مظبوطة على كل الموبايلات)
    final hostNow = (s['now'] as num?)?.toInt();
    if (hostNow != null) clockOffset = hostNow - DateTime.now().millisecondsSinceEpoch;
    screen = screenName == 'results' ? AppScreen.results : AppScreen.game;
    _viewerModeName = LText.fromJson(Map<String, dynamic>.from(s['mode'] as Map));
    final list = (s['players'] as List).cast<Map>();
    players = [
      for (var i = 0; i < list.length; i++)
        Player(list[i]['name'] as String, i)
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
    questionEndsAt = qEnds == null ? null : DateTime.fromMillisecondsSinceEpoch(qEnds - clockOffset);
    answerShown = s['answerShown'] as bool? ?? false;
    paused = s['paused'] as bool? ?? false;
    innerTurn = (s['inner'] as num?)?.toInt();
    lastClapOrder = [for (final n in (s['clapOrder'] as List? ?? [])) if (n is String) n];
    final eco = s['eco'];
    if (eco is Map) economy.applyJson(eco);
    final fx = s['coinFx'];
    if (fx is List) {
      coinFx
        ..clear()
        ..addAll([for (final c in fx) if (c is List && c.length == 3) CoinFx((c[0] as num).toInt(), (c[1] as num).toInt(), (c[2] as num).toInt())]);
    }
    turns
      ..clear()
      ..addAll([for (final t in (s['turns'] as List? ?? [])) TurnRecord.fromJson(t as Map)]);
    clapOpen = s['clapOpen'] as bool? ?? false;
    clapTaps
      ..clear()
      ..addAll([
        for (final t in (s['clapTaps'] as List? ?? []))
          ClapTap(((t as List)[0] as num).toInt(), (t[1] as num).toInt()),
      ]);
    timedOut = s['timedOut'] as bool? ?? false;
    final bombEnds = (s['bombEnds'] as num?)?.toInt();
    bombEndsAt = bombEnds == null ? null : DateTime.fromMillisecondsSinceEpoch(bombEnds - clockOffset);
    lastEvent = GameEvent.fromJson(s['event']);
    final rawClaims = s['claims'];
    claims = rawClaims is Map
        ? {for (final e in rawClaims.entries) int.parse(e.key as String): e.value as String}
        : {};
    final next = s['next'];
    _viewerNext = next is Map ? Map<String, dynamic>.from(next) : null;

    // الهوست ربط الموبايل ده باسمه لما بدأ اللعب: نعرف إحنا مين على طول
    final mineByHost = claims.entries.where((e) => e.value == deviceId).map((e) => e.key).firstOrNull;
    if (mineByHost != null) myPlayerIndex = mineByHost;
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
    _pingTimer?.cancel();
    _cancelTimers();
    _pendingTimer?.cancel();
    _closeRoom();
    super.dispose();
  }
}

/// وقت بشكل ساعة إيقاف: 00:35 أو 1:02:05
String formatClock(int ms) {
  final total = max(0, ms) ~/ 1000;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, sec = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}
