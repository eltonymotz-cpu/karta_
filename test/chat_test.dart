// اختبارات الشات: قبول/رفض الرسايل عند الهوست، السرعة، الكتم، التكرار، المسح، والطرد،
// واستقبال الموبايلات للرسايل والتاريخ بعد ما يرجعوا، وحدود إعدادات الأدمن
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:karta/game/chat.dart';
import 'package:karta/game/game_controller.dart';
import 'package:karta/services/app_settings.dart';

ChatRejection? send(ChatRoom room, String id, String device, String text, int now, {int perMinute = 5}) => room.accept(
      id: id,
      device: device,
      name: 'Sara',
      text: text,
      context: ChatContext.lobby,
      now: now,
      enabled: true,
      maxLength: 20,
      perMinute: perMinute,
    );

GameController host() {
  final game = GameController()..sound.enabled = false;
  game.chatForTest = true;
  game.startGame(['A', 'B', 'C']);
  return game;
}

void main() {
  test('host validates length, empty text, speed, mutes and duplicates', () {
    final room = ChatRoom();
    expect(send(room, 'm1', 'p1', '  hello  ', 0), isNull);
    expect(room.messages.single.text, 'hello'); // المسافات بتتشال
    expect(send(room, 'm2', 'p1', '   ', 1), ChatRejection.empty);
    expect(send(room, 'm3', 'p1', 'x' * 21, 2), ChatRejection.tooLong);

    // نفس الرسالة اتبعتت تاني (إعادة إرسال): مابتتكررش
    expect(send(room, 'm1', 'p1', 'hello', 3), isNull);
    expect(room.messages.length, 1);

    // السرعة: 5 في الدقيقة
    for (var i = 0; i < 4; i++) {
      expect(send(room, 'fast$i', 'p1', 'hi', 10 + i), isNull);
    }
    expect(send(room, 'fast9', 'p1', 'hi', 20), ChatRejection.tooFast);
    expect(send(room, 'later', 'p1', 'hi', 61000), isNull); // بعد دقيقة يقدر تاني
    expect(send(room, 'other', 'p2', 'hi', 21), isNull);     // موبايل تاني مش متأثر

    // الكتم
    room.muted.add('p2');
    expect(send(room, 'muted', 'p2', 'hi', 22), ChatRejection.muted);

    // الشات مقفول من الأدمن
    expect(
      room.accept(id: 'off', device: 'p3', name: 'x', text: 'hi', context: ChatContext.game, now: 0, enabled: false, maxLength: 20, perMinute: 5),
      ChatRejection.disabled,
    );
  });

  test('only the sender or the host can delete a message, and history is capped', () {
    final room = ChatRoom();
    send(room, 'a', 'p1', 'mine', 0);
    expect(room.delete('a', byDevice: 'p2', byHost: false), isFalse);
    expect(room.delete('a', byDevice: 'p1', byHost: false), isTrue);
    send(room, 'b', 'p1', 'again', 1);
    expect(room.delete('b', byDevice: 'host', byHost: true), isTrue);

    for (var i = 0; i < ChatRoom.historySize + 20; i++) {
      room.accept(id: 'h$i', device: 'd$i', name: 'n', text: 't', context: ChatContext.game, now: i, enabled: true, maxLength: 20, perMinute: 5);
    }
    expect(room.messages.length, ChatRoom.historySize);
    expect(room.messages.last.id, 'h${ChatRoom.historySize + 19}');
  });

  test('host relays player messages, ignores kicked phones and rejects muted ones', () {
    final game = host();
    game.handleRemoteAction({'type': 'chat', 'device': 'phone-1', 'name': 'Omar', 'id': 'x1', 'text': 'يلا بينا'});
    expect(game.chat.messages.single.text, 'يلا بينا');
    expect(game.chat.messages.single.name, 'Omar');
    expect(game.lobby.containsKey('phone-1'), isTrue); // اتسجل في اللوبي

    game.toggleMute('phone-1');
    game.handleRemoteAction({'type': 'chat', 'device': 'phone-1', 'id': 'x2', 'text': 'hello?'});
    expect(game.chat.messages.length, 1);

    // الهوست يطرد موبايل: أي طلب منه بعد كده بيتجاهل (حتى سحب الكارت)
    game.handleRemoteAction({'type': 'claim', 'player': 0, 'device': 'phone-2'});
    expect(game.claims[0], 'phone-2');
    game.kick('phone-2');
    expect(game.claims.containsKey(0), isFalse);
    game.handleRemoteAction({'type': 'chat', 'device': 'phone-2', 'id': 'x3', 'text': 'still here'});
    game.handleRemoteAction({'type': 'claim', 'player': 0, 'device': 'phone-2'});
    expect(game.chat.messages.length, 1);
    expect(game.claims.containsKey(0), isFalse);

    // صاحب الرسالة يمسحها، وحد تاني لأ
    game.handleRemoteAction({'type': 'chatDelete', 'device': 'phone-3', 'id': 'x1'});
    expect(game.chat.messages.length, 1);
    game.handleRemoteAction({'type': 'chatDelete', 'device': 'phone-1', 'id': 'x1'});
    expect(game.chat.messages, isEmpty);
    game.dispose();
  });

  test('player phone shows sending, confirms on echo, marks rejections and merges history after reconnect', () {
    final phone = GameController()..sound.enabled = false;
    phone.isViewer = true;
    phone.chatForTest = true;
    expect(phone.sendChat('hi all'), isNull);
    final pending = phone.pendingChat.values.single;
    expect(pending.failed, isNull);

    // الهوست رد بالرسالة: مابقتش "بتتبعت" وظهرت مرة واحدة بس حتى لو وصلت مرتين
    final echo = ChatMessage(id: pending.id, device: phone.deviceId, name: 'Guest', text: 'hi all', context: ChatContext.lobby, at: 5);
    phone.onRoomEventForTest('chat', echo.toJson());
    phone.onRoomEventForTest('chat', echo.toJson());
    expect(phone.pendingChat, isEmpty);
    expect(phone.chatView.length, 1);

    // رسالة اترفضت (سرعة): بتفضل ظاهرة بالسبب وينفع يعيدها
    phone.sendChat('spam');
    final id = phone.pendingChat.keys.single;
    phone.onRoomEventForTest('chatReject', {'id': id, 'device': phone.deviceId, 'reason': 'tooFast'});
    expect(phone.pendingChat[id]!.failed, ChatRejection.tooFast);
    phone.retryChat(id);
    expect(phone.pendingChat[id]!.failed, isNull);

    // رجع بعد ما فصل: الهوست بيبعت التاريخ كله، وبيتدمج من غير تكرار
    final other = ChatMessage(id: 'o1', device: 'p9', name: 'Mona', text: 'welcome back', context: ChatContext.lobby, at: 3);
    phone.applySnapshotForTest({
      'screen': 'waiting',
      'chat': [echo.toJson(), other.toJson()],
      'lobby': [
        {'d': 'p9', 'n': 'Mona', 'on': true},
      ],
    });
    expect(phone.chatView.map((m) => m.id), ['o1', echo.id]); // بالترتيب
    expect(phone.lobby['p9']!.name, 'Mona');

    // الهوست طردني
    phone.applySnapshotForTest({'screen': 'waiting', 'kicked': [phone.deviceId]});
    expect(phone.wasKicked, isTrue);
    phone.dispose();
  });

  test('voice notes travel inside the message, are validated, and are left out of the history', () {
    final voice = VoiceAttachment.fromBytes(Uint8List.fromList(List.filled(2000, 7)), 'audio/webm', 3000);
    final back = VoiceAttachment.fromJson(voice.toJson())!;
    expect(back.bytes.length, 2000);
    expect(back.durationMs, 3000);
    // نوع مش صوت، أو حجم أكبر من حد القناة، أو base64 بايظ: مرفوض
    expect(VoiceAttachment.fromJson({'b': voice.data, 'mime': 'text/html', 'ms': 3000}), isNull);
    expect(VoiceAttachment.fromJson({'b': 'A' * (VoiceAttachment.maxDataLength + 4), 'mime': 'audio/webm', 'ms': 3000}), isNull);
    expect(VoiceAttachment.fromJson({'b': '%%%not-base64%%%', 'mime': 'audio/webm', 'ms': 3000}), isNull);

    // التاريخ اللي بيتبعت للي بيدخل متأخر: من غير الصوت نفسه (عشان يفضل صغير)
    final message = ChatMessage(id: 'v1', device: 'p1', name: 'Sara', text: '', voice: voice, context: ChatContext.game, at: 1);
    final light = ChatMessage.fromJson(message.toJson(withVoiceData: false))!;
    expect(light.voice!.available, isFalse);
    expect(ChatMessage.fromJson(message.toJson())!.voice!.available, isTrue);
  });

  test('closing the game wipes the chat, the lobby and the device id from memory', () {
    final game = host();
    game.handleRemoteAction({'type': 'chat', 'device': 'phone-1', 'name': 'Omar', 'id': 'x1', 'text': 'hi'});
    game.toggleMute('phone-1');
    game.kick('phone-2');
    final oldId = game.deviceId;
    game.goHome();
    expect(game.chat.messages, isEmpty);
    expect(game.chat.muted, isEmpty);
    expect(game.lobby, isEmpty);
    expect(game.kicked, isEmpty);
    expect(game.chatView, isEmpty);
    expect(game.deviceId, isNot(oldId));
    game.dispose();
  });

  test('admin settings keep values inside safe limits and survive JSON', () {
    final s = AppSettings.fromJson({
      'online': {'enabled': false},
      'chat': {'maxLength': 99999, 'perMinute': 0},
      'voice': {'maxSeconds': 1000},
    });
    expect(s.onlineEnabled, isFalse);
    expect(s.chatMaxLength, AppSettings.chatLengthRange.$2);
    expect(s.chatPerMinute, AppSettings.chatPerMinuteRange.$1);
    expect(s.voiceMaxSeconds, 60); // أكتر من كده الرسالة تعدي حد القناة
    final back = AppSettings.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
    // الإعدادات القديمة (من غير الخانات دي) بتاخد القيم الافتراضية
    expect(AppSettings.fromJson({}).chatOnline, isTrue);
  });
}
