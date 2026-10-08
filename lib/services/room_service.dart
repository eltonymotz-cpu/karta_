// =================================================================
// القعدة أونلاين (وضع أكتر من موبايل) عن طريق Supabase Realtime
// -----------------------------------------------------------------
// - صاحب القعدة (الهوست) بيفتح "قناة" باسم الكود، وكل ما حالة اللعبة تتغير
//   بيبعت نسخة منها (state) لكل اللي في القناة.
// - المتفرج بيدخل نفس القناة بالكود، وأول ما يدخل بيبعت "hello"
//   فالهوست يرد عليه بالحالة الحالية على طول.
// - بنستخدم Broadcast بس، فمش محتاجين أي جداول في قاعدة البيانات.
// =================================================================
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  final String code;                 // كود القعدة (مثلاً K7P2Q)
  final bool isHost;                 // هل إحنا صاحب القعدة؟
  RealtimeChannel? _channel;
  bool connected = false;

  RoomService._(this.code, this.isHost);

  /// حروف الكود (من غير الحروف اللي بتتلخبط زي O و 0 و I و 1)
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// كود عشوائي من 5 حروف
  static String newCode() {
    final random = Random();
    return List.generate(5, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
  }

  /// فتح قعدة جديدة (للهوست)
  /// onHello: بتتنادى لما متفرج جديد يدخل (عشان نبعتله الحالة)
  static RoomService host({required String code, required void Function() onHello, void Function()? onConnected}) {
    final room = RoomService._(code, true);
    room._open(
      listeners: {'hello': (_) => onHello()},
      onConnected: () {
        onHello(); // نبعت الحالة أول ما نتصل
        onConnected?.call();
      },
    );
    return room;
  }

  /// الدخول لقعدة موجودة (للمتفرج)
  /// onState: بتتنادى كل ما الهوست يبعت حالة جديدة
  static RoomService join({
    required String code,
    required void Function(Map<String, dynamic> state) onState,
    void Function()? onConnected,
  }) {
    final room = RoomService._(code, false);
    room._open(
      listeners: {'state': onState},
      onConnected: () {
        room._send('hello', {}); // نطلب الحالة الحالية من الهوست
        onConnected?.call();
      },
    );
    return room;
  }

  void _open({
    required Map<String, void Function(Map<String, dynamic>)> listeners,
    required void Function() onConnected,
  }) {
    final channel = Supabase.instance.client.channel('karta-room-$code');
    listeners.forEach((event, callback) {
      channel.onBroadcast(
        event: event,
        callback: (message) {
          // الرسالة بتوصل وجواها "payload" فيه البيانات اللي اتبعتت
          final payload = message['payload'];
          callback(payload is Map ? Map<String, dynamic>.from(payload) : message);
        },
      );
    });
    channel.subscribe((status, error) {
      connected = status == RealtimeSubscribeStatus.subscribed;
      if (connected) onConnected();
    });
    _channel = channel;
  }

  /// الهوست بيبعت حالة اللعبة لكل المتفرجين
  void sendState(Map<String, dynamic> state) => _send('state', state);

  void _send(String event, Map<String, dynamic> payload) {
    if (!connected) return;
    _channel?.sendBroadcastMessage(event: event, payload: payload);
  }

  /// قفل القعدة
  Future<void> close() async {
    connected = false;
    final channel = _channel;
    _channel = null;
    if (channel != null) await Supabase.instance.client.removeChannel(channel);
  }
}
