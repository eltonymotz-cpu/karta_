// رسايل Supabase Realtime: بياناتنا لازم توصل كاملة (من غير ما "type" و "event" يتمسحوا)
import 'package:flutter_test/flutter_test.dart';
import 'package:karta/services/room_service.dart';

void main() {
  test('our fields survive Supabase adding its own type/event keys', () {
    // ده الشكل اللي Supabase بيبعته فعلاً (اتجرب على المشروع الحقيقي بـ tool/room_probe.dart)
    final flat = {'event': 'action', 'type': 'broadcast', 'data': {'type': 'draw', 'player': 0, 'device': 'p1'}};
    expect(RoomService.unwrap(flat), {'type': 'draw', 'player': 0, 'device': 'p1'});

    // ولو جت جوه payload
    final nested = {
      'event': 'state',
      'payload': {'data': {'event': {'id': 3, 'kind': 'loss'}, 'screen': 'game'}},
    };
    expect(RoomService.unwrap(nested)['event'], {'id': 3, 'kind': 'loss'});
  });
}
