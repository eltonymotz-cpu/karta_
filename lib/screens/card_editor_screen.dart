// =================================================================
// محرر الكارت (لوحة الأدمن) مع معاينة لايف
// -----------------------------------------------------------------
// - المحتوى: العنوان، السطر الصغير، الشرح، سؤال الاختيار، الإيموجي (عربي + فرانكو)
// - الشكل: الألوان، الحدود، الأيقونة (ستيكر أو صورة مرفوعة) وحجمها ومكانها،
//   صورة الخلفية، النقشة، المحاذاة، شكل الضهر
// - اللعب: النوع، مفعّل ولا لأ، المؤقت، عدد النسخ (للكروت الزيادة)
// المعاينة فوق بتستخدم نفس كود رسم الكارت في اللعبة، فاللي بتشوفه هو اللي اللاعيبة هيشوفوه.
// الحفظ بيروح لـ Supabase، ولو فشل مفيش حاجة بتتغير.
// =================================================================
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/mode_store.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';
import 'asset_library_screen.dart';
import 'card_library_screen.dart';

class CardEditorScreen extends StatefulWidget {
  final GameController game;
  final String modeId;
  final String? label; // null = كارت زيادة جديد
  const CardEditorScreen({super.key, required this.game, required this.modeId, this.label});

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  GameController get game => widget.game;
  bool get _isNew => widget.label == null;
  bool get _isExtra => _isNew || !cardRanks.contains(widget.label);

  // ---------------- المحتوى ----------------
  final _label = TextEditingController();
  final _emoji = TextEditingController();
  final _titleAr = TextEditingController();
  final _titleFr = TextEditingController();
  final _subAr = TextEditingController();
  final _subFr = TextEditingController();
  final _descAr = TextEditingController();
  final _descFr = TextEditingController();
  final _promptAr = TextEditingController();
  final _promptFr = TextEditingController();
  final _answerAr = TextEditingController();
  final _answerFr = TextEditingController();
  final _clapTextAr = TextEditingController();
  final _clapTextFr = TextEditingController();
  final _clapIcon = TextEditingController();

  // ---------------- اللعب ----------------
  RuleType _type = RuleType.assign;
  bool _silence = false;
  bool _enabled = true;
  bool _timed = false;
  int? _timerSeconds;
  int _copies = 2;
  bool _clapOn = false;
  ClapButtonStyle _clapStyle = const ClapButtonStyle();

  // ---------------- الشكل ----------------
  int? _bg, _bar, _text, _border, _back;
  String _borderStyle = 'solid';
  String? _sticker;
  String? _iconUrl;
  double _iconScale = 1.0;
  String _iconPos = 'top';
  String? _artworkUrl;
  double _artworkOpacity = 0.25;
  String _pattern = 'none';
  String _align = 'center';
  String _backPattern = 'auto';
  bool _titleOnBack = false;

  // ---------------- حالة المحرر ----------------
  String _preview = 'front'; // front / back / mobile
  String? _originalIcon, _originalArtwork;
  final Set<String> _newUploads = {};
  bool _saved = false;
  bool _saving = false;
  String? _uploading; // icon / artwork

  @override
  void initState() {
    super.initState();
    CardRule rule;
    var copies = 2;
    if (_isNew) {
      rule = getRule('classic', 'A').copyWith(enabled: true); // بداية جاهزة يعدّل عليها
      _label.text = _suggestLabel();
    } else {
      final entry = cardsOf(widget.modeId).firstWhere((c) => c.rank == widget.label);
      rule = entry.rule;
      copies = entry.copies;
      _label.text = entry.rank;
    }
    _fill(rule, copies);
  }

  String _suggestLabel() {
    final taken = {...cardRanks, ...?allModes[widget.modeId]?.extraCards.map((x) => x.label)};
    for (var i = 1; i < 100; i++) {
      if (!taken.contains('X$i')) return 'X$i';
    }
    return 'XX';
  }

