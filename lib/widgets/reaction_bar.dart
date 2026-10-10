// =================================================================
// الأزرار السريعة: 5 زراير إيموجي تحت الترابيزة
// -----------------------------------------------------------------
// - دوسة = الإيموجي يظهر في نص اللعبة عند كل اللي في القعدة (ومعاه اسمك)
// - دوسة طويلة = تختار إيموجي تاني للزرار ده
// - مابيتحفظش: لما اللعبة تتقفل الزراير بترجع للأصل
// =================================================================
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import 'common.dart';

class ReactionBar extends StatelessWidget {
  final GameController game;
  const ReactionBar({super.key, required this.game});

  static const choices = [
    '😂', '🤣', '😍', '😎', '🤔', '😱', '😭', '😡', '🥳', '🤯', '😴', '🤡',
    '👏', '👍', '👎', '🙏', '💪', '👀', '🔥', '💯', '❤️', '💔', '🎉', '💣',
    '🃏', '⏰', '🐢', '🚀', '🍿', '☕',
  ];

  @override
  Widget build(BuildContext context) {
    if (!game.reactionsOn) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < game.reactionButtons.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onLongPress: () => _edit(context, i),
                child: SquareButton(
                  onTap: () => game.sendReaction(game.reactionButtons[i]),
                  child: Text(game.reactionButtons[i], style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// اختيار إيموجي للزرار (من القايمة أو كتابة إيموجي تاني)
  Future<void> _edit(BuildContext context, int index) async {
    final controller = TextEditingController();
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(game.t(UiText.editReaction), style: pixelStyle(size: 15)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final e in choices)
                    InkWell(
                      onTap: () => Navigator.pop(context, e),
                      child: Padding(padding: const EdgeInsets.all(4), child: Text(e, style: const TextStyle(fontSize: 24))),
                    ),
                ],
              ),
              TextField(
                controller: controller,
                maxLength: 8,
                decoration: InputDecoration(labelText: game.t(UiText.customEmoji)),
                onSubmitted: (v) => Navigator.pop(context, v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(game.t(UiText.cancel))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(game.t(UiText.save))),
        ],
      ),
    );
    controller.dispose();
    if (picked != null && GameController.isValidReaction(picked)) game.setReactionButton(index, picked);
  }
}
