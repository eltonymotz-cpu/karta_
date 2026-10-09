// تجربة على Supabase الحقيقي: موبايلين (هوست + لاعب) على نفس القناة وبنفس شكل رسايل التطبيق.
// اللاعب بيبعت طلب سحب، والهوست لازم يستلمه كامل (type = draw). التشغيل: dart run tool/room_probe.dart
// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:async';
import 'package:supabase/supabase.dart';

const url = 'https://mimonvumevwapgtyhikg.supabase.co';
const key = 'sb_publishable_TwMofqSyfIoqatfPsyUOUw_8fPOyhxm';

Future<void> main() async {
  final code = 'PROBE${DateTime.now().millisecondsSinceEpoch % 100000}';
  final hostClient = SupabaseClient(url, key);
  final viewerClient = SupabaseClient(url, key);
  final gotAction = Completer<Map>();
  final gotState = Completer<Map>();
  final sw = Stopwatch()..start();

  final host = hostClient.channel('karta-room-$code');
  host.onBroadcast(event: 'action', callback: (m) {
    final data = (m['payload'] is Map ? m['payload'] : m)['data'];
    print('host got action data: $data');
    if (!gotAction.isCompleted) gotAction.complete(data as Map);
  });
  host.onBroadcast(event: 'hello', callback: (m) { print('host got hello ${sw.elapsedMilliseconds}ms'); host.sendBroadcastMessage(event: 'state', payload: {'x': 1}); });
  final hostReady = Completer();
  host.subscribe((s, e) { print('host status $s $e'); if (s == RealtimeSubscribeStatus.subscribed && !hostReady.isCompleted) hostReady.complete(); });
  await hostReady.future.timeout(const Duration(seconds: 15));

  final viewer = viewerClient.channel('karta-room-$code');
  viewer.onBroadcast(event: 'state', callback: (m) { print('viewer got state: $m'); if (!gotState.isCompleted) gotState.complete(m); });
  final viewerReady = Completer();
  viewer.subscribe((s, e) { print('viewer status $s $e'); if (s == RealtimeSubscribeStatus.subscribed && !viewerReady.isCompleted) viewerReady.complete(); });
  await viewerReady.future.timeout(const Duration(seconds: 15));
  viewer.sendBroadcastMessage(event: 'hello', payload: {});
  await gotState.future.timeout(const Duration(seconds: 10));
  final t0 = sw.elapsedMilliseconds;
  viewer.sendBroadcastMessage(event: 'action', payload: {'data': {'type': 'draw', 'player': 1, 'device': 'probe'}});
  final action = await gotAction.future.timeout(const Duration(seconds: 10));
  if (action['type'] != 'draw') throw StateError('type was overwritten: $action');
  print('action latency ${sw.elapsedMilliseconds - t0}ms');
  // الشات: اللاعب يبعت رسالة → الهوست يرجّعها للكل كحدث "chat" → اللاعب يستلمها
  final gotChat = Completer<Map>();
  viewer.onBroadcast(event: 'chat', callback: (m) {
    final data = (m['payload'] is Map ? m['payload'] : m)['data'];
    if (!gotChat.isCompleted) gotChat.complete(data as Map);
  });
  host.onBroadcast(event: 'action', callback: (m) {
    final data = (m['payload'] is Map ? m['payload'] : m)['data'] as Map;
    if (data['type'] == 'chat') {
      host.sendBroadcastMessage(event: 'chat', payload: {'data': {'id': data['id'], 'd': data['device'], 'n': 'Sara', 't': data['text'], 'c': 'lobby', 'at': 1}});
    }
  });
  final t1 = sw.elapsedMilliseconds;
  viewer.sendBroadcastMessage(event: 'action', payload: {'data': {'type': 'chat', 'id': 'probe-1', 'device': 'probe', 'text': 'أهلا 👋'}});
  final chat = await gotChat.future.timeout(const Duration(seconds: 10));
  if (chat['t'] != 'أهلا 👋' || chat['id'] != 'probe-1') throw StateError('chat corrupted: $chat');
  print('chat round trip ${sw.elapsedMilliseconds - t1}ms: $chat');
  await hostClient.removeAllChannels();
  await viewerClient.removeAllChannels();
  print('OK');
}
