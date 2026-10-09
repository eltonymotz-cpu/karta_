// =================================================================
// مكتبة الصور (شاشة واحدة بتتفتح من أي مكان)
// -----------------------------------------------------------------
// - pick = true: بتختار صورة وبترجع مرجعها (للكارت، أيقونة، خلفية، صورة النمط...)
// - pick = false: إدارة المكتبة من لوحة الأدمن (رفع، تعديل الاسم والتصنيف، استبدال، مسح)
// بحث + فلترة بالتصنيف + معاينة. أيقونات البيكسل بتتعرض من غير تنعيم.
// =================================================================
import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/pixel_assets.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/asset_library.dart';
import '../services/mode_store.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';

/// يفتح المكتبة للاختيار ويرجّع مرجع الصورة (أو null لو اتلغى)
Future<String?> pickLibraryAsset(BuildContext context, GameController game) {
  return Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => AssetLibraryScreen(game: game, pick: true)));
}

class AssetLibraryScreen extends StatefulWidget {
  final GameController game;
  final bool pick;
  const AssetLibraryScreen({super.key, required this.game, this.pick = false});

  @override
  State<AssetLibraryScreen> createState() => _AssetLibraryScreenState();
}

class _AssetLibraryScreenState extends State<AssetLibraryScreen> {
  GameController get game => widget.game;
  final _search = TextEditingController();
  AssetCategory? _category;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final error = await AssetLibrary.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  Future<void> _run(Future<String?> Function() action, String success) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return _snack(error, error: true);
    _snack(success);
  }

  /// اسم + تصنيف (للرفع والتعديل)
  Future<(String, AssetCategory, List<String>)?> _askDetails({String name = '', AssetCategory category = AssetCategory.other, List<String> tags = const []}) {
    final nameController = TextEditingController(text: name);
    final tagsController = TextEditingController(text: tags.join(', '));
    var picked = category;
    return showDialog<(String, AssetCategory, List<String>)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppColors.paper,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: nameController, maxLength: 60, decoration: InputDecoration(labelText: game.t(UiText.assetName))),
              TextField(controller: tagsController, decoration: InputDecoration(labelText: game.t(UiText.assetTags))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in AssetCategory.values)
                    ChoiceChip(
                      label: Text(game.t(categoryName(c))),
                      selected: picked == c,
                      onSelected: (_) => setDialog(() => picked = c),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(game.t(UiText.cancel))),
            TextButton(
              onPressed: () => Navigator.pop(context, (
                nameController.text.trim(),
                picked,
                [for (final t in tagsController.text.split(',')) if (t.trim().isNotEmpty) t.trim()],
              )),
              child: Text(game.t(UiText.save)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    final details = await _askDetails();
    if (details == null) return;
    await _run(() => AssetLibrary.upload(name: details.$1, category: details.$2, tags: details.$3), game.t(UiText.uploaded));
  }

  /// بعد استبدال صورة: نحدّث رابطها في كل الكروت والأنماط اللي بتستخدمها
  Future<String?> _replaceUsages(String oldRef, String newRef) async {
    for (final entry in allModes.entries.toList()) {
      var mode = entry.value;
      var changed = false;
      if (mode.image == oldRef) {
        mode = GameMode(
          emoji: mode.emoji,
          name: mode.name,
          description: mode.description,
          basedOn: mode.basedOn,
          rules: mode.rules,
          extraCards: mode.extraCards,
          image: newRef,
        );
        changed = true;
      }
      if (changed) customModes[entry.key] = mode;
      for (final card in cardsOf(entry.key)) {
        final d = card.rule.design;
        if (d.iconUrl != oldRef && d.artworkUrl != oldRef) continue;
        final json = d.toJson();
        if (d.iconUrl == oldRef) json['iconUrl'] = newRef;
        if (d.artworkUrl == oldRef) json['artworkUrl'] = newRef;
        mode = modeWithCard(entry.key, oldLabel: card.rank, label: card.rank, newRule: card.rule.copyWith(design: CardDesign.fromJson(json)), copies: card.copies);
        customModes[entry.key] = mode;
        changed = true;
      }
      if (changed) {
        final error = await ModeStore.save(entry.key, mode);
        if (error != null) return error;
      }
    }
    game.modesChanged();
    return null;
  }

  Future<void> _manage(LibraryAsset asset) async {
    final used = AssetLibrary.usages(asset.ref);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 140, child: imageFromRef(asset.ref, fit: BoxFit.contain)),
              const SizedBox(height: 8),
              Text(game.t(asset.name), textAlign: TextAlign.center, style: pixelStyle(size: 16)),
              Text(
                '${game.t(categoryName(asset.category))} • ${asset.builtIn ? game.t(UiText.builtInAsset) : game.t(UiText.uploadedAsset)}'
                '${used.isEmpty ? '' : '\n${game.t(UiText.usedIn)}: ${used.take(4).join('، ')}'}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (!asset.builtIn) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.pop(context, 'edit'), child: Text(game.t(UiText.editDetails))),
                TextButton(onPressed: () => Navigator.pop(context, 'replace'), child: Text(game.t(UiText.replaceImage))),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'delete'),
                  child: Text(game.t(UiText.deleteLabel), style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'edit':
        final details = await _askDetails(name: asset.name.ar, category: asset.category, tags: asset.tags);
        if (details != null) {
          await _run(() => AssetLibrary.update(asset, name: details.$1, category: details.$2, tags: details.$3), game.t(UiText.saved));
        }
      case 'replace':
        await _run(() => AssetLibrary.replace(asset, _replaceUsages), game.t(UiText.saved));
      case 'delete':
        await _run(() => AssetLibrary.delete(asset), game.t(UiText.deleted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = AssetLibrary.all.where((a) => (_category == null || a.category == _category) && a.matches(_search.text)).toList();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        SquareButton(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('🖼 ${game.t(UiText.assetLibrary)}', style: pixelStyle(size: 16), overflow: TextOverflow.ellipsis)),
                        if (_busy) Padding(padding: const EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.ink))),
                        SquareButton(color: AppColors.yellow, onTap: _busy ? null : _upload, child: Text('+ ${game.t(UiText.upload)}')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: game.t(UiText.search),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.paper,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Brutal.radius), borderSide: BorderSide(color: AppColors.ink, width: 1.6)),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      children: [
                        _chip(null, game.t(UiText.all)),
                        for (final c in AssetCategory.values) _chip(c, game.t(categoryName(c))),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('⚠ $_error', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w700)),
                    ),
                  Expanded(
                    child: _loading
                        ? Center(child: CircularProgressIndicator(color: AppColors.ink))
                        : assets.isEmpty
                            ? Center(child: Text(game.t(UiText.noResults), style: TextStyle(color: AppColors.muted)))
                            : GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 130, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
                                itemCount: assets.length,
                                itemBuilder: (context, i) => _tile(assets[i]),
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

  Widget _chip(AssetCategory? c, String label) {
    final selected = _category == c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: GestureDetector(
        onTap: () => setState(() => _category = c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: Brutal.box(color: selected ? AppColors.yellow : AppColors.paper, borderWidth: 1.8, shadowOffset: selected ? const Offset(2, 2) : Offset.zero),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
        ),
      ),
    );
  }

  Widget _tile(LibraryAsset asset) {
    return GestureDetector(
      onTap: () => widget.pick ? Navigator.of(context).pop(asset.ref) : _manage(asset),
      onLongPress: widget.pick ? () => _manage(asset) : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: Brutal.box(borderWidth: 1.8, shadowOffset: const Offset(2, 2)),
        child: Column(
          children: [
            Expanded(child: Center(child: imageFromRef(asset.ref, fit: BoxFit.contain))),
            const SizedBox(height: 4),
            Text(game.t(asset.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
