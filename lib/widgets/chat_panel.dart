// =================================================================
// الشات: زرار بعداد الرسايل الجديدة + نافذة الشات (كلام بس)
// -----------------------------------------------------------------
// - النافذة بتفتح من تحت ومش بتقفل اللعب (الكارت بيكمل عادي وراها)
// - الرسالة اللي بتتبعت بتظهر "بيتبعت..." لحد ما الهوست يأكدها،
//   ولو ماوصلتش بيظهر "إعادة" و"امسح"
// - الهوست: يشوف مين في القعدة ويقدر يكتم أو يطرد، ويمسح أي رسالة
// =================================================================
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/chat.dart';
import '../game/game_controller.dart';
import '../services/app_settings.dart';
import '../theme.dart';
import 'common.dart';

/// زرار الشات (بعداد الرسايل اللي ماتقريتش)
class ChatButton extends StatelessWidget {
  final GameController game;
  const ChatButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (!game.chatAvailable) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SquareButton(
          color: AppColors.blue,
          onTap: () => showChatSheet(context, game),
          child: const Icon(Icons.chat_bubble_outline),
        ),
        if (game.chatUnread > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: Brutal.box(color: AppColors.red, borderWidth: 1.6, shadowOffset: Offset.zero, radius: 10),
              child: Text(game.chatUnread > 99 ? '99+' : '${game.chatUnread}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.paper)),
            ),
          ),
      ],
    );
  }
}

Future<void> showChatSheet(BuildContext context, GameController game) async {
  game.setChatOpen(true);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.ink, width: Brutal.border)),
    builder: (context) => Padding(
      // الكيبورد مايغطيش خانة الكتابة
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ChatPanel(game: game),
      ),
    ),
  );
  game.setChatOpen(false);
}

class ChatPanel extends StatefulWidget {
  final GameController game;
  const ChatPanel({super.key, required this.game});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}


