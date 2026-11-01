import 'dart:math';

import '../../../core/domain/signal.dart';
import 'observations.dart';

/// One daily diary entry for a pond.
class PondLog {
  const PondLog({
    required this.id,
    required this.pondId,
    required this.date,
    required this.feedKg,
    required this.deadCount,
    this.waterColor,
    this.behavior,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String pondId;
  final DateTime date;
  final double feedKg;
  final int deadCount;
  final WaterColor? waterColor;
  final FishBehavior? behavior;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Worst of: water colour, fish behaviour, dead fish.
  Signal signalFor(int currentStock) {
    final color = waterColor;
    final beh = behavior;
    return Signal.worst([
      if (color != null) color.signal,
      if (beh != null) beh.signal,
      deadSignal(deadCount, currentStock),
    ]);
  }

  /// Any death = yellow. 10 fish or 1% of stock (whichever is more) = red.
  static Signal deadSignal(int dead, int stock) {
    if (dead <= 0) return Signal.ok;
    final limit = max(10, (stock * 0.01).round());
    return dead >= limit ? Signal.danger : Signal.warn;
  }

  /// Tips for anything that is not "ok", shown after saving.
  List<String> tips(int currentStock) {
    final color = waterColor;
    final beh = behavior;
    return [
      if (beh?.tip != null) beh!.tip!,
      if (color?.tip != null) color!.tip!,
      if (deadSignal(deadCount, currentStock) == Signal.danger)
        'অনেক মাছ মারা গেছে — মরা মাছ তুলে মাটিতে পুঁতে ফেলুন এবং পানি চেক করুন।',
    ];
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'pondId': pondId,
        'date': date.millisecondsSinceEpoch,
        'feedKg': feedKg,
        'deadCount': deadCount,
        'waterColor': waterColor?.name,
        'behavior': behavior?.name,
        'note': note,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory PondLog.fromMap(Map<dynamic, dynamic> m) {
    DateTime date(String key) =>
        DateTime.fromMillisecondsSinceEpoch((m[key] as num?)?.toInt() ?? 0);
    return PondLog(
      id: m['id'] as String,
      pondId: m['pondId'] as String,
      date: date('date'),
      feedKg: (m['feedKg'] as num?)?.toDouble() ?? 0,
      deadCount: (m['deadCount'] as num?)?.toInt() ?? 0,
      waterColor: WaterColor.fromKey(m['waterColor'] as String?),
      behavior: FishBehavior.fromKey(m['behavior'] as String?),
      note: (m['note'] as String?) ?? '',
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
    );
  }
}
