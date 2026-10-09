// =================================================================
// صفحة المساعدة: إزاي نلعب كارتة (بتتفتح من زرار ? في الشاشة الأولى)
// -----------------------------------------------------------------
// الأجزاء العامة من help_texts.dart، والأنماط والكروت من بيانات اللعبة نفسها،
// فلو الأدمن أضاف أو عدّل كارت بيظهر هنا على طول.
// =================================================================
import 'package:flutter/material.dart';

import '../data/game_modes.dart';
import '../data/help_texts.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';

class HelpScreen extends StatelessWidget {
  final GameController game;
  const HelpScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder: لو اللغة اتغيرت أو الأدمن عدّل كارت، الصفحة بتتحدث
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final sections = [
          (HelpText.goalTitle, HelpText.goal, AppColors.teal),
          (HelpText.startTitle, HelpText.start, AppColors.orange),
          (HelpText.turnTitle, HelpText.turn, AppColors.pink),
          (HelpText.scoreTitle, HelpText.score, AppColors.yellow),
          (HelpText.hostTitle, HelpText.host, AppColors.blue),
          (HelpText.buttonsTitle, HelpText.buttons, AppColors.green),
          (HelpText.timersTitle, HelpText.timers, AppColors.red),
          (HelpText.specialTitle, HelpText.special, AppColors.purple),
          (HelpText.extrasTitle, HelpText.extras, AppColors.orange),
          (HelpText.multiTitle, HelpText.multi, AppColors.teal),
        ];
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: AppBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
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
                          const StickerImage(Sticker.magnifier, size: 36),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Headline(game.t(HelpText.title), size: 34),
                      const SizedBox(height: 16),
                      for (final (title, body, color) in sections) ...[
                        RetroWindow(
                          title: game.t(title),
                          barColor: color,
                          child: Text(game.t(body), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.6)),
                        ),
                        const SizedBox(height: 14),
                      ],
                      // الأنماط وكروتها (من بيانات اللعبة الحقيقية)
                      RetroWindow(
                        title: game.t(HelpText.modesTitle),
                        barColor: AppColors.orange,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(game.t(HelpText.modesHint), style: TextStyle(fontSize: 13, color: AppColors.muted)),
                            const SizedBox(height: 10),
                            for (final entry in allModes.entries) _modeTile(entry.key, entry.value),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// نمط واحد: اسمه ووصفه، ولما يتفتح بتظهر كل كروته
  Widget _modeTile(String id, GameMode mode) {
    final cards = cardsOf(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: Brutal.box(borderWidth: 2, shadowOffset: const Offset(2, 2)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: ModeIcon(mode: mode, size: 40),
          title: Text(game.t(mode.name), style: pixelStyle(size: 16)),
          subtitle: Text(game.t(mode.description), style: TextStyle(fontSize: 12, color: AppColors.muted)),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          children: [for (final card in cards) _cardRow(card)],
        ),
      ),
    );
  }

  /// كارت واحد: قيمته وعنوانه ونوعه وشرحه
  Widget _cardRow(CardEntry card) {
    final rule = card.rule;
    final colors = ResolvedCardColors.of(rule, card.rank);
    final description = fillText(rule.description, {'player': HelpText.playerWord});
    return Opacity(
      opacity: rule.enabled ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        clipBehavior: Clip.antiAlias,
        decoration: Brutal.box(color: colors.bg, borderWidth: 1.8, shadowOffset: Offset.zero),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: colors.bar,
              child: Column(
                children: [
                  Text(card.rank, textDirection: TextDirection.ltr, style: rankStyle(size: 16)),
                  Text(rule.emoji, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.t(rule.title), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(game.t(description), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tag(game.t(HelpText.typeExplain(rule.type)), AppColors.paper),
                        if (rule.isAction) _tag('⚡ ${game.t(UiText.actionCard)}', AppColors.orange),
                        if (rule.timed) _tag(game.t(HelpText.timedTag), AppColors.yellow),
                        if (card.isExtra) _tag(game.t(fillText(HelpText.copies, {'n': card.copies})), AppColors.blue),
                        if (!rule.enabled) _tag(game.t(HelpText.disabled), AppColors.line),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: Brutal.box(color: color, borderWidth: 1.4, shadowOffset: Offset.zero, radius: 3),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
