// =================================================================
// مكتبة الرسايل الصوتية المحفوظة
// -----------------------------------------------------------------
// - "رسايلي": الرسايل اللي حفظتها (خاصة أو عامة) - أسمعها، أغيّر اسمها،
//   أخليها عامة/خاصة، أمسحها، أو أبعتها في شات القعدة من غير رفع تاني
// - "رسايل عامة": اللي الناس خلوها عامة والأدمن وافق عليها
// - adminReview = true: لوحة الأدمن لمراجعة الرسايل العامة (وافق/ارفض/امسح)
// السيرفر نفسه (RLS) هو اللي بيحمي الرسايل الخاصة، مش الشاشة.
// =================================================================
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/texts.dart';
import '../game/chat.dart';
import '../game/game_controller.dart';
import '../services/app_settings.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class VoiceLibraryScreen extends StatefulWidget {
  final GameController game;
  final bool adminReview;
  const VoiceLibraryScreen({super.key, required this.game, this.adminReview = false});

  @override
  State<VoiceLibraryScreen> createState() => _VoiceLibraryScreenState();
}

class _VoiceLibraryScreenState extends State<VoiceLibraryScreen> {
  GameController get game => widget.game;
  bool _publicTab = false;
  bool _loading = true;
  String? _error;
  List<SavedVoiceNote> _notes = [];
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (notes, error) = await VoiceService.list(publicOnly: _publicTab, pendingOnly: widget.adminReview && !_publicTab);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      _notes = notes;
    });
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  Future<void> _play(SavedVoiceNote note) async {
    if (_playingId == note.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    final url = await VoiceService.linkFor(note.path);
    if (url == null) return _snack('Could not open the recording', error: true);
    await _player.play(UrlSource(url));
    if (mounted) setState(() => _playingId = note.id);
  }

  Future<void> _rename(SavedVoiceNote note) async {
    final controller = TextEditingController(text: note.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(game.t(UiText.rename)),
        content: TextField(controller: controller, maxLength: 60, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(game.t(UiText.cancel))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(game.t(UiText.save))),
        ],
      ),
    );
    controller.dispose();
    if (title == null) return;
    final error = await VoiceService.update(note.id, title: title.trim());
    if (error != null) return _snack(error, error: true);
    _load();
  }

  Future<void> _setVisibility(SavedVoiceNote note, String visibility) async {
    final error = await VoiceService.update(note.id, visibility: visibility);
    if (error != null) return _snack(error, error: true);
    _load();
  }

  Future<void> _setStatus(SavedVoiceNote note, String status) async {
    final error = await VoiceService.update(note.id, status: status);
    if (error != null) return _snack(error, error: true);
    _load();
  }

  Future<void> _delete(SavedVoiceNote note) async {
    final error = await VoiceService.delete(note);
    if (error != null) return _snack(error, error: true);
    _load();
  }

  /// إعادة استخدام: بنعمل رابط جديد لنفس الملف ونبعته في الشات (من غير رفع تاني)
  Future<void> _sendToChat(SavedVoiceNote note) async {
    if (!game.chatAvailable) return _snack(game.t(UiText.noRoomForVoice), error: true);
    final url = await VoiceService.linkFor(note.path);
    if (url == null) return _snack('Could not open the recording', error: true);
    final rejected = game.sendChat('', voice: VoiceAttachment(url: url, durationMs: note.durationMs));
    if (rejected != null) return _snack(game.t(UiText.notDelivered), error: true);
    _snack(game.t(UiText.sentToChat));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.adminReview
        ? [(false, game.t(UiText.pendingReview)), (true, game.t(UiText.publicVoices))]
        : [(false, game.t(UiText.voiceLibrary)), (true, game.t(UiText.publicVoices))];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        SquareButton(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('🎤 ${game.t(widget.adminReview ? UiText.reviewVoices : UiText.voiceLibrary)}',
                              style: pixelStyle(size: 16), overflow: TextOverflow.ellipsis),
                        ),
                        SquareButton(onTap: _load, child: const Icon(Icons.refresh)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final (value, label) in tabs)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _publicTab = value);
                                _load();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: Brutal.box(
                                  color: _publicTab == value ? AppColors.yellow : AppColors.paper,
                                  borderWidth: 2,
                                  shadowOffset: _publicTab == value ? const Offset(2, 2) : Offset.zero,
                                ),
                                child: Text(label, style: pixelStyle(size: 13)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.ink));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚠ $_error', textAlign: TextAlign.center, style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SquareButton(onTap: _load, child: Text(game.t(UiText.retry))),
            ],
          ),
        ),
      );
    }
    if (_notes.isEmpty) {
      return Center(child: Text(game.t(UiText.noVoices), style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      itemCount: _notes.length,
      itemBuilder: (context, i) => _row(_notes[i]),
    );
  }

  Widget _row(SavedVoiceNote note) {
    final mine = note.owner == VoiceService.myId;
    final date = note.createdAt.toLocal();
    final seconds = note.durationMs ~/ 1000;
    final status = note.visibility == 'public' && note.status != 'approved'
        ? game.t(note.status == 'pending' ? UiText.pendingReview : UiText.rejected)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      decoration: Brutal.box(borderWidth: 1.8, shadowOffset: const Offset(2, 2)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _play(note),
            icon: Icon(_playingId == note.id ? Icons.stop_circle : Icons.play_circle, size: 34, color: AppColors.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title.isEmpty ? game.t(UiText.voiceNote) : note.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text(
                  '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}  •  ${date.year}/${date.month}/${date.day}'
                  '${note.ownerName.isEmpty || mine ? '' : '  •  ${note.ownerName}'}'
                  '${note.visibility == 'public' ? '  •  🌍' : '  •  🔒'}',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                if (status != null) Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.ink),
            onSelected: (action) {
              switch (action) {
                case 'send':
                  _sendToChat(note);
                case 'rename':
                  _rename(note);
                case 'public':
                  _setVisibility(note, 'public');
                case 'private':
                  _setVisibility(note, 'private');
                case 'approve':
                  _setStatus(note, 'approved');
                case 'reject':
                  _setStatus(note, 'rejected');
                case 'delete':
                  _delete(note);
              }
            },
            itemBuilder: (context) => [
              if (!widget.adminReview && (mine || note.status == 'approved'))
                PopupMenuItem(value: 'send', child: Text(game.t(UiText.sendToChat))),
              if (mine) PopupMenuItem(value: 'rename', child: Text(game.t(UiText.rename))),
              if (mine && note.visibility == 'private' && AppSettings.current.voiceAllowPublic)
                PopupMenuItem(value: 'public', child: Text(game.t(UiText.makePublic))),
              if (mine && note.visibility == 'public') PopupMenuItem(value: 'private', child: Text(game.t(UiText.makePrivate))),
              if (widget.adminReview && note.status != 'approved') PopupMenuItem(value: 'approve', child: Text(game.t(UiText.approve))),
              if (widget.adminReview && note.status != 'rejected') PopupMenuItem(value: 'reject', child: Text(game.t(UiText.reject))),
              if (mine || widget.adminReview)
                PopupMenuItem(value: 'delete', child: Text(game.t(UiText.deleteLabel), style: TextStyle(color: AppColors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
