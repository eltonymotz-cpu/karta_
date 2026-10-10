// =================================================================
// الشات (في الانتظار وأثناء اللعب)
// -----------------------------------------------------------------
// الرسايل بتعدي على موبايل الهوست، وهو اللي بيقرر يقبلها ولا لأ:
//   - الطول (مفيش رسالة فاضية أو أطول من الحد)
//   - السرعة (أقصى عدد رسايل في الدقيقة لكل موبايل)
//   - الموبايل مش مكتوم ومش مطرود
//   - نفس الرسالة مابتتكررش لو اتبعتت مرتين (كل رسالة ليها id)
// الهوست بيبعت الرسالة المقبولة لكل اللي في القعدة، وبيحتفظ بآخر 80 رسالة
// فاللي يفصل ويرجع بيلاقي الكلام القديم.
// ⚠️ مفيش أي حاجة من الشات بتتحفظ: الرسايل في ذاكرة الموبايلات بس،
//    وبتتمسح أول ما اللعبة تتقفل.
// =================================================================
/// مكان الرسالة: lobby = في الانتظار قبل اللعب، game = أثناء اللعب
enum ChatContext { lobby, game }

class ChatMessage {
  final String id;          // رقم مميز بيعمله اللي بعت (لمنع التكرار)
  final String device;      // الموبايل اللي بعت
  final String name;        // اسم اللي بعت
  final String text;        // الكلام (فاضي لو رسالة صوتية بس)
  final ChatContext context;
  final int at;             // وقت القبول بساعة الهوست
  final bool fromHost;

  const ChatMessage({
    required this.id,
    required this.device,
    required this.name,
    required this.text,
    required this.context,
    required this.at,
    this.fromHost = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'd': device,
        'n': name,
        if (text.isNotEmpty) 't': text,
        'c': context.name,
        'at': at,
        if (fromHost) 'h': true,
      };

  static ChatMessage? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], device = json['d'], name = json['n'], at = json['at'];
    if (id is! String || device is! String || name is! String || at is! num) return null;
    return ChatMessage(
      id: id,
      device: device,
      name: name,
      text: json['t'] is String ? json['t'] as String : '',
      context: json['c'] == 'game' ? ChatContext.game : ChatContext.lobby,
      at: at.toInt(),
      fromHost: json['h'] == true,
    );
  }
}

/// سبب رفض رسالة (بيرجع للي بعتها عشان يعرف)
enum ChatRejection { disabled, empty, tooLong, tooFast, muted, invalid }

/// منطق الشات عند الهوست (من غير أي واجهة، عشان يتختبر لوحده)
class ChatRoom {
  static const historySize = 80;
  static const nameMax = 24;

  final List<ChatMessage> messages = [];
  final Set<String> muted = {};            // موبايلات مكتومة
  final Map<String, List<int>> _sent = {}; // أوقات آخر رسايل كل موبايل (للسرعة)
  final Set<String> _seenIds = {};

  /// الهوست بيستقبل رسالة. بيرجع null لو اتقبلت، أو سبب الرفض.
  /// الرسالة المكررة (نفس id) بترجع null من غير ما تتضاف تاني.
  ChatRejection? accept({
    required String id,
    required String device,
    required String name,
    required String text,
    required ChatContext context,
    required int now,
    required bool enabled,
    required int maxLength,
    required int perMinute,
    bool fromHost = false,
  }) {
    if (!enabled) return ChatRejection.disabled;
    if (id.isEmpty || id.length > 40 || device.isEmpty) return ChatRejection.invalid;
    if (_seenIds.contains(id)) return null; // اتبعتت قبل كده (إعادة إرسال): خلاص اتقبلت
    if (!fromHost && muted.contains(device)) return ChatRejection.muted;
    final clean = text.trim();
    if (clean.isEmpty) return ChatRejection.empty;
    if (clean.length > maxLength) return ChatRejection.tooLong;

    // السرعة: آخر دقيقة بس
    final times = _sent.putIfAbsent(device, () => []);
    times.removeWhere((t) => now - t > 60000);
    if (!fromHost && times.length >= perMinute) return ChatRejection.tooFast;
    times.add(now);

    final cleanName = name.trim().isEmpty ? '?' : name.trim();
    _seenIds.add(id);
    messages.add(ChatMessage(
      id: id,
      device: device,
      name: cleanName.length > nameMax ? cleanName.substring(0, nameMax) : cleanName,
      text: clean,
      context: context,
      at: now,
      fromHost: fromHost,
    ));
    if (messages.length > historySize) messages.removeRange(0, messages.length - historySize);
    return null;
  }

  /// مسح رسالة: صاحبها أو الهوست بس
  bool delete(String id, {required String byDevice, required bool byHost}) {
    final index = messages.indexWhere((m) => m.id == id);
    if (index < 0) return false;
    if (!byHost && messages[index].device != byDevice) return false;
    messages.removeAt(index);
    return true;
  }

  void clear() {
    messages.clear();
    muted.clear();
    _sent.clear();
    _seenIds.clear();
  }
}
