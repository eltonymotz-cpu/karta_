// =================================================================
// لوحة الأدمن (مخفية): إضافة وتعديل ومسح أنماط اللعب
// -----------------------------------------------------------------
// كل نمط جديد = اسم ووصف + قاعدة لكل كارت من الـ 13 (A, K, Q, J, 10 ... 2)
// الأنماط بتتحفظ في Supabase (وعلى الجهاز) وبتظهر في شاشة الإعداد على طول.
// =================================================================
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/admin_auth.dart';
import '../services/mode_store.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';
import 'card_library_screen.dart';

// =================================================================
// قائمة الأنماط
// =================================================================
class AdminScreen extends StatefulWidget {
  final GameController game;
  const AdminScreen({super.key, required this.game});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  GameController get game => widget.game;

  /// فتح محرر النمط (جديد لو id = null)
  Future<void> _openEditor(String? id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModeEditorScreen(game: game, modeId: id)),
    );
    if (mounted) setState(() {}); // نحدّث القائمة بعد الرجوع
  }

  /// مسح نمط جديد، أو ترجيع نمط أساسي لأصله (بمسح تعديل الأدمن عليه)
  Future<void> _delete(String id) async {
    final resetting = isBuiltIn(id);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BrutalBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline(game.t(resetting ? UiText.resetConfirm : UiText.deleteConfirm), size: 22),
              const SizedBox(height: 18),
              BrutalButton(
                label: game.t(resetting ? UiText.reset : UiText.delete),
                color: AppColors.red,
                onTap: () => Navigator.pop(context, true),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(game.t(UiText.no), style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    final mode = allModes[id];
    final error = await ModeStore.delete(id);
    if (!mounted) return;
    if (error != null) {
      // الحذف فشل: مفيش حاجة اتغيرت، ونعرض السبب
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: AppColors.red),
      );
      return;
    }
    // صورة النمط اللي اتمسح مبقتش مستخدمة
    if (!resetting) StorageService.deleteByUrl(mode?.image);
    game.modesChanged();
    setState(() {});
  }

  Future<void> _logout() async {
    await AdminAuth.signOut();
    game.closeAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                children: [
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      SquareButton(onTap: game.closeAdmin, child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                      const SizedBox(width: 8),
                      LangToggle(game: game),
                      const Spacer(),
                      const ShapeAccent(size: 12),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Headline(game.t(UiText.adminTitle), size: 40),
                  const SizedBox(height: 6),
                  Text(game.t(UiText.adminSubtitle), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (!AppConfig.hasSupabase) ...[
                    const SizedBox(height: 10),
                    Text(game.t(UiText.savedLocalOnly),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
                  ],
                  // الحساب اللي داخل بيه + خروج
                  if (AdminAuth.isLoggedIn) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(game.t(fillText(UiText.loggedInAs, {'email': AdminAuth.email!})),
                              style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ),
                        TextButton.icon(
                          onPressed: _logout,
                          icon: Icon(Icons.logout, size: 18, color: AppColors.red),
                          label: Text(game.t(UiText.logout), style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // مكتبة الكروت: كل الكروت في كل الأنماط (تعديل الشكل والمحتوى والإعدادات)
                  BrutalButton(
                    label: '🃏 ${game.t(UiText.cardLibrary)}',
                    color: AppColors.teal,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardLibraryScreen(game: game)));
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  BrutalButton(label: '+ ${game.t(UiText.newMode)}', onTap: () => _openEditor(null)),
                  const SizedBox(height: 24),
                  // الأنماط اللي الأدمن ضافها
                  if (!customModes.keys.any((id) => !isBuiltIn(id)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(game.t(UiText.noCustomModes), style: TextStyle(color: AppColors.muted)),
                    ),
                  for (final entry in customModes.entries)
                    if (!isBuiltIn(entry.key)) _modeRow(entry.key, entry.value),
                  // الأنماط الأساسية (بتتعدل، ولو اتعدلت ينفع ترجعها لأصلها)
                  for (final id in builtInModes.keys) _modeRow(id, allModes[id]!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeRow(String id, GameMode mode) {
    final builtIn = isBuiltIn(id);
    final edited = isEdited(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
      child: Row(
        children: [
          ModeIcon(mode: mode, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.t(mode.name).toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text(game.t(mode.description), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                // علامة "أساسي" أو "أساسي • معدّل"
                if (builtIn)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    color: edited ? AppColors.red : AppColors.ink,
                    child: Text(
                      edited ? '${game.t(UiText.builtIn)} • ${game.t(UiText.edited)}' : game.t(UiText.builtIn),
                      style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: () => _openEditor(id), icon: Icon(Icons.edit, color: AppColors.ink)),
          // نمط جديد: مسح / نمط أساسي معدّل: رجوع للأصل / نمط أساسي زي ما هو: مفيش
          if (!builtIn)
            IconButton(onPressed: () => _delete(id), icon: Icon(Icons.delete_outline, color: AppColors.red))
          else if (edited)
            IconButton(
              tooltip: game.t(UiText.reset),
              onPressed: () => _delete(id),
              icon: Icon(Icons.restore, color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

// =================================================================
// محرر النمط: البيانات + الـ 13 كارت
// =================================================================
class ModeEditorScreen extends StatefulWidget {
  final GameController game;
  final String? modeId; // null = نمط جديد
  const ModeEditorScreen({super.key, required this.game, this.modeId});

  @override
  State<ModeEditorScreen> createState() => _ModeEditorScreenState();
}

/// مسودة قاعدة كارت واحد (خانات الكتابة بتاعته)
class _RuleDraft {
  final emoji = TextEditingController();
  final titleAr = TextEditingController();
  final titleFr = TextEditingController();
  final descAr = TextEditingController();
  final descFr = TextEditingController();
  final promptAr = TextEditingController();
  final promptFr = TextEditingController();
  RuleType type = RuleType.assign;
  bool silence = false;
  CardRule? original; // القاعدة الأصلية (عشان التصميم والإعدادات اللي مش في المحرر ده تفضل زي ما هي)

  /// نملا الخانات من قاعدة موجودة
  void fill(CardRule rule) {
    original = rule;
    emoji.text = rule.emoji;
    titleAr.text = rule.title.ar;
    titleFr.text = rule.title.fr;
    descAr.text = rule.description.ar;
    descFr.text = rule.description.fr;
    promptAr.text = rule.prompt?.ar ?? '';
    promptFr.text = rule.prompt?.fr ?? '';
    type = rule.type;
    silence = rule.setsSilence;
  }

  /// نحوّل الخانات لقاعدة (التصميم وباقي الإعدادات بتتنقل من القاعدة الأصلية زي ما هي)
  CardRule build() {
    final hasPrompt = promptAr.text.trim().isNotEmpty || promptFr.text.trim().isNotEmpty;
    final base = original ??
        CardRule(emoji: '🃏', title: const LText('', ''), description: const LText('', ''), type: type);
    return base.copyWith(
      emoji: emoji.text.trim().isEmpty ? '🃏' : emoji.text.trim(),
      title: LText(titleAr.text.trim(), titleFr.text.trim()),
      description: LText(descAr.text.trim(), descFr.text.trim()),
      type: type,
      prompt: hasPrompt ? LText(promptAr.text.trim(), promptFr.text.trim()) : null,
      clearPrompt: !hasPrompt,
      setsSilence: silence,
    );
  }

  bool get hasTitle => titleAr.text.trim().isNotEmpty || titleFr.text.trim().isNotEmpty;

  void dispose() {
    for (final c in [emoji, titleAr, titleFr, descAr, descFr, promptAr, promptFr]) {
      c.dispose();
    }
  }
}

/// مسودة كارت زيادة: اسمه وعدد نسخه وقاعدته
class _ExtraDraft {
  final label = TextEditingController();
  int copies = 2;
  final rule = _RuleDraft();

  _ExtraDraft();

  factory _ExtraDraft.from(ExtraCard card) {
    final draft = _ExtraDraft()
      ..copies = card.copies
      ..rule.fill(card.rule);
    draft.label.text = card.label;
    return draft;
  }

  ExtraCard build() => ExtraCard(label: label.text.trim(), copies: copies, rule: rule.build());

  void dispose() {
    label.dispose();
    rule.dispose();
  }
}

class _ModeEditorScreenState extends State<ModeEditorScreen> {
  final _emoji = TextEditingController();
  final _nameAr = TextEditingController();
  final _nameFr = TextEditingController();
  final _descAr = TextEditingController();
  final _descFr = TextEditingController();
  final Map<String, _RuleDraft> _drafts = {for (final r in cardRanks) r: _RuleDraft()};
  final List<_ExtraDraft> _extras = [];  // الكروت الزيادة
  String? _image;                        // صورة النمط (رابط في Supabase Storage)
  String? _originalImage;                // الصورة اللي كانت محفوظة قبل التعديل
  final Set<String> _newUploads = {};    // صور اترفعت في الجلسة دي (بتتمسح لو خرجنا من غير حفظ)
  bool _saved = false;
  bool _uploading = false;
  String _copyFrom = 'classic';
  bool _saving = false;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    // النمط اللي بنعدّله (جديد، أو أساسي زي classic، أو اتعدّل قبل كده)
    final existing = widget.modeId == null ? null : allModes[widget.modeId];
    if (existing != null) {
      // تعديل نمط موجود
      _emoji.text = existing.emoji;
      _nameAr.text = existing.name.ar;
      _nameFr.text = existing.name.fr;
      _descAr.text = existing.description.ar;
      _descFr.text = existing.description.fr;
      _image = existing.image;
      _originalImage = existing.image;
      _extras.addAll(existing.extraCards.map(_ExtraDraft.from));
      _fillCardsFrom(widget.modeId!);
    } else {
      // نمط جديد: نبدأ بقواعد الكلاسيك عشان يعدّل عليها بدل ما يكتب من الصفر
      _emoji.text = '🎲';
      _fillCardsFrom('classic');
    }
  }

  /// نملا الـ 13 كارت من نمط موجود
  void _fillCardsFrom(String modeId) {
    for (final rank in cardRanks) {
      _drafts[rank]!.fill(getRule(modeId, rank));
    }
  }

  @override
  void dispose() {
    for (final c in [_emoji, _nameAr, _nameFr, _descAr, _descFr]) {
      c.dispose();
    }
    for (final d in _drafts.values) {
      d.dispose();
    }
    for (final x in _extras) {
      x.dispose();
    }
    // خرجنا من غير حفظ: نمسح الصور اللي اترفعت ومااتستخدمتش
    if (!_saved) {
      for (final url in _newUploads) {
        StorageService.deleteByUrl(url);
      }
    }
    super.dispose();
  }

  /// اختيار صورة للنمط من الجهاز (بنصغّرها عشان تتحفظ بسرعة)
  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final result = await StorageService.pickAndUpload(folder: 'modes', maxSide: 480);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result.error != null) return _snack(result.error!, AppColors.red);
    if (result.url == null) return; // المستخدم لغى
    _replaceImage(result.url!);
  }

  /// تغيير الصورة: القديمة بتتمسح من Storage بعد ما الحفظ ينجح بس
  void _replaceImage(String? url) {
    final old = _image;
    if (old != null && old != _originalImage && _newUploads.contains(old)) {
      StorageService.deleteByUrl(old); // صورة اترفعت دلوقتي واتغيرت قبل الحفظ
      _newUploads.remove(old);
    }
    if (url != null) _newUploads.add(url);
    setState(() => _image = url);
  }

  /// هل الكروت الزيادة سليمة؟ (ليها اسم وعنوان، ومفيش اسم متكرر أو زي كارت من الـ 13)
  bool _extrasValid() {
    final labels = <String>{};
    for (final x in _extras) {
      final label = x.label.text.trim();
      if (label.isEmpty || !x.rule.hasTitle || label.contains(extraSuit)) return false;
      if (cardRanks.contains(label.toUpperCase()) || !labels.add(label)) return false;
    }
    return true;
  }

  Future<void> _save() async {
    final hasName = _nameAr.text.trim().isNotEmpty || _nameFr.text.trim().isNotEmpty;
    if (!hasName || _drafts.values.any((d) => !d.hasTitle)) {
      _snack(game.t(UiText.fillRequired), AppColors.red);
      return;
    }
    if (!_extrasValid()) {
      _snack(game.t(UiText.extraInvalid), AppColors.red);
      return;
    }
    // لو كتب لغة واحدة بس، نستخدمها للغتين
    String pick(String a, String b) => a.trim().isNotEmpty ? a.trim() : b.trim();
    final mode = GameMode(
      emoji: _emoji.text.trim().isEmpty ? '🎲' : _emoji.text.trim(),
      name: LText(pick(_nameAr.text, _nameFr.text), pick(_nameFr.text, _nameAr.text)),
      description: LText(_descAr.text.trim(), _descFr.text.trim()),
      basedOn: 'classic',
      rules: {for (final rank in cardRanks) rank: _drafts[rank]!.build()},
      extraCards: [for (final x in _extras) x.build()],
      image: _image,
    );
    final id = widget.modeId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _saving = true);
    final error = await ModeStore.save(id, mode);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _snack(game.t(fillText(UiText.saveFailed, {'error': error})), AppColors.red);
    } else {
      _saved = true;
      // الصورة القديمة مبقتش مستخدمة: نمسحها من Storage
      if (_originalImage != null && _originalImage != _image) StorageService.deleteByUrl(_originalImage);
      game.modesChanged();
      _snack(game.t(AppConfig.hasSupabase ? UiText.saved : UiText.savedLocalOnly), const Color(0xFF3DBE5B));
      Navigator.of(context).pop();
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    SquareButton(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                    const Spacer(),
                    const ShapeAccent(size: 12),
                  ],
                ),
                const SizedBox(height: 16),
                Headline(game.t(widget.modeId == null ? UiText.newMode : UiText.editMode), size: 34),
                const SizedBox(height: 20),

                // ---------- بيانات النمط ----------
                _section(game.t(UiText.modeInfo)),
                BrutalBox(
                  child: Column(
                    children: [
                      _field(game.t(UiText.emoji), _emoji),
                      _field(game.t(UiText.modeNameAr), _nameAr),
                      _field(game.t(UiText.modeNameFr), _nameFr, ltr: true),
                      _field(game.t(UiText.modeDescAr), _descAr, lines: 2),
                      _field(game.t(UiText.modeDescFr), _descFr, lines: 2, ltr: true),
                      // صورة النمط
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(game.t(UiText.modeImage).toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            clipBehavior: Clip.antiAlias,
                            decoration: Brutal.box(color: AppColors.bg, borderWidth: 2, shadowOffset: Offset.zero),
                            child: _image == null
                                ? const Center(child: StickerImage(Sticker.magnifier, size: 34))
                                : imageFromRef(_image!),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _uploading
                                    ? Center(child: CircularProgressIndicator(color: AppColors.ink))
                                    : BrutalButton(
                                        label: game.t(UiText.pickImage),
                                        onTap: _pickImage,
                                        showArrow: false,
                                        height: 40,
                                        fontSize: 14,
                                      ),
                                if (_image != null && !_uploading)
                                  TextButton(
                                    onPressed: () => _replaceImage(null),
                                    child: Text(game.t(UiText.removeImage),
                                        style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---------- الـ 13 كارت ----------
                _section(game.t(UiText.theCards)),
                // نسخ القواعد من نمط موجود
                Row(
                  children: [
                    Text('${game.t(UiText.copyFrom)}: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _copyFrom,
                        isExpanded: true,
                        dropdownColor: AppColors.paper,
                        items: [
                          for (final e in allModes.entries)
                            DropdownMenuItem(value: e.key, child: Text('${e.value.emoji} ${game.t(e.value.name)}')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _copyFrom = value;
                            _fillCardsFrom(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text(game.t(UiText.playerTip), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                for (final rank in cardRanks) _rankEditor(rank),
                const SizedBox(height: 24),

                // ---------- كروت زيادة ----------
                _section('${game.t(UiText.extraCards)} (${_extras.length})'),
                Text(game.t(UiText.extraCardsHint), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                for (var i = 0; i < _extras.length; i++) _extraEditor(i),
                BrutalButton(
                  label: '+ ${game.t(UiText.addExtra)}',
                  color: AppColors.paper,
                  showArrow: false,
                  height: 48,
                  fontSize: 15,
                  onTap: () => setState(() {
                    final draft = _ExtraDraft();
                    draft.label.text = 'X${_extras.length + 1}';
                    draft.rule.fill(getRule('classic', 'A')); // بداية جاهزة يعدّل عليها
                    _extras.add(draft);
                  }),
                ),
                const SizedBox(height: 24),
                _saving
                    ? Center(child: CircularProgressIndicator(color: AppColors.ink))
                    : BrutalButton(label: game.t(UiText.save), onTap: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: AppColors.yellow, margin: const EdgeInsetsDirectional.only(end: 8)),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  /// محرر كارت من الـ 13
  Widget _rankEditor(String rank) =>
      _ruleEditor(label: rank, d: _drafts[rank]!, key: ValueKey('$rank-$_copyFrom'));

  /// محرر كارت زيادة: اسمه + عدد نسخه + قاعدته + زرار مسح
  Widget _extraEditor(int index) {
    final x = _extras[index];
    return _ruleEditor(
      label: x.label.text.isEmpty ? '?' : x.label.text,
      d: x.rule,
      key: ObjectKey(x),
      color: styleFor(x.label.text).color,
      topFields: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _field(game.t(UiText.extraLabel), x.label, onChanged: () => setState(() {}), maxLength: 3)),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.t(UiText.copies).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  DropdownButton<int>(
                    value: x.copies,
                    dropdownColor: AppColors.paper,
                    items: [for (var n = 1; n <= 8; n++) DropdownMenuItem(value: n, child: Text('× $n'))],
                    onChanged: (n) => setState(() => x.copies = n ?? x.copies),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      onDelete: () => setState(() => _extras.removeAt(index).dispose()),
    );
  }

  /// محرر قاعدة كارت (بيفتح ويقفل)
  Widget _ruleEditor({
    required String label,
    required _RuleDraft d,
    required Key key,
    Color? color,
    List<Widget> topFields = const [],
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias, // مربع الرقم يمشي مع الزوايا المدوّرة
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
      child: Theme(
        // نشيل الخطوط اللي ExpansionTile بيحطها فوق وتحت
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: key, // عشان يتحدث لما ننسخ من نمط تاني
          tilePadding: const EdgeInsetsDirectional.only(start: 0, end: 12),
          leading: Container(
            width: 52,
            height: 56,
            alignment: Alignment.center,
            color: color ?? styleFor(label).color,
            child: Text(label, textDirection: TextDirection.ltr, style: rankStyle(size: 20)),
          ),
          title: Text(
            '${d.emoji.text}  ${game.lang == AppLang.ar ? d.titleAr.text : d.titleFr.text}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(_typeLabel(d.type), style: TextStyle(fontSize: 12, color: AppColors.muted)),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          children: [
            ...topFields,
            _field(game.t(UiText.emoji), d.emoji, onChanged: () => setState(() {})),
            _field(game.t(UiText.ruleTitleAr), d.titleAr, onChanged: () => setState(() {})),
            _field(game.t(UiText.ruleTitleFr), d.titleFr, ltr: true, onChanged: () => setState(() {})),
            _field(game.t(UiText.ruleDescAr), d.descAr, lines: 3),
            _field(game.t(UiText.ruleDescFr), d.descFr, lines: 3, ltr: true),
            // نوع الكارت
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(game.t(UiText.ruleType).toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            DropdownButton<RuleType>(
              value: d.type,
              isExpanded: true,
              dropdownColor: AppColors.paper,
              items: [
                for (final type in RuleType.values) DropdownMenuItem(value: type, child: Text(_typeLabel(type))),
              ],
              onChanged: (value) => setState(() => d.type = value ?? d.type),
            ),
            // سؤال الاختيار (للأنواع اللي فيها اختيار خسران)
            if (d.type == RuleType.assign || d.type == RuleType.free || d.type == RuleType.bomb || d.type == RuleType.clap) ...[
              _field(game.t(UiText.rulePromptAr), d.promptAr),
              _field(game.t(UiText.rulePromptFr), d.promptFr, ltr: true),
            ],
            CheckboxListTile(
              value: d.silence,
              onChanged: (value) => setState(() => d.silence = value ?? false),
              title: Text(game.t(UiText.silence), style: const TextStyle(fontWeight: FontWeight.w700)),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.ink,
              checkColor: AppColors.yellow,
            ),
            if (onDelete != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: AppColors.red),
                  label: Text(game.t(UiText.delete), style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
                ),
              ),
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

  /// خانة كتابة بعنوان صغير فوقها
  Widget _field(String label, TextEditingController controller,
      {int lines = 1, bool ltr = false, bool last = false, VoidCallback? onChanged, int? maxLength}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: lines,
            minLines: 1,
            maxLength: maxLength,
            textDirection: ltr ? TextDirection.ltr : null,
            onChanged: onChanged == null ? null : (_) => onChanged(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Brutal.radius),
                borderSide: BorderSide(color: AppColors.ink, width: 1.5),
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
