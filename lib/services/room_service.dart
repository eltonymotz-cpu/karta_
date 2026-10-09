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
  /// onAction: طلب من موبايل لاعب (زي "عايز أسحب") - الهوست بيتأكد منه قبل ما ينفذه
  static RoomService host({
    required String code,
    required void Function(Map<String, dynamic> hello) onHello,
    required void Function(Map<String, dynamic> action) onAction,
    void Function()? onConnected,
  }) {
    final room = RoomService._(code, true);
    room._open(
      listeners: {'hello': onHello, 'action': onAction},
      onConnected: () {
        onHello(const {}); // نبعت الحالة أول ما نتصل
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
    void Function(String event, Map<String, dynamic> data)? onEvent,
    void Function()? onConnected,
    Map<String, dynamic> hello = const {},
  }) {
    final room = RoomService._(code, false);
    room._open(
      listeners: {
        'state': onState,
        // أحداث صغيرة من الهوست (رسالة شات جديدة، مسح رسالة، رفض رسالة)
        // بدل ما نبعت الحالة كلها مع كل رسالة
        for (final event in eventNames) event: (data) => onEvent?.call(event, data),
      },
      onConnected: () {
        room._send('hello', hello); // نطلب الحالة الحالية من الهوست (ومعاها اسمنا)
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
        callback: (message) => callback(unwrap(message)),
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

  /// أسماء الأحداث الصغيرة اللي الهوست بيبعتها (الشات)
  static const eventNames = ['chat', 'chatDel', 'chatReject'];

  /// الهوست بيبعت حدث صغير (رسالة شات مثلاً)
  void sendEvent(String event, Map<String, dynamic> data) {
    if (isHost && eventNames.contains(event)) _send(event, data);
  }

  /// موبايل لاعب بيبعت طلب للهوست (الهوست هو اللي بيقرر ينفذه ولا لأ)
  void sendAction(Map<String, dynamic> action) {
    if (!isHost) _send('action', action);
  }

  void _send(String event, Map<String, dynamic> payload) {
    if (!connected) return;
    // البيانات بتتبعت جوه "data": Supabase بيحط "type" و "event" بتوعه فوق الرسالة،
    // فلو بعتنا البيانات على طول كانت "type": "draw" بتتمسح وتبقى "broadcast"
    // (ده كان سبب إن موبايلات اللاعيبة ماكانتش بتقدر تسحب)
    _channel?.sendBroadcastMessage(event: event, payload: {'data': payload});
  }

  /// بيطلّع بياناتنا من رسالة Supabase (أياً كان شكلها: مسطحة أو جوه payload)
  static Map<String, dynamic> unwrap(Map<String, dynamic> message) {
    final inner = message['payload'] is Map ? Map<String, dynamic>.from(message['payload'] as Map) : message;
    final data = inner['data'];
    return data is Map ? Map<String, dynamic>.from(data) : inner;
  }

  /// قفل القعدة
  Future<void> close() async {
    connected = false;
    final channel = _channel;
    _channel = null;
    if (channel != null) await Supabase.instance.client.removeChannel(channel);
  }
}
