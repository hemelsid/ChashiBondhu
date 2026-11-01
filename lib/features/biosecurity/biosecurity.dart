import '../../core/domain/signal.dart';

class BioItem {
  const BioItem(this.id, this.label, this.iconKey);

  final String id;
  final String label;
  final String iconKey;
}

/// The weekly checklist. Order = order on screen.
const List<BioItem> kBioItems = [
  BioItem('disinfect', 'জাল ও যন্ত্রপাতি জীবাণুমুক্ত করা', 'disinfect'),
  BioItem('quarantine', 'নতুন মাছ ৭ দিন আলাদা রাখা', 'quarantine'),
  BioItem('dead_fish', 'মরা মাছ সরিয়ে ফেলা', 'dead_fish'),
  BioItem('visitors', 'বাইরের লোক ঢোকা নিয়ন্ত্রণ', 'visitors'),
  BioItem('feed_dry', 'খাবার শুকনো জায়গায় রাখা', 'feed_dry'),
  BioItem('bank_clean', 'পুকুর পাড় পরিষ্কার', 'bank_clean'),
];

class BioRules {
  BioRules._();

  static int score(Set<String> ticked) {
    final done = kBioItems.where((i) => ticked.contains(i.id)).length;
    return (done * 100 / kBioItems.length).round();
  }

  /// 80+ green, 50–79 yellow, below 50 red.
  static Signal signal(int score) {
    if (score >= 80) return Signal.ok;
    if (score >= 50) return Signal.warn;
    return Signal.danger;
  }

  /// Week starts on Saturday (common in Bangladesh).
  static DateTime weekStart(DateTime d) {
    final back = (d.weekday - DateTime.saturday) % 7;
    return DateTime(d.year, d.month, d.day - back);
  }
}

class BioCheck {
  const BioCheck({
    required this.id,
    required this.weekStart,
    required this.ticked,
    required this.updatedAt,
  });

  final String id;
  final DateTime weekStart;
  final Set<String> ticked;
  final DateTime updatedAt;

  int get score => BioRules.score(ticked);

  Map<String, dynamic> toMap() => {
        'id': id,
        'weekStart': weekStart.millisecondsSinceEpoch,
        'ticked': ticked.toList(),
        'score': score,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory BioCheck.fromMap(Map<dynamic, dynamic> m) => BioCheck(
        id: m['id'] as String,
        weekStart: DateTime.fromMillisecondsSinceEpoch((m['weekStart'] as num).toInt()),
        ticked: {
          for (final t in (m['ticked'] as List<dynamic>? ?? const [])) t.toString()
        },
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (m['updatedAt'] as num?)?.toInt() ?? 0),
      );
}
