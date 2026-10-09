// =================================================================
// مكتبة الكروت (لوحة الأدمن): كل كارت في كل نمط في مكان واحد
// -----------------------------------------------------------------
// - بحث + فلترة بالنمط والنوع والحالة
// - تعديل (شكل ومحتوى وإعدادات) / نسخ / تفعيل وقفل / مسح (الكروت الزيادة بس)
// - كارت جديد
// كل تغيير بيتحفظ في Supabase (جدول karta_modes) وبيوصل للعبة على طول.
// الكروت الـ 13 الأساسية (A..2) مينفعش تتمسح عشان القواعد الأساسية، بس ينفع تتقفل.
// =================================================================
import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/mode_store.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';
import 'card_editor_screen.dart';

class CardLibraryScreen extends StatefulWidget {
  final GameController game;
  const CardLibraryScreen({super.key, required this.game});

  @override
  State<CardLibraryScreen> createState() => _CardLibraryScreenState();
}

class _CardLibraryScreenState extends State<CardLibraryScreen> {
  final _search = TextEditingController();
  String _modeFilter = 'all';
  String _typeFilter = 'all';    // all / normal / action / queen / bomb
  String _statusFilter = 'all';  // all / on / off
  bool _busy = false;            // بيمنع عمليتين في نفس الوقت

