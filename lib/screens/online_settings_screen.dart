// =================================================================
// لوحة الأدمن: إعدادات الأونلاين والشات والرسايل الصوتية
// -----------------------------------------------------------------
// كل التعديلات بتتحفظ في Supabase (جدول karta_settings) وبتوصل لكل الأجهزة لايف.
// السيرفر بيرفض الحفظ لو الحساب مش أدمن (RLS)، فالشاشة دي لوحدها مش بتحمي حاجة.
// القيم الرقمية ليها حدود (مثلاً حجم الصوت أقصاه 2 ميجا زي حد الـ bucket نفسه).
// =================================================================
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/app_settings.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnlineSettingsScreen extends StatefulWidget {
  final GameController game;
  const OnlineSettingsScreen({super.key, required this.game});

  @override
  State<OnlineSettingsScreen> createState() => _OnlineSettingsScreenState();
}

class _OnlineSettingsScreenState extends State<OnlineSettingsScreen> {
  GameController get game => widget.game;
  late AppSettings _s = AppSettings.current;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await AppSettings.save(_s);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? game.t(UiText.saved) : game.t(fillText(UiText.saveFailed, {'error': error})),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: error == null ? AppColors.green : AppColors.red,
      ),
    );
    if (error == null) game.modesChanged();
  }

  Widget _switch(String label, bool value, void Function(bool) onChanged, {String? hint}) {
    // Material شفاف عشان المفتاح يرسم ضغطته فوق لون الشباك
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        value: value,
        onChanged: (v) => setState(() => onChanged(v)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: hint == null ? null : Text(hint, style: const TextStyle(fontSize: 12)),
        activeThumbColor: AppColors.ink,
        activeTrackColor: AppColors.green,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  /// رقم بزراير - و + (في حدود مسموحة)
  Widget _stepper(String label, int value, (int, int) range, int step, void Function(int) onChanged) {
    void change(int delta) => setState(() => onChanged((value + delta).clamp(range.$1, range.$2)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          SquareButton(onTap: value > range.$1 ? () => change(-step) : null, child: const Icon(Icons.remove)),
          SizedBox(
            width: 64,
            child: Text('$value', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: rankStyle(size: 16)),
          ),
          SquareButton(onTap: value < range.$2 ? () => change(step) : null, child: const Icon(Icons.add)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                children: [
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      SquareButton(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🌐 ${game.t(UiText.onlineSettings)}',
                          style: pixelStyle(size: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      LangToggle(game: game, compact: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RetroWindow(
                    title: '📲 ${game.t(UiText.multiDevice)}',
                    barColor: AppColors.orange,
                    child: _switch(game.t(UiText.onlineEnabled), _s.onlineEnabled, (v) => _s = _s.copyWith(onlineEnabled: v)),
                  ),
                  const SizedBox(height: 16),
                  RetroWindow(
                    title: '💬 ${game.t(UiText.chat)}',
                    barColor: AppColors.blue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _switch(game.t(UiText.chatOnlineLabel), _s.chatOnline, (v) => _s = _s.copyWith(chatOnline: v)),
                        Text(game.t(UiText.chatOfflineNote), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        _stepper(
                          game.t(UiText.chatMaxLength),
                          _s.chatMaxLength,
                          AppSettings.chatLengthRange,
                          50,
                          (v) => _s = _s.copyWith(chatMaxLength: v),
                        ),
                        _stepper(
                          game.t(UiText.chatPerMinute),
                          _s.chatPerMinute,
                          AppSettings.chatPerMinuteRange,
                          1,
                          (v) => _s = _s.copyWith(chatPerMinute: v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RetroWindow(
                    title: '😀 ${game.t(UiText.reactionsTitle)}',
                    barColor: AppColors.pink,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _switch(game.t(UiText.reactionsLabel), _s.reactionsEnabled, (v) => _s = _s.copyWith(reactionsEnabled: v)),
                        Text(game.t(UiText.reactionsHint), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text(
                          game.t(UiText.nothingSavedNote),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _saving
                      ? Center(child: CircularProgressIndicator(color: AppColors.ink))
                      : BrutalButton(label: game.t(UiText.save), onTap: _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
