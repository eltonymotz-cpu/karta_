// =================================================================
// الشات: زرار بعداد الرسايل الجديدة + نافذة الشات + التسجيل الصوتي
// -----------------------------------------------------------------
// - النافذة بتفتح من تحت ومش بتقفل اللعب (الكارت بيكمل عادي وراها)
// - الرسالة اللي بتتبعت بتظهر "بيتبعت..." لحد ما الهوست يأكدها،
//   ولو ماوصلتش بيظهر "إعادة" و"امسح"
// - التسجيل: دوس المايك → بيسجل بعداد → وقّف → اسمع → ابعت أو امسح
//   (الصوت بيتبعت جوه القعدة على طول، ومابيتحفظش في أي مكان)
// - الهوست: يشوف مين في القعدة ويقدر يكتم أو يطرد، ويمسح أي رسالة
// =================================================================
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/chat.dart';
import '../game/game_controller.dart';
import '../services/app_settings.dart';
import '../services/voice_service.dart';
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

enum _RecState { idle, recording, preview, uploading }

class _ChatPanelState extends State<ChatPanel> {
  GameController get game => widget.game;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _showPeople = false;

  // ---------------- التسجيل ----------------
  _RecState _rec = _RecState.idle;
  Timer? _recTimer;
  VoiceDraft? _draft;
  final AudioPlayer _preview = AudioPlayer();
  bool _previewPlaying = false;

  @override
  void initState() {
    super.initState();
    _preview.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewPlaying = false);
    });
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    if (_rec == _RecState.recording) VoiceService.cancel();
    _preview.dispose();
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

  // ---------------- التسجيل ----------------
  Future<void> _startRecording() async {
    final error = await VoiceService.start();
    if (!mounted) return;
    if (error != null) return _snack(error.contains('permission') ? game.t(UiText.micDenied) : error);
    setState(() => _rec = _RecState.recording);
    final max = AppSettings.current.voiceMaxSeconds;
    _recTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      // أقصى مدة: بيقف لوحده
      if (VoiceService.elapsed.inSeconds >= max) {
        _stopRecording();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _stopRecording() async {
    _recTimer?.cancel();
    final (draft, error) = await VoiceService.stop();
    if (!mounted) return;
    if (draft == null) {
      setState(() => _rec = _RecState.idle);
      return _snack(error ?? 'Recording failed');
    }
    setState(() {
      _draft = draft;
      _rec = _RecState.preview;
    });
  }

  Future<void> _togglePreview() async {
    final draft = _draft;
    if (draft == null) return;
    if (_previewPlaying) {
      await _preview.pause();
      setState(() => _previewPlaying = false);
      return;
    }
    try {
      await _preview.play(BytesSource(draft.bytes, mimeType: draft.mime)); // من الذاكرة
      setState(() => _previewPlaying = true);
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _discardDraft() async {
    await _preview.stop();
    setState(() {
      _draft = null;
      _previewPlaying = false;
      _rec = _RecState.idle;
    });
  }

  Future<void> _cancelRecording() async {
    _recTimer?.cancel();
    await VoiceService.cancel();
    if (mounted) setState(() => _rec = _RecState.idle);
  }

  /// الإرسال (بعد التأكيد بس): الصوت نفسه بيتبعت جوه رسالة الشات
  Future<void> _sendVoice() async {
    final draft = _draft;
    if (draft == null) return;
    await _preview.stop();
    final rejected = game.sendChat('', voice: VoiceAttachment.fromBytes(draft.bytes, draft.mime, draft.durationMs));
    if (!mounted) return;
    if (rejected != null) return _snack(_rejection(rejected)); // التسجيل لسه موجود: يقدر يعيد
    setState(() {
      _draft = null;
      _previewPlaying = false;
      _rec = _RecState.idle;
    });
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

  /// خانة الكتابة + المايك (أو شريط التسجيل/المعاينة)
  Widget _composer() {
    final voiceOn = AppSettings.current.voiceOnline;
    Widget bar;
    switch (_rec) {
      case _RecState.recording:
        bar = Row(
          children: [
            Pulse(scale: 1.2, child: Icon(Icons.fiber_manual_record, color: AppColors.red)),
            const SizedBox(width: 6),
            Text('${game.t(UiText.recording)} ${_clock(VoiceService.elapsed.inMilliseconds)} / ${AppSettings.current.voiceMaxSeconds}s',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const Spacer(),
            IconButton(tooltip: game.t(UiText.discard), onPressed: _cancelRecording, icon: Icon(Icons.delete_outline, color: AppColors.red)),
            SquareButton(color: AppColors.red, onTap: _stopRecording, child: Text('⏹ ${game.t(UiText.stopRecording)}')),
          ],
        );
      case _RecState.preview:
      case _RecState.uploading:
        final uploading = _rec == _RecState.uploading;
        bar = Row(
          children: [
            IconButton(
              onPressed: uploading ? null : _togglePreview,
              icon: Icon(_previewPlaying ? Icons.pause_circle : Icons.play_circle, color: AppColors.ink, size: 32),
            ),
            Text(_clock(_draft?.durationMs ?? 0), textDirection: TextDirection.ltr, style: rankStyle(size: 14)),
            const Spacer(),
            if (uploading) ...[
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.ink)),
              const SizedBox(width: 8),
              Text(game.t(UiText.uploadingVoice), style: const TextStyle(fontWeight: FontWeight.w800)),
            ] else ...[
              IconButton(tooltip: game.t(UiText.discard), onPressed: _discardDraft, icon: Icon(Icons.delete_outline, color: AppColors.red)),
              SquareButton(color: AppColors.green, onTap: _sendVoice, child: Text('➤ ${game.t(UiText.sendVoice)}')),
            ],
          ],
        );
      case _RecState.idle:
        bar = Row(
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
            if (voiceOn)
              IconButton(
                tooltip: game.t(UiText.record),
                onPressed: _startRecording,
                icon: Icon(Icons.mic, color: AppColors.ink),
              ),
            SquareButton(color: AppColors.yellow, onTap: _sendText, child: const Icon(Icons.send)),
          ],
        );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.ink, width: 2))),
      child: SafeArea(top: false, child: bar),
    );
  }
}

String _clock(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
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
              if (message.voice != null) VoiceMessagePlayer(game: game, voice: message.voice!),
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
              Text(pending.voice != null ? '🎤 ${game.t(UiText.voiceNote)}' : pending.text,
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

/// مشغّل الرسالة الصوتية (تشغيل/إيقاف + المدة). الصوت بيتشغل من الذاكرة على طول.
class VoiceMessagePlayer extends StatefulWidget {
  final GameController game;
  final VoiceAttachment voice;
  const VoiceMessagePlayer({super.key, required this.game, required this.voice});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = _player ??= AudioPlayer()
      ..onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
    try {
      if (_playing) {
        await player.pause();
      } else {
        await player.play(BytesSource(widget.voice.bytes, mimeType: widget.voice.mime));
      }
      if (mounted) setState(() => _playing = !_playing);
    } catch (e) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // اللي دخل متأخر بيشوف إن فيه رسالة صوتية، بس الصوت نفسه مابيتبعتش تاني
    if (!widget.voice.available) {
      return Text(widget.game.t(UiText.voiceUnavailable), style: TextStyle(fontSize: 12, color: AppColors.muted));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _toggle,
          icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle, color: AppColors.ink, size: 30),
        ),
        Text('🎤 ${_clock(widget.voice.durationMs)}', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
      ],
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