  GameController get game => widget.game;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// الكروت بعد الفلترة
  List<CardEntry> get _cards {
    final query = _search.text.trim().toLowerCase();
    final result = <CardEntry>[];
    for (final modeId in allModes.keys) {
      if (_modeFilter != 'all' && _modeFilter != modeId) continue;
      for (final card in cardsOf(modeId)) {
        final rule = card.rule;
        if (_typeFilter != 'all' && rule.category.name != _typeFilter) continue;
        if (_statusFilter == 'on' && !rule.enabled) continue;
        if (_statusFilter == 'off' && rule.enabled) continue;
        if (query.isNotEmpty) {
          final haystack = '${card.rank} ${rule.title.ar} ${rule.title.fr} ${rule.description.ar} ${rule.description.fr}'.toLowerCase();
          if (!haystack.contains(query)) continue;
        }
        result.add(card);
      }
    }
    return result;
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  /// حفظ نمط بعد تغيير كارت فيه (ومفيش أي تغيير لو الحفظ فشل)
  Future<bool> _saveMode(String modeId, GameMode mode) async {
    setState(() => _busy = true);
    final error = await ModeStore.save(modeId, mode);
    if (!mounted) return false;
    setState(() => _busy = false);
    if (error != null) {
      _snack(game.t(fillText(UiText.saveFailed, {'error': error})), error: true);
      return false;
    }
    game.modesChanged();
    return true;
  }

  /// تفعيل/قفل كارت
  Future<void> _toggle(CardEntry card) async {
    if (_busy) return;
    final rule = card.rule.copyWith(enabled: !card.rule.enabled, updatedAt: DateTime.now().toIso8601String());
    final mode = modeWithCard(card.modeId, oldLabel: card.rank, label: card.rank, newRule: rule, copies: card.copies);
    if (await _saveMode(card.modeId, mode)) {
      _snack(game.t(rule.enabled ? UiText.cardEnabled : UiText.cardDisabled));
    }
  }

  /// مسح كارت زيادة (بعد التأكيد)
  Future<void> _delete(CardEntry card) async {
    if (_busy || !card.isExtra) return;
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
              Headline(game.t(fillText(UiText.deleteCardConfirm, {'card': card.rank})), size: 22),
              const SizedBox(height: 18),
              BrutalButton(label: game.t(UiText.delete), color: AppColors.red, onTap: () => Navigator.pop(context, true)),
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
    final mode = modeWithCard(card.modeId, oldLabel: card.rank, label: card.rank, newRule: null);
    if (await _saveMode(card.modeId, mode)) _snack(game.t(UiText.cardDeleted));
  }

  /// نسخ كارت كارت زيادة جديد (في نفس النمط أو نمط تاني)
  Future<void> _duplicate(CardEntry card) async {
    if (_busy) return;
    final target = await _pickMode(card.modeId);
    if (target == null) return;
    final label = _uniqueLabel(target, card.rank);
    final rule = card.rule.copyWith(enabled: true, updatedAt: DateTime.now().toIso8601String());
    final mode = modeWithCard(target, oldLabel: null, label: label, newRule: rule, copies: card.isExtra ? card.copies : 2);
    if (await _saveMode(target, mode)) _snack(game.t(fillText(UiText.cardDuplicated, {'card': label})));
  }

  /// اسم كارت زيادة مش متكرر (لحد 3 حروف)
  static String _uniqueLabel(String modeId, String base) {
    final taken = {...cardRanks, ...?allModes[modeId]?.extraCards.map((x) => x.label)};
    final stem = base.replaceAll(extraSuit, '');
    for (var i = 1; i < 100; i++) {
      final suffix = '$i';
      final head = stem.length + suffix.length > 3 ? stem.substring(0, (3 - suffix.length).clamp(0, stem.length)) : stem;
      final label = '$head$suffix';
      if (!taken.contains(label)) return label;
    }
    return 'X${DateTime.now().millisecond % 99}';
  }

  /// اختيار نمط
  Future<String?> _pickMode(String initial) {
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: RetroWindow(
          title: game.t(UiText.chooseMode),
          barColor: AppColors.teal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in allModes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: Brutal.box(
                        color: entry.key == initial ? AppColors.yellow : AppColors.paper,
                        borderWidth: 2,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: Row(
                        children: [
                          ModeIcon(mode: entry.value, size: 32),
                          const SizedBox(width: 10),
                          Expanded(child: Text(game.t(entry.value.name), style: const TextStyle(fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor({required String modeId, String? label}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CardEditorScreen(game: game, modeId: modeId, label: label),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _newCard() async {
    final modeId = await _pickMode(_modeFilter == 'all' ? 'classic' : _modeFilter);
    if (modeId != null) await _openEditor(modeId: modeId);
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            SquareButton(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr),
                            ),
                            const SizedBox(width: 8),
                            LangToggle(game: game),
                            const Spacer(),
                            if (_busy) SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Headline(game.t(UiText.cardLibrary), size: 32),
                        Text(game.t(UiText.cardLibraryHint), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        BrutalButton(label: '+ ${game.t(UiText.newCard)}', onTap: _newCard),
                        const SizedBox(height: 14),
                        _filters(),
                        const SizedBox(height: 10),
                        Text(game.t(fillText(UiText.cardsCount, {'n': cards.length})),
                            style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // الكروت (بتترسم وإنت بتنزل بس، عشان الأداء)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList.builder(
                      itemCount: cards.length,
                      itemBuilder: (context, i) => _cardRow(cards[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// خانة البحث والفلاتر
  Widget _filters() {
    Widget dropdown<T>(T value, List<(T, String)> items, ValueChanged<T> onChanged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            dropdownColor: AppColors.paper,
            items: [for (final (v, label) in items) DropdownMenuItem(value: v, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))],
            onChanged: (v) {
              if (v != null) setState(() => onChanged(v));
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search, color: AppColors.ink),
            hintText: game.t(UiText.searchCards),
            filled: true,
            fillColor: AppColors.paper,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Brutal.radius),
              borderSide: BorderSide(color: AppColors.ink, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Brutal.radius),
              borderSide: BorderSide(color: AppColors.ink, width: 2.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            dropdown<String>(_modeFilter, [
              ('all', game.t(UiText.allModes)),
              for (final e in allModes.entries) (e.key, '${e.value.emoji} ${game.t(e.value.name)}'),
            ], (v) => _modeFilter = v),
            dropdown<String>(_typeFilter, [
              ('all', game.t(UiText.allTypes)),
              for (final c in CardCategory.values) (c.name, categoryLabel(game, c)),
            ], (v) => _typeFilter = v),
            dropdown<String>(_statusFilter, [
              ('all', game.t(UiText.allStatus)),
              ('on', game.t(UiText.enabledLabel)),
              ('off', game.t(UiText.disabledLabel)),
            ], (v) => _statusFilter = v),
          ],
        ),
      ],
    );
  }

  /// سطر كارت: معاينة صغيرة + بياناته + الأزرار
  Widget _cardRow(CardEntry card) {
    final rule = card.rule;
    final colors = ResolvedCardColors.of(rule, card.rank);
    final mode = allModes[card.modeId]!;
    final updated = rule.updatedAt == null ? null : DateTime.tryParse(rule.updatedAt!);
    return Opacity(
      opacity: rule.enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
        child: Row(
          children: [
            // معاينة صغيرة للكارت
            GestureDetector(
              onTap: () => _openEditor(modeId: card.modeId, label: card.rank),
              child: Container(
                width: 64,
                height: 86,
                decoration: BoxDecoration(
                  color: colors.bg,
                  border: BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      color: colors.bar,
                      alignment: Alignment.center,
                      child: Text(card.rank, textDirection: TextDirection.ltr, style: rankStyle(size: 12)),
                    ),
                    Expanded(
                      child: Center(
                        child: rule.design.iconUrl != null
                            ? imageFromRef(rule.design.iconUrl!, fit: BoxFit.contain, width: 38, height: 38)
                            : StickerImage(stickerFor(rule, card.rank), size: 38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${rule.emoji} ${game.t(rule.title)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        _tag('${mode.emoji} ${game.t(mode.name)}', AppColors.paper),
                        _tag(categoryLabel(game, rule.category), rule.isAction ? AppColors.orange : AppColors.blue),
                        if (card.isExtra) _tag('${game.t(UiText.extraCards)} ×${card.copies}', AppColors.yellow),
                        if (rule.timed) _tag('⏱', AppColors.yellow),
                      ],
                    ),
                    if (updated != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          game.t(fillText(UiText.updatedAt, {'date': '${updated.year}-${_two(updated.month)}-${_two(updated.day)}'})),
                          style: TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // تفعيل/قفل
            Switch(
              value: rule.enabled,
              activeThumbColor: AppColors.ink,
              activeTrackColor: AppColors.green,
              onChanged: _busy ? null : (_) => _toggle(card),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.ink),
              color: AppColors.paper,
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    _openEditor(modeId: card.modeId, label: card.rank);
                  case 'duplicate':
                    _duplicate(card);
                  case 'delete':
                    _delete(card);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('✏️ ${game.t(UiText.edit)}')),
                PopupMenuItem(value: 'duplicate', child: Text('📄 ${game.t(UiText.duplicate)}')),
                if (card.isExtra) PopupMenuItem(value: 'delete', child: Text('🗑 ${game.t(UiText.delete)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: Brutal.box(color: color, borderWidth: 1.3, shadowOffset: Offset.zero, radius: 3),
      child: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

/// اسم تصنيف الكارت
String categoryLabel(GameController game, CardCategory category) => game.t(switch (category) {
      CardCategory.normal => UiText.catNormal,
      CardCategory.action => UiText.catAction,
      CardCategory.queen => UiText.catQueen,
      CardCategory.bomb => UiText.catBomb,
    });