  void _fill(CardRule rule, int copies) {
    _emoji.text = rule.emoji;
    _titleAr.text = rule.title.ar;
    _titleFr.text = rule.title.fr;
    _subAr.text = rule.subtitle?.ar ?? '';
    _subFr.text = rule.subtitle?.fr ?? '';
    _descAr.text = rule.description.ar;
    _descFr.text = rule.description.fr;
    _promptAr.text = rule.prompt?.ar ?? '';
    _promptFr.text = rule.prompt?.fr ?? '';
    _type = rule.type;
    _silence = rule.setsSilence;
    _enabled = rule.enabled;
    _timed = rule.timed;
    _timerSeconds = rule.timerSeconds;
    _copies = copies;
    _answerAr.text = rule.answer?.ar ?? '';
    _answerFr.text = rule.answer?.fr ?? '';
    _clapOn = rule.hasClapButton;
    _clapStyle = rule.clapStyle;
    _clapTextAr.text = rule.clapStyle.text?.ar ?? '';
    _clapTextFr.text = rule.clapStyle.text?.fr ?? '';
    _clapIcon.text = rule.clapStyle.icon;
    final d = rule.design;
    _bg = d.bg;
    _bar = d.bar;
    _text = d.text;
    _border = d.border;
    _back = d.back;
    _borderStyle = d.borderStyle;
    _sticker = d.sticker;
    _iconUrl = d.iconUrl;
    _originalIcon = d.iconUrl;
    _iconScale = d.iconScale;
    _iconPos = d.iconPos;
    _artworkUrl = d.artworkUrl;
    _originalArtwork = d.artworkUrl;
    _artworkOpacity = d.artworkOpacity;
    _pattern = d.pattern;
    _align = d.align;
    _backPattern = d.backPattern;
    _titleOnBack = d.titleOnBack;
  }

  @override
  void dispose() {
    for (final c in [
      _label,
      _emoji,
      _titleAr,
      _titleFr,
      _subAr,
      _subFr,
      _descAr,
      _descFr,
      _promptAr,
      _promptFr,
      _answerAr,
      _answerFr,
      _clapTextAr,
      _clapTextFr,
      _clapIcon,
    ]) {
      c.dispose();
    }
    // خرجنا من غير حفظ: نمسح الصور اللي اترفعت ومااتستخدمتش
    if (!_saved) {
      for (final url in _newUploads) {
        StorageService.deleteByUrl(url);
      }
    }
    super.dispose();
  }

  String get _rank => _isExtra ? (_label.text.trim().isEmpty ? '?' : _label.text.trim()) : widget.label!;
  String get _suit => _isExtra ? extraSuit : '♥';

