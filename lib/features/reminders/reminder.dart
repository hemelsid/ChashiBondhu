import '../../core/domain/fish_species.dart';

enum ReminderType {
  feed('খাবার দেওয়ার সময়', daily: true),
  lime('চুন দেওয়ার দিন'),
  net('জাল টানা'),
  harvest('মাছ ধরার আনুমানিক দিন');

  const ReminderType(this.label, {this.daily = false});

  final String label;

  /// Feed time repeats every day; the others are one date.
  final bool daily;

  static ReminderType fromKey(String? key) {
    for (final t in values) {
      if (t.name == key) return t;
    }
    return ReminderType.feed;
  }
}

/// Typical days from stocking to harvest. A rough guide only.
const Map<FishSpecies, int> kCultureDays = {
  FishSpecies.pangas: 180,
  FishSpecies.tilapia: 120,
  FishSpecies.rui: 300,
  FishSpecies.katla: 300,
  FishSpecies.mrigel: 300,
  FishSpecies.chingri: 150,
  FishSpecies.shing: 180,
  FishSpecies.magur: 180,
  FishSpecies.koi: 120,
  FishSpecies.pabda: 180,
  FishSpecies.gulsha: 180,
  FishSpecies.sharpunti: 150,
  FishSpecies.silverCarp: 300,
  FishSpecies.grassCarp: 300,
  FishSpecies.commonCarp: 300,
  FishSpecies.bighead: 300,
  FishSpecies.kalibaus: 300,
};

DateTime estimateHarvest(FishSpecies species, DateTime stockDate, {DateTime? now}) {
  // Calendar arithmetic (not Duration) so the day never shifts.
  final days = kCultureDays[species] ?? 180;
  final est = DateTime(stockDate.year, stockDate.month, stockDate.day + days);
  final today = now ?? DateTime.now();
  // Already past → suggest a week from now.
  return est.isAfter(today) ? est : DateTime(today.year, today.month, today.day + 7);
}

int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    this.pondId,
    this.pondName,
    required this.dueAt,
    required this.notificationId,
    this.done = false,
    this.doneDay,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ReminderType type;
  final String? pondId;
  final String? pondName;

  /// For daily reminders only the time matters.
  final DateTime dueAt;
  final int notificationId;

  /// One-time reminders.
  final bool done;

  /// Daily reminders: the day it was last ticked (yyyymmdd).
  final int? doneDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isDone({DateTime? now}) =>
      type.daily ? doneDay == dayKey(now ?? DateTime.now()) : done;

  Reminder copyWith({bool? done, int? doneDay, bool clearDoneDay = false}) => Reminder(
        id: id,
        type: type,
        pondId: pondId,
        pondName: pondName,
        dueAt: dueAt,
        notificationId: notificationId,
        done: done ?? this.done,
        doneDay: clearDoneDay ? null : (doneDay ?? this.doneDay),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'pondId': pondId,
        'pondName': pondName,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'notificationId': notificationId,
        'done': done,
        'doneDay': doneDay,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Reminder.fromMap(Map<dynamic, dynamic> m) {
    DateTime date(String key) =>
        DateTime.fromMillisecondsSinceEpoch((m[key] as num?)?.toInt() ?? 0);
    return Reminder(
      id: m['id'] as String,
      type: ReminderType.fromKey(m['type'] as String?),
      pondId: m['pondId'] as String?,
      pondName: m['pondName'] as String?,
      dueAt: date('dueAt'),
      notificationId: (m['notificationId'] as num?)?.toInt() ?? 0,
      done: m['done'] == true,
      doneDay: (m['doneDay'] as num?)?.toInt(),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
    );
  }
}
