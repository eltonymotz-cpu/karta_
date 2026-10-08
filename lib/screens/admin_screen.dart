// =================================================================
// لوحة الأدمن (مخفية): إضافة وتعديل ومسح أنماط اللعب
// -----------------------------------------------------------------
// كل نمط جديد = اسم ووصف + قاعدة لكل كارت من الـ 13 (A, K, Q, J, 10 ... 2)
// الأنماط بتتحفظ في Supabase (وعلى الجهاز) وبتظهر في شاشة الإعداد على طول.
// =================================================================
import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/mode_store.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets/common.dart';

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

  Future<void> _delete(String id) async {
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
              Headline(game.t(UiText.deleteConfirm), size: 22),
              const SizedBox(height: 18),
              BrutalButton(label: game.t(UiText.delete), color: AppColors.red, onTap: () => Navigator.pop(context, true)),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(game.t(UiText.no), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    await ModeStore.delete(id);
    if (game.modeId == id) game.setMode('classic');
    if (mounted) setState(() {});
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
                      const CheckerSquares(size: 12),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Headline(game.t(UiText.adminTitle), size: 40),
                  const SizedBox(height: 6),
                  Text(game.t(UiText.adminSubtitle), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (!AppConfig.hasSupabase) ...[
                    const SizedBox(height: 10),
                    Text(game.t(UiText.savedLocalOnly),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
                  ],
                  const SizedBox(height: 20),
                  BrutalButton(label: '+ ${game.t(UiText.newMode)}', onTap: () => _openEditor(null)),
                  const SizedBox(height: 24),
                  // الأنماط اللي الأدمن ضافها
                  if (customModes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(game.t(UiText.noCustomModes), style: const TextStyle(color: AppColors.muted)),
                    ),
                  for (final entry in customModes.entries) _modeRow(entry.key, entry.value, editable: true),
                  // الأنماط الأساسية (مش بتتعدل)
                  for (final entry in builtInModes.entries) _modeRow(entry.key, entry.value, editable: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeRow(String id, GameMode mode, {required bool editable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: Brutal.box(color: AppColors.yellow, borderWidth: 2, shadowOffset: Offset.zero),
            child: Text(mode.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.t(mode.name).toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text(game.t(mode.description), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (editable) ...[
            IconButton(onPressed: () => _openEditor(id), icon: const Icon(Icons.edit, color: AppColors.ink)),
            IconButton(onPressed: () => _delete(id), icon: const Icon(Icons.delete_outline, color: AppColors.red)),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: AppColors.ink,
              child: Text(game.t(UiText.builtIn),
                  style: const TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w900)),
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

  /// نملا الخانات من قاعدة موجودة
  void fill(CardRule rule) {
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

  /// نحوّل الخانات لقاعدة
  CardRule build() {
    final hasPrompt = promptAr.text.trim().isNotEmpty || promptFr.text.trim().isNotEmpty;
    return CardRule(
      emoji: emoji.text.trim().isEmpty ? '🃏' : emoji.text.trim(),
      title: LText(titleAr.text.trim(), titleFr.text.trim()),
      description: LText(descAr.text.trim(), descFr.text.trim()),
      type: type,
      prompt: hasPrompt ? LText(promptAr.text.trim(), promptFr.text.trim()) : null,
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

class _ModeEditorScreenState extends State<ModeEditorScreen> {
  final _emoji = TextEditingController();
  final _nameAr = TextEditingController();
  final _nameFr = TextEditingController();
  final _descAr = TextEditingController();
  final _descFr = TextEditingController();
  final Map<String, _RuleDraft> _drafts = {for (final r in cardRanks) r: _RuleDraft()};
  String _copyFrom = 'classic';
  bool _saving = false;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    final existing = widget.modeId == null ? null : customModes[widget.modeId];
    if (existing != null) {
      // تعديل نمط موجود
      _emoji.text = existing.emoji;
      _nameAr.text = existing.name.ar;
      _nameFr.text = existing.name.fr;
      _descAr.text = existing.description.ar;
      _descFr.text = existing.description.fr;
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
    super.dispose();
  }

  Future<void> _save() async {
    final hasName = _nameAr.text.trim().isNotEmpty || _nameFr.text.trim().isNotEmpty;
    if (!hasName || _drafts.values.any((d) => !d.hasTitle)) {
      _snack(game.t(UiText.fillRequired), AppColors.red);
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
    );
    final id = widget.modeId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _saving = true);
    final error = await ModeStore.save(id, mode);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _snack(game.t(fillText(UiText.saveFailed, {'error': error})), AppColors.red);
    } else {
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
                    const CheckerSquares(size: 12),
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
                      _field(game.t(UiText.modeDescFr), _descFr, lines: 2, ltr: true, last: true),
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
                Text(game.t(UiText.playerTip), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                for (final rank in cardRanks) _rankEditor(rank),
                const SizedBox(height: 20),
                _saving
                    ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
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

  /// محرر كارت واحد (بيفتح ويقفل)
  Widget _rankEditor(String rank) {
    final d = _drafts[rank]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
      child: Theme(
        // نشيل الخطوط اللي ExpansionTile بيحطها فوق وتحت
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('$rank-$_copyFrom'), // عشان يتحدث لما ننسخ من نمط تاني
          tilePadding: const EdgeInsetsDirectional.only(start: 0, end: 12),
          leading: Container(
            width: 52,
            height: 56,
            alignment: Alignment.center,
            color: AppColors.ink,
            child: Text(rank, style: const TextStyle(color: AppColors.yellow, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          title: Text(
            '${d.emoji.text}  ${game.lang == AppLang.ar ? d.titleAr.text : d.titleFr.text}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(_typeLabel(d.type), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          children: [
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
      });

  /// خانة كتابة بعنوان صغير فوقها
  Widget _field(String label, TextEditingController controller,
      {int lines = 1, bool ltr = false, bool last = false, VoidCallback? onChanged}) {
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
                borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Brutal.radius),
                borderSide: const BorderSide(color: AppColors.ink, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