class _ChatPanelState extends State<ChatPanel> {
  GameController get game => widget.game;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _showPeople = false;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = true}) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  String _rejection(ChatRejection r) => game.t(switch (r) {
        ChatRejection.tooFast => UiText.rejectTooFast,
        ChatRejection.muted => UiText.rejectMuted,
        ChatRejection.tooLong => UiText.rejectTooLong,
        ChatRejection.disabled => UiText.rejectOff,
        ChatRejection.empty || ChatRejection.invalid => UiText.notDelivered,
      });

  void _sendText() {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    final rejected = game.sendChat(text);
    if (rejected != null) return _snack(_rejection(rejected));
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final messages = game.chatMessages;
        final pending = game.pendingChat.values.toList();
        final title = game.t(game.screen == AppScreen.game || game.screen == AppScreen.results ? UiText.gameChat : UiText.lobbyChat);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.blue,
              child: Row(
                children: [
                  Expanded(child: WindowBar(title: '💬 $title', color: AppColors.blue)),
                  // اللي في القعدة (والهوست بيقدر يكتم ويطرد)
                  IconButton(
                    tooltip: game.t(UiText.roomPeople),
                    icon: Icon(_showPeople ? Icons.chat : Icons.group, color: AppColors.ink),
                    onPressed: () => setState(() => _showPeople = !_showPeople),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showPeople
                  ? LobbyList(game: game)
                  : !game.chatAvailable
                      ? Center(child: Text(game.t(UiText.chatOff), style: TextStyle(color: AppColors.muted)))
                      : messages.isEmpty && pending.isEmpty
                          ? Center(
                              child: Text(game.t(UiText.chatEmpty),
                                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                            )
                          : ListView(
                              controller: _scroll,
                              reverse: true, // الأحدث تحت
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              children: [
                                for (final p in pending.reversed) _PendingBubble(game: game, pending: p, reason: p.failed == null ? null : _rejection(p.failed!)),
                                for (final m in messages.reversed) MessageBubble(game: game, message: m),
                              ],
                            ),
            ),
            if (!_showPeople && game.chatAvailable) _composer(),
          ],
        );
      },
    );
  }

  /// خانة الكتابة
  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.ink, width: 2))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                maxLength: AppSettings.current.chatMaxLength,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: game.t(UiText.chatHint),
                  counterText: '',
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
                    borderSide: BorderSide(color: AppColors.ink, width: 2.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SquareButton(color: AppColors.yellow, onTap: _sendText, child: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

String _time(int ms) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// رسالة في الشات (الكلام بيتعرض كنص عادي، فمفيش أي كود أو روابط بتشتغل منه)
class MessageBubble extends StatelessWidget {
  final GameController game;
  final ChatMessage message;
  const MessageBubble({super.key, required this.game, required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.device == game.deviceId;
    final canDelete = mine || game.isHost;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: Brutal.box(
            color: mine ? AppColors.yellow : AppColors.paper,
            borderWidth: 1.8,
            shadowOffset: const Offset(2, 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.fromHost) const Text('👑 ', style: TextStyle(fontSize: 11)),
                  Flexible(
                    child: Text(message.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ),
                  const SizedBox(width: 8),
                  Text(_time(message.at), textDirection: TextDirection.ltr, style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  if (canDelete)
                    InkWell(
                      onTap: () => game.deleteChat(message.id),
                      child: Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.close, size: 14, color: AppColors.muted)),
                    ),
                ],
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(message.text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// رسالتي اللي لسه بتتبعت (أو ماوصلتش)
class _PendingBubble extends StatelessWidget {
  final GameController game;
  final PendingChat pending;
  final String? reason;
  const _PendingBubble({required this.game, required this.pending, this.reason});

  @override
  Widget build(BuildContext context) {
    final failed = pending.failed != null;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Opacity(
        opacity: failed ? 1 : 0.6,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: Brutal.box(color: AppColors.yellow, borderWidth: 1.8, shadowOffset: Offset.zero),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pending.text,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 2),
              if (!failed)
                Text(game.t(UiText.sending), style: TextStyle(fontSize: 11, color: AppColors.muted))
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text('⚠ ${reason ?? game.t(UiText.notDelivered)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.red))),
                    TextButton(onPressed: () => game.retryChat(pending.id), child: Text(game.t(UiText.retry))),
                    TextButton(onPressed: () => game.discardChat(pending.id), child: Text(game.t(UiText.discard))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اللي في القعدة: مين الهوست، مين متصل، وتحكم الهوست (كتم/طرد)
class LobbyList extends StatelessWidget {
  final GameController game;
  const LobbyList({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final members = game.lobby.entries.toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _row(context, '👑 ${game.t(UiText.host)}', online: true),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(game.t(UiText.nobodyYet), textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          ),
        for (final e in members)
          _row(
            context,
            e.key == game.deviceId ? '${e.value.name} (${game.t(UiText.youWord)})' : e.value.name,
            online: game.isHost ? game.nowMs - e.value.lastSeen < 50000 : e.value.lastSeen > 0,
            muted: game.isHost ? game.chat.muted.contains(e.key) : e.value.muted,
            device: e.key,
          ),
      ],
    );
  }

  Widget _row(BuildContext context, String name, {required bool online, bool muted = false, String? device}) {
    final canModerate = game.isHost && device != null && device != game.deviceId;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Brutal.box(borderWidth: 1.6, shadowOffset: Offset.zero),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: online ? AppColors.green : AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
          Text(game.t(online ? UiText.online : UiText.offline), style: TextStyle(fontSize: 11, color: AppColors.muted)),
          if (muted) Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.volume_off, size: 16, color: AppColors.red)),
          if (canModerate) ...[
            TextButton(onPressed: () => game.toggleMute(device), child: Text(game.t(muted ? UiText.unmute : UiText.mute))),
            TextButton(
              onPressed: () => _confirmKick(context, name, device),
              child: Text(game.t(UiText.kick), style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmKick(BuildContext context, String name, String device) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        content: Text(game.t(fillText(UiText.kickConfirm, {'name': name})), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(game.t(UiText.no))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(game.t(UiText.kick), style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (yes == true) game.kick(device);
  }
}
