// =================================================================
// النماذج: الكارت واللاعب
// =================================================================
import 'package:flutter/material.dart';

/// كارت واحد من الكوتشينة
class PlayingCard {
  final String rank; // القيمة: A, K, Q, J, 10 ... 2
  final String suit; // الشكل: ♠ ♥ ♦ ♣
  const PlayingCard(this.rank, this.suit);

  /// يعمل كارت من نصه، مثلاً "10♥" → القيمة 10 والشكل ♥
  factory PlayingCard.fromLabel(String label) =>
      PlayingCard(label.substring(0, label.length - 1), label.substring(label.length - 1));

  /// هل الكارت أحمر؟ (قلب أو ديناري)
  bool get isRed => suit == '♥' || suit == '♦';

  /// نص الكارت مثل "K♠"
  String get label => '$rank$suit';
}

/// لاعب
class Player {
  final String name;
  final Color color;                         // لونه المميز في المقعد
  final List<PlayingCard> cards = [];        // الكروت (العقوبات) اللي أخدها
  Player(this.name, this.color);
}