  /// القاعدة من الخانات الحالية (المعاينة والحفظ بيستخدموها)
  CardRule _buildRule({bool stamp = false}) {
    LText? optional(TextEditingController ar, TextEditingController fr) {
      final a = ar.text.trim(), f = fr.text.trim();
      if (a.isEmpty && f.isEmpty) return null;
      return LText(a.isEmpty ? f : a, f.isEmpty ? a : f);
    }

    String pick(String a, String b) => a.trim().isNotEmpty ? a.trim() : b.trim();
    return CardRule(
      emoji: _emoji.text.trim().isEmpty ? '🃏' : _emoji.text.trim(),
      title: LText(pick(_titleAr.text, _titleFr.text), pick(_titleFr.text, _titleAr.text)),
      description: LText(pick(_descAr.text, _descFr.text), pick(_descFr.text, _descAr.text)),
      type: _type,
      prompt: optional(_promptAr, _promptFr),
      setsSilence: _silence,
      subtitle: optional(_subAr, _subFr),
      enabled: _enabled,
      timed: _timed,
      timerSeconds: _timed ? _timerSeconds : null,
      design: CardDesign(
        bg: _bg,
        bar: _bar,
        text: _text,
        border: _border,
        borderStyle: _borderStyle,
        sticker: _iconUrl == null ? _sticker : null,
        iconUrl: _iconUrl,
        iconScale: _iconScale,
        iconPos: _iconPos,
        artworkUrl: _artworkUrl,
        artworkOpacity: _artworkOpacity,
        pattern: _pattern,
        align: _align,
        back: _back,
        backPattern: _backPattern,
        titleOnBack: _titleOnBack,
      ),
      updatedAt: stamp ? DateTime.now().toIso8601String() : null,
      clapButton: _clapOn && CardRule.clapAllowedFor(_type),
      clapStyle: _clapStyle.copyWith(
        text: optional(_clapTextAr, _clapTextFr),
        clearText: optional(_clapTextAr, _clapTextFr) == null,
        icon: _clapIcon.text.trim().isEmpty ? '👏' : _clapIcon.text.trim(),
      ),
      answer: optional(_answerAr, _answerFr),
    );
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: error ? AppColors.red : AppColors.green,
      ),
    );
  }

  /// رفع صورة (أيقونة أو خلفية)
  Future<void> _upload(String kind) async {
    setState(() => _uploading = kind);
    final result = await StorageService.pickAndUpload(
      folder: kind == 'icon' ? 'icons' : 'artwork',
      maxSide: kind == 'icon' ? 400 : 900,
    );
    if (!mounted) return;
    setState(() => _uploading = null);
    if (result.error != null) return _snack(result.error!, error: true);
    if (result.url == null) return;
    _newUploads.add(result.url!);
    setState(() {
      if (kind == 'icon') {
        _discardUnsaved(_iconUrl, _originalIcon);
        _iconUrl = result.url;
      } else {
        _discardUnsaved(_artworkUrl, _originalArtwork);
        _artworkUrl = result.url;
      }
    });
    _snack(game.t(UiText.uploaded));
  }

  /// اختيار صورة من المكتبة (للأيقونة أو الخلفية)
  Future<void> _fromLibrary(String kind) async {
    final ref = await pickLibraryAsset(context, game);
    if (ref == null || !mounted) return;
    setState(() {
      if (kind == 'icon') {
        _discardUnsaved(_iconUrl, _originalIcon);
        _iconUrl = ref;
      } else {
        _discardUnsaved(_artworkUrl, _originalArtwork);
        _artworkUrl = ref;
      }
    });
  }

  /// صورة اترفعت في الجلسة دي واتغيرت قبل الحفظ: نمسحها
  void _discardUnsaved(String? url, String? original) {
    if (url != null && url != original && _newUploads.remove(url)) StorageService.deleteByUrl(url);
  }

  /// التحقق قبل الحفظ (بترجع رسالة الخطأ أو null)
  String? _validate() {
    if (_titleAr.text.trim().isEmpty && _titleFr.text.trim().isEmpty) return game.t(UiText.titleRequired);
    if (_isExtra) {
      final label = _label.text.trim();
      if (label.isEmpty || label.length > 3 || label.contains(extraSuit)) return game.t(UiText.extraInvalid);
      if (cardRanks.contains(label.toUpperCase())) return game.t(UiText.extraInvalid);
      final others = allModes[widget.modeId]?.extraCards.where((x) => x.label != widget.label).map((x) => x.label) ?? [];
      if (others.contains(label)) return game.t(UiText.extraInvalid);
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) return _snack(problem, error: true);
    setState(() => _saving = true);
    final rule = _buildRule(stamp: true);
    final mode = modeWithCard(
      widget.modeId,
      oldLabel: widget.label,
      label: _isExtra ? _label.text.trim() : widget.label!,
      newRule: rule,
      copies: _copies,
    );
    final error = await ModeStore.save(widget.modeId, mode);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      return _snack(game.t(fillText(UiText.saveFailed, {'error': error})), error: true);
    }
    _saved = true;
    // الصور القديمة اللي اتغيرت مبقتش مستخدمة
    if (_originalIcon != null && _originalIcon != _iconUrl) StorageService.deleteByUrl(_originalIcon);
    if (_originalArtwork != null && _originalArtwork != _artworkUrl) StorageService.deleteByUrl(_originalArtwork);
    game.modesChanged();
    _snack(game.t(AppConfig.hasSupabase ? UiText.saved : UiText.savedLocalOnly));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mode = allModes[widget.modeId]!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // ---------- الشريط اللي فوق ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        SquareButton(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${mode.emoji} ${game.t(mode.name)} • ${game.t(_isNew ? UiText.newCard : UiText.editCard)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pixelStyle(size: 15),
                          ),
                        ),
                        LangToggle(game: game),
                      ],
                    ),
                  ),
                  // ---------- المعاينة اللايف ----------
                  _previewArea(),
                  // ---------- التابات ----------
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
                    child: TabBar(
                      labelStyle: pixelStyle(size: 14),
                      unselectedLabelStyle: pixelStyle(size: 14, weight: FontWeight.w500),
                      labelColor: AppColors.ink,
                      indicator: BoxDecoration(color: AppColors.yellow),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: game.t(UiText.tabContent), height: 40),
                        Tab(text: game.t(UiText.tabDesign), height: 40),
                        Tab(text: game.t(UiText.tabGameplay), height: 40),
                      ],
                    ),
                  ),
                  Expanded(child: TabBarView(children: [_contentTab(), _designTab(), _gameplayTab()])),
                  // ---------- الحفظ ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: _saving
                        ? SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                          )
                        : BrutalButton(label: game.t(UiText.save), onTap: _save, height: 52),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================================================================
  // المعاينة
  // =================================================================
  Widget _previewArea() {
    final rule = _buildRule();
    final description = fillText(rule.description, {'player': game.players.isNotEmpty ? game.players.first.name : 'Sara'});
    Widget card(double w) {
      final h = w * 7 / 5;
      if (_preview == 'back') {
        return CardBackFace(
          width: w,
          height: h,
          deckLeft: 37,
          deckTotal: 52,
          category: rule.category,
          backColor: rule.design.back,
          backPattern: rule.design.backPattern,
          titleOnBack: rule.design.titleOnBack ? game.t(rule.title) : null,
          cardsLeftLabel: game.t(UiText.cardsLeft),
          tapLabel: game.t(UiText.tapToDraw),
          actionLabel: game.t(UiText.actionCard),
        );
      }
      if (_preview == 'clap' && rule.usesClap) {
        final button = ClapButtonView(w: w, style: rule.clapStyle, defaultText: game.t(UiText.clapNow), translate: game.t);
        return CardFrontFace(
          width: w,
          height: h,
          rank: _rank,
          suit: _suit,
          rule: rule,
          body: Column(
            children: [
              Expanded(
                child: Align(alignment: button.alignment, child: button),
              ),
              Text(
                game.t(UiText.lastClapLoses),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }
      return CardFrontFace(
        width: w,
        height: h,
        rank: _rank,
        suit: _suit,
        rule: rule,
        body: RuleBody(
          width: w,
          rank: _rank,
          rule: rule,
          title: game.t(rule.title),
          subtitle: rule.subtitle == null ? null : game.t(rule.subtitle!),
          description: game.t(description),
          hint: game.t(UiText.tapToChoose),
        ),
      );
    }

    // "موبايل": الكارت جوه شكل موبايل بالمقاس الحقيقي تقريباً
    final preview = _preview == 'mobile'
        ? Container(
            width: 170,
            padding: const EdgeInsets.fromLTRB(8, 14, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: card(142),
          )
        : card(150);

    Widget toggle(String id, String label) {
      final selected = _preview == id;
      return GestureDetector(
        onTap: () => setState(() => _preview = id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: Brutal.box(
            color: selected ? AppColors.yellow : AppColors.paper,
            borderWidth: 2,
            shadowOffset: selected ? const Offset(2, 2) : Offset.zero,
          ),
          child: Text(label, style: pixelStyle(size: 13)),
        ),
      );
    }

    return Container(
      height: 240,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.all(8),
      decoration: Brutal.box(color: AppColors.bg, borderWidth: 2, shadowOffset: Offset.zero),
      child: Row(
        children: [
          // عرض ثابت لعمود الأزرار (من غيره الـ Row بيدي العمود عرض لانهائي والمعاينة ماتترسمش)
          SizedBox(
            width: 104,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(game.t(UiText.livePreview), style: pixelStyle(size: 12)),
                const SizedBox(height: 8),
                toggle('front', game.t(UiText.front)),
                toggle('back', game.t(UiText.backFace)),
                toggle('mobile', game.t(UiText.mobile)),
                if (rule.usesClap) toggle('clap', game.t(UiText.previewClap)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(child: RepaintBoundary(child: preview)),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // تاب المحتوى
  // =================================================================
  Widget _contentTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        if (_isExtra) _field(game.t(UiText.extraLabel), _label, maxLength: 3),
        _field(game.t(UiText.emoji), _emoji),
        _field(game.t(UiText.ruleTitleAr), _titleAr),
        _field(game.t(UiText.ruleTitleFr), _titleFr, ltr: true),
        _field(game.t(UiText.subtitleAr), _subAr),
        _field(game.t(UiText.subtitleFr), _subFr, ltr: true),
        Text(game.t(UiText.playerTip), style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        _field(game.t(UiText.ruleDescAr), _descAr, lines: 4),
        _field(game.t(UiText.ruleDescFr), _descFr, lines: 4, ltr: true),
        _field(game.t(UiText.rulePromptAr), _promptAr),
        _field(game.t(UiText.rulePromptFr), _promptFr, ltr: true),
        _field(game.t(UiText.answerAr), _answerAr),
        _field(game.t(UiText.answerFr), _answerFr, ltr: true),
        Text(game.t(UiText.answerHint), style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 10),
        _label2(game.t(UiText.textAlign)),
        _choices<String>(_align, [
          ('center', game.t(UiText.alignCenter)),
          ('start', game.t(UiText.alignStart)),
        ], (v) => _align = v),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _titleOnBack,
          onChanged: (v) => setState(() => _titleOnBack = v),
          title: Text(game.t(UiText.titleOnBack), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(game.t(UiText.titleOnBackHint), style: const TextStyle(fontSize: 12)),
          activeThumbColor: AppColors.ink,
          activeTrackColor: AppColors.yellow,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // =================================================================
  // تاب الشكل
  // =================================================================
  Widget _designTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        _label2(game.t(UiText.barColor)),
        _colors(_bar, (c) => _bar = c),
        _label2(game.t(UiText.bgColor)),
        _colors(_bg, (c) => _bg = c),
        _label2(game.t(UiText.textColor)),
        _colors(_text, (c) => _text = c),
        _label2(game.t(UiText.borderColor)),
        _colors(_border, (c) => _border = c),
        _label2(game.t(UiText.borderStyle)),
        _choices<String>(_borderStyle, [
          ('solid', game.t(UiText.borderSolid)),
          ('thick', game.t(UiText.borderThick)),
          ('dashed', game.t(UiText.borderDashed)),
        ], (v) => _borderStyle = v),
        const SizedBox(height: 14),

        // ---------- الأيقونة ----------
        _label2(game.t(UiText.icon)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in Sticker.values)
              GestureDetector(
                onTap: () => setState(() {
                  _discardUnsaved(_iconUrl, _originalIcon);
                  _iconUrl = null;
                  _sticker = s.name;
                }),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: Brutal.box(
                    color: _iconUrl == null && (_sticker ?? stickerFor(_buildRule(), _rank).name) == s.name
                        ? AppColors.yellow
                        : AppColors.paper,
                    borderWidth: 1.6,
                    shadowOffset: Offset.zero,
                  ),
                  child: StickerImage(s, size: 32),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_iconUrl != null)
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsetsDirectional.only(end: 8),
                decoration: Brutal.box(borderWidth: 1.6, shadowOffset: Offset.zero),
                child: imageFromRef(_iconUrl!, fit: BoxFit.contain),
              ),
            Expanded(child: _uploadButton('icon', UiText.uploadIcon)),
            const SizedBox(width: 6),
            // أيقونة من مكتبة الصور (بيكسل ارت أو صورة مرفوعة قبل كده) من غير رفع تاني
            TextButton(onPressed: () => _fromLibrary('icon'), child: Text(game.t(UiText.fromLibrary), style: const TextStyle(fontWeight: FontWeight.w800))),
            if (_iconUrl != null)
              TextButton(
                onPressed: () => setState(() {
                  _discardUnsaved(_iconUrl, _originalIcon);
                  _iconUrl = null;
                }),
                child: Text(
                  game.t(UiText.removeImage),
                  style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        _label2('${game.t(UiText.iconSize)} (${(_iconScale * 100).round()}%)'),
        Slider(
          value: _iconScale,
          min: 0.5,
          max: 1.5,
          divisions: 10,
          activeColor: AppColors.ink,
          onChanged: (v) => setState(() => _iconScale = v),
        ),
        _label2(game.t(UiText.iconPosition)),
        _choices<String>(_iconPos, [
          ('top', game.t(UiText.iconTop)),
          ('background', game.t(UiText.iconBackground)),
        ], (v) => _iconPos = v),
        const SizedBox(height: 14),

        // ---------- صورة الخلفية ----------
        _label2(game.t(UiText.artwork)),
        Row(
          children: [
            if (_artworkUrl != null)
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsetsDirectional.only(end: 8),
                clipBehavior: Clip.antiAlias,
                decoration: Brutal.box(borderWidth: 1.6, shadowOffset: Offset.zero),
                child: imageFromRef(_artworkUrl!),
              ),
            Expanded(child: _uploadButton('artwork', UiText.uploadArtwork)),
            const SizedBox(width: 6),
            TextButton(onPressed: () => _fromLibrary('artwork'), child: Text(game.t(UiText.fromLibrary), style: const TextStyle(fontWeight: FontWeight.w800))),
            if (_artworkUrl != null)
              TextButton(
                onPressed: () => setState(() {
                  _discardUnsaved(_artworkUrl, _originalArtwork);
                  _artworkUrl = null;
                }),
                child: Text(
                  game.t(UiText.removeImage),
                  style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        if (_artworkUrl != null) ...[
          _label2('${game.t(UiText.artworkOpacity)} (${(_artworkOpacity * 100).round()}%)'),
          Slider(
            value: _artworkOpacity,
            min: 0.05,
            max: 1,
            divisions: 19,
            activeColor: AppColors.ink,
            onChanged: (v) => setState(() => _artworkOpacity = v),
          ),
        ],
        _label2(game.t(UiText.pattern)),
        _choices<String>(_pattern, [
          ('none', game.t(UiText.patternNone)),
          ('dots', game.t(UiText.patternDots)),
          ('grid', game.t(UiText.patternGrid)),
          ('stripes', game.t(UiText.patternStripes)),
        ], (v) => _pattern = v),
        const SizedBox(height: 14),

        // ---------- الضهر ----------
        _label2(game.t(UiText.backColor)),
        _colors(_back, (c) => _back = c),
        _label2(game.t(UiText.backPattern)),
        _choices<String>(_backPattern, [
          ('auto', game.t(UiText.patternAuto)),
          ('dots', game.t(UiText.patternDots)),
          ('grid', game.t(UiText.patternGrid)),
          ('stripes', game.t(UiText.patternStripes)),
        ], (v) => _backPattern = v),
      ],
    );
  }

  // =================================================================
  // تاب اللعب
  // =================================================================
  Widget _gameplayTab() {
    final mode = allModes[widget.modeId]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Text('${game.t(UiText.inMode)}: ${mode.emoji} ${game.t(mode.name)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SwitchListTile(
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
          title: Text(game.t(UiText.enabledLabel), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(game.t(UiText.enabledHint), style: const TextStyle(fontSize: 12)),
          activeThumbColor: AppColors.ink,
          activeTrackColor: AppColors.green,
          contentPadding: EdgeInsets.zero,
        ),
        _label2(game.t(UiText.ruleType)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: Brutal.box(borderWidth: 2, shadowOffset: Offset.zero),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RuleType>(
              value: _type,
              isExpanded: true,
              dropdownColor: AppColors.paper,
              items: [
                for (final type in RuleType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabel(type), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${game.t(UiText.category)}: ${categoryLabel(game, _buildRule().category)}',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        CheckboxListTile(
          value: _silence,
          onChanged: (v) => setState(() => _silence = v ?? false),
          title: Text(game.t(UiText.silence), style: const TextStyle(fontWeight: FontWeight.w700)),
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.ink,
          checkColor: AppColors.yellow,
        ),
        SwitchListTile(
          value: _timed,
          onChanged: (v) => setState(() => _timed = v),
          title: Text('⏱ ${game.t(UiText.timedCard)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(game.t(UiText.timedCardHint), style: const TextStyle(fontSize: 12)),
          activeThumbColor: AppColors.ink,
          activeTrackColor: AppColors.yellow,
          contentPadding: EdgeInsets.zero,
        ),
        if (_timed) ...[
          _label2(game.t(UiText.cardTimer)),
          _choices<int?>(_timerSeconds, [
            (null, game.t(UiText.useGameSetting)),
            for (final s in const [10, 20, 30, 45, 60]) (s, '$s ${game.t(UiText.sec)}'),
          ], (v) => _timerSeconds = v),
        ],
        const SizedBox(height: 6),
        _clapSection(),
        if (_isExtra) ...[
          const SizedBox(height: 14),
          _label2('${game.t(UiText.copies)} (${game.t(UiText.copiesHint)})'),
          _choices<int>(_copies, [for (var n = 1; n <= 8; n++) (n, '× $n')], (v) => _copies = v),
        ],
      ],
    );
  }

  /// زرار التصفيق: تشغيله + شكله (الأدمن يختار أي كارت يبقى عليه الزرار)
  Widget _clapSection() {
    final allowed = CardRule.clapAllowedFor(_type);
    final on = _clapOn && allowed;
    void update(ClapButtonStyle style) => setState(() => _clapStyle = style);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: Brutal.box(color: on ? AppColors.paper : AppColors.bg, borderWidth: 2, shadowOffset: Offset.zero),
      // Material شفاف: عشان مفاتيح التشغيل ترسم ضغطتها فوق لون الصندوق
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: on,
              onChanged: allowed
                  ? (v) => setState(() {
                      _clapOn = v;
                      if (v) _preview = 'clap'; // نوري الزرار في المعاينة على طول
                    })
                  : null,
              title: Text(game.t(UiText.clapButton), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                game.t(allowed ? UiText.clapButtonHint : UiText.clapNotAllowed),
                style: const TextStyle(fontSize: 12),
              ),
              activeThumbColor: AppColors.ink,
              activeTrackColor: AppColors.yellow,
              contentPadding: EdgeInsets.zero,
            ),
            if (on) ...[
              const SizedBox(height: 6),
              Text(game.t(UiText.clapDesign), style: pixelStyle(size: 14)),
              const SizedBox(height: 8),
              _field(game.t(UiText.clapTextAr), _clapTextAr),
              _field(game.t(UiText.clapTextFr), _clapTextFr, ltr: true),
              _field(game.t(UiText.clapIcon), _clapIcon, maxLength: 4),
              _label2(game.t(UiText.clapBg)),
              _colors(
                _clapStyle.bg,
                (c) => _clapStyle = c == null ? _clapStyle.copyWith(clearBg: true) : _clapStyle.copyWith(bg: c),
              ),
              _label2(game.t(UiText.clapFg)),
              _colors(
                _clapStyle.fg,
                (c) => _clapStyle = c == null ? _clapStyle.copyWith(clearFg: true) : _clapStyle.copyWith(fg: c),
              ),
              _label2(game.t(UiText.clapSize)),
              _choices<String>(_clapStyle.size, [
                ('s', game.t(UiText.sizeS)),
                ('m', game.t(UiText.sizeM)),
                ('l', game.t(UiText.sizeL)),
              ], (v) => _clapStyle = _clapStyle.copyWith(size: v)),
              const SizedBox(height: 8),
              _label2(game.t(UiText.clapShape)),
              _choices<String>(_clapStyle.shape, [
                ('circle', game.t(UiText.shapeCircle)),
                ('rounded', game.t(UiText.shapeRounded)),
                ('pill', game.t(UiText.shapePill)),
                ('square', game.t(UiText.shapeSquare)),
              ], (v) => _clapStyle = _clapStyle.copyWith(shape: v)),
              if (_clapStyle.shape == 'rounded') ...[
                _label2('${game.t(UiText.clapRadius)} (${_clapStyle.radius.round()})'),
                Slider(
                  value: _clapStyle.radius,
                  min: 0,
                  max: 40,
                  divisions: 20,
                  activeColor: AppColors.ink,
                  onChanged: (v) => update(_clapStyle.copyWith(radius: v)),
                ),
              ],
              const SizedBox(height: 8),
              _label2(game.t(UiText.clapPosition)),
              _choices<String>(_clapStyle.position, [
                ('top', game.t(UiText.posTop)),
                ('center', game.t(UiText.posCenter)),
                ('bottom', game.t(UiText.posBottom)),
              ], (v) => _clapStyle = _clapStyle.copyWith(position: v)),
              SwitchListTile(
                value: _clapStyle.border,
                onChanged: (v) => update(_clapStyle.copyWith(border: v)),
                title: Text(game.t(UiText.clapBorder), style: const TextStyle(fontWeight: FontWeight.w800)),
                activeThumbColor: AppColors.ink,
                activeTrackColor: AppColors.yellow,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _clapStyle.animate,
                onChanged: (v) => update(_clapStyle.copyWith(animate: v)),
                title: Text(game.t(UiText.clapAnimate), style: const TextStyle(fontWeight: FontWeight.w800)),
                activeThumbColor: AppColors.ink,
                activeTrackColor: AppColors.yellow,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(RuleType type) => game.t(switch (type) {
    RuleType.assign => UiText.typeAssign,
    RuleType.free => UiText.typeFree,
    RuleType.self => UiText.typeSelf,
    RuleType.cadu => UiText.typeCadu,
    RuleType.bomb => UiText.typeBomb,
    RuleType.clap => UiText.typeClap,
    RuleType.silence => UiText.typeSilence,
  });

  // =================================================================
  // عناصر مساعدة
  // =================================================================
  static const _palette = <int>[
    0xFF3B2A2E,
    0xFFFCEBD5,
    0xFFFFFFFF,
    0xFFDCE6FA,
    0xFFF2C94C,
    0xFF5DB3A4,
    0xFFF08A3C,
    0xFFE8585A,
    0xFFF29BBE,
    0xFF6E8EF0,
    0xFF6CC468,
    0xFFA98BF0,
    0xFFE0A458,
    0xFFFF7F6B,
    0xFF4FC1C9,
    0xFF8C7B8F,
  ];

  /// صف ألوان (أول مربع = الافتراضي)
  Widget _colors(int? value, void Function(int?) onPick) {
    Widget swatch(int? color) {
      final selected = value == color;
      return GestureDetector(
        onTap: () => setState(() => onPick(color)),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color == null ? AppColors.paper : Color(color),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.ink, width: selected ? 3.5 : 1.6),
          ),
          child: color == null ? Icon(Icons.auto_awesome, size: 16, color: AppColors.ink) : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 6, runSpacing: 6, children: [swatch(null), for (final c in _palette) swatch(c)]),
    );
  }

  /// اختيارات (زراير)
  Widget _choices<T>(T value, List<(T, String)> options, void Function(T) onPick) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (v, label) in options)
          GestureDetector(
            onTap: () => setState(() => onPick(v)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: Brutal.box(
                color: value == v ? AppColors.yellow : AppColors.paper,
                borderWidth: 2,
                shadowOffset: value == v ? const Offset(2, 2) : Offset.zero,
              ),
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  Widget _uploadButton(String kind, LText label) {
    if (_uploading == kind) {
      return Row(
        children: [
          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.ink)),
          const SizedBox(width: 8),
          Text(game.t(UiText.uploading), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }
    return BrutalButton(
      label: game.t(label),
      onTap: _uploading == null ? () => _upload(kind) : () {},
      showArrow: false,
      height: 40,
      fontSize: 13,
      color: AppColors.paper,
    );
  }

  Widget _label2(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
  );

  Widget _field(String label, TextEditingController controller, {int lines = 1, bool ltr = false, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: lines,
            minLines: 1,
            maxLength: maxLength,
            textDirection: ltr ? TextDirection.ltr : null,
            onChanged: (_) => setState(() {}), // المعاينة بتتحدث مع كل حرف
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.paper,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Brutal.radius),
                borderSide: BorderSide(color: AppColors.ink, width: 1.6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Brutal.radius),
                borderSide: BorderSide(color: AppColors.ink, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
