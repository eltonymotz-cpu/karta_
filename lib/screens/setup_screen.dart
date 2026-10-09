// =================================================================
// شاشة الإعداد: أسامي اللاعيبة + نمط اللعب
// =================================================================
import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../game/game_settings.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SetupScreen extends StatefulWidget {
  final GameController game;
  const SetupScreen({super.key, required this.game});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // متحكم لكل خانة اسم (بيحفظ النص المكتوب)
  late List<TextEditingController> _controllers;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    // لو راجعين من لعبة قبل كده نرجّع نفس الأسامي، وإلا 3 خانات فاضية
    final names = game.lastNames.isNotEmpty ? game.lastNames : ['', '', ''];
    _controllers = [for (final n in names) TextEditingController(text: n)];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_controllers.length >= GameController.maxPlayers) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removePlayer(int index) {
    if (_controllers.length <= GameController.minPlayers) return;
    setState(() => _controllers.removeAt(index).dispose());
  }

  void _start() {
    // الاسم الفاضي يبقى "لاعب 1" وهكذا
    final names = [
      for (var i = 0; i < _controllers.length; i++)
        _controllers[i].text.trim().isEmpty
            ? game.t(fillText(UiText.defaultPlayer, {'n': i + 1}))
            : _controllers[i].text.trim(),
    ];
    // منع تكرار الأسامي
    if (names.toSet().length != names.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(game.t(UiText.duplicateNames), style: const TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    game.startGame(names);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        // مفتاح اللغة فوق على الشمال
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            SquareButton(onTap: game.goHome, child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                            const SizedBox(width: 8),
                            LangToggle(game: game),
                            const Spacer(),
                            // علامة إن اللعبة هتبقى على أكتر من موبايل
                            if (game.multiDevice)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: AppColors.ink,
                                child: Text(game.t(UiText.multiDevice).toUpperCase(),
                                    style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w900)),
                              )
                            else
                              const ShapeAccent(size: 12),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Headline(game.t(UiText.setupTitle), size: 40),
                        const SizedBox(height: 8),
                        Text(
                          game.t(UiText.subtitle),
                          style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        _logo(),
                        const SizedBox(height: 24),
                        _sectionTitle(game.t(UiText.players), game.t(UiText.playersRange)),
                        const SizedBox(height: 10),
                        for (var i = 0; i < _controllers.length; i++) _playerField(i),
                        _addButton(),
                        const SizedBox(height: 26),
                        _sectionTitle(game.t(UiText.mode), null),
                        const SizedBox(height: 10),
                        // الأنماط الأساسية + اللي الأدمن ضافها
                        for (final entry in allModes.entries) _modeOption(entry.key, entry.value),
                        const SizedBox(height: 26),
                        _settingsBox(),
                        const SizedBox(height: 22),
                        BrutalButton(label: game.t(UiText.start), onTap: _start),
                      ],
                    ),
                  ),
                ),
              ),
              // شريط التحذير في آخر الشاشة
              const ShapesStrip(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// اللوجو في صندوق أبيض بحدود سودا
  Widget _logo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.all(12),
          child: Center(child: Image.asset(AppTheme.logo, fit: BoxFit.contain)),
        ),
        const Positioned(top: 10, right: 10, child: DotGrid(columns: 4, rows: 3)),
      ],
    );
  }

  /// عنوان قسم صغير
  Widget _sectionTitle(String title, String? hint) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: AppColors.yellow, margin: const EdgeInsetsDirectional.only(end: 8)),
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Text(hint, style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  /// خانة اسم لاعب: مربع بلونه ورقمه | العنوان + الاسم | زرار حذف
  Widget _playerField(int index) {
    final color = AppColors.playerColors[index % AppColors.playerColors.length];
    final canRemove = _controllers.length > GameController.minPlayers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 60,
        clipBehavior: Clip.antiAlias, // مربع الرقم يمشي مع الزوايا المدوّرة
        decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(3, 3)),
        child: Row(
          children: [
            // مربع الرقم بلون اللاعب
            Container(
              width: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: BorderDirectional(end: BorderSide(color: AppColors.ink, width: 2)),
              ),
              child: Text('${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.t(fillText(UiText.playerLabel, {'n': index + 1})).toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    TextField(
                      controller: _controllers[index],
                      maxLength: 14,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 2),
                        hintText: game.t(UiText.typeName),
                        hintStyle: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: canRemove ? () => _removePlayer(index) : null,
              icon: const Icon(Icons.close),
              color: AppColors.ink,
              disabledColor: AppColors.line,
            ),
          ],
        ),
      ),
    );
  }

  /// زرار إضافة لاعب
  Widget _addButton() {
    final enabled = _controllers.length < GameController.maxPlayers;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? _addPlayer : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(Brutal.radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(game.t(UiText.addPlayer).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  /// إعدادات اللعبة: مؤقت كروت الأسئلة + مدة القنبلة (بتتحفظ على الجهاز)
  Widget _settingsBox() {
    final s = game.settings;
    Widget choice(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: Brutal.box(
            color: selected ? AppColors.yellow : AppColors.paper,
            borderWidth: 2,
            shadowOffset: selected ? const Offset(3, 3) : const Offset(1, 1),
          ),
          child: Text(label, style: pixelStyle(size: 14)),
        ),
      );
    }

    return RetroWindow(
      title: game.t(UiText.gameSettings),
      barColor: AppColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⏱ ${game.t(UiText.questionTimer)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          Text(game.t(UiText.questionTimerHint), style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final seconds in GameSettings.questionOptions)
                choice(
                  seconds == 0 ? game.t(UiText.off) : '$seconds ${game.t(UiText.sec)}',
                  s.questionSeconds == seconds,
                  () => game.updateSettings(questionSeconds: seconds),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('💣 ${game.t(UiText.bombRange)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          Text(game.t(UiText.bombRangeHint), style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final max in GameSettings.bombMaxOptions)
                choice(
                  '${GameSettings.bombMinSeconds}–$max ${game.t(UiText.sec)}',
                  s.bombMaxSeconds == max,
                  () => game.updateSettings(bombMaxSeconds: max),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// اختيار نمط: مربع أصفر فيه إيموجي + الاسم والوصف (النمط المختار بيبقى أصفر)
  Widget _modeOption(String id, GameMode mode) {
    final selected = game.modeId == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => game.setMode(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: Brutal.box(
            color: selected ? AppColors.yellow : AppColors.paper,
            borderWidth: 2,
            shadowOffset: selected ? const Offset(4, 4) : const Offset(2, 2),
          ),
          child: Row(
            children: [
              // صورة النمط (أو الإيموجي لو مفيش صورة)
              ModeIcon(mode: mode, size: 52, color: selected ? AppColors.paper : AppColors.yellow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.t(mode.name).toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(game.t(mode.description),
                        style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
