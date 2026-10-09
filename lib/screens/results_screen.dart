// =================================================================
// شاشة النهاية: ترتيب اللاعيبة من الأقل كروت (الكسبان) للأكتر
// =================================================================
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ResultsScreen extends StatelessWidget {
  final GameController game;
  const ResultsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // نسخة مترتبة من اللاعيبة (من غير ما نغيّر الترتيب الأصلي)
    final ranked = [...game.players]..sort((a, b) => a.cards.length.compareTo(b.cards.length));
    final minCards = ranked.first.cards.length;
    final maxCards = ranked.last.cards.length;

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
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [LangToggle(game: game), const Spacer(), const ShapeAccent(size: 12)],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Headline(game.t(UiText.gameOver), size: 38)),
                            Container(
                              width: 96,
                              height: 104,
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(AppTheme.logo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(game.t(UiText.fewestWins),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        for (var i = 0; i < ranked.length; i++)
                          _resultRow(
                            ranked[i],
                            i,
                            isWinner: ranked[i].cards.length == minCards,
                            isLoser: ranked[i].cards.length == maxCards && maxCards != minCards,
                          ),
                        if (game.asideCards.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              game.t(fillText(UiText.asideLeft, {'n': game.asideCards.length})),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        if (game.caduCards.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              game.t(fillText(UiText.caduLeft, {'n': game.caduCards.length})),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        const SizedBox(height: 14),
                        // المتفرج: زرار خروج بس (صاحب القعدة هو اللي بيقرر يلعبوا تاني)
                        if (game.isViewer)
                          BrutalButton(label: game.t(UiText.leave), onTap: game.goHome, color: AppColors.paper)
                        else ...[
                          BrutalButton(label: game.t(UiText.playAgain), onTap: game.playAgain),
                          const SizedBox(height: 14),
                          BrutalButton(
                            label: game.t(UiText.backToSetup),
                            onTap: game.backToSetup,
                            color: AppColors.paper,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const ShapesStrip(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// سطر لاعب في الترتيب: الميدالية + الاسم + كروته + العدد
  Widget _resultRow(Player player, int position, {required bool isWinner, required bool isLoser}) {
    final medal = isWinner ? '🏆' : (isLoser ? '🤡' : '${position + 1}');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias, // الخانات الملونة تمشي مع الزوايا المدوّرة
      decoration: Brutal.box(
        color: isWinner ? AppColors.yellow : AppColors.paper,
        shadowColor: isLoser ? AppColors.red : AppColors.ink,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // خانة الميدالية بلون اللاعب
            Container(
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: player.color,
                border: BorderDirectional(end: BorderSide(color: AppColors.ink, width: Brutal.border)),
              ),
              child: Text(medal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    if (player.cards.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      // الكروت اللي أخدها
                      Wrap(spacing: 4, runSpacing: 4, children: [for (final c in player.cards) _miniCard(c)]),
                    ],
                  ],
                ),
              ),
            ),
            // عدد الكروت في مربع أسود
            Container(
              width: 56,
              alignment: Alignment.center,
              color: AppColors.ink,
              child: Text(
                '${player.cards.length}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.yellow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(PlayingCard card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.ink, width: 1.5)),
      child: Text(
        card.label,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: card.isRed ? AppColors.red : AppColors.ink,
        ),
      ),
    );
  }
}
