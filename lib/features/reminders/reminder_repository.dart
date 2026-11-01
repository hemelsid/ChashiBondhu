import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/storage/local_db.dart';
import '../../core/sync/sync_outbox.dart';
import 'reminder.dart';

class ReminderRepository {
  ReminderRepository._();

  static final ReminderRepository instance = ReminderRepository._();

  static const table = 'reminders';

  Box<dynamic> get _box => LocalDb.box(LocalDb.reminders);
  NotificationService get _notify => NotificationService.instance;

  ValueListenable<Box<dynamic>> get changes => _box.listenable();

  /// Not done first, then by time.
  List<Reminder> all() {
    final list = _box.values.whereType<Map>().map(Reminder.fromMap).toList();
    list.sort((a, b) {
      final d = (a.isDone() ? 1 : 0) - (b.isDone() ? 1 : 0);
      if (d != 0) return d;
      if (a.type.daily != b.type.daily) return a.type.daily ? -1 : 1;
      return a.dueAt.compareTo(b.dueAt);
    });
    return list;
  }

  String _title(Reminder r) => 'চাষিবন্ধু: ${r.type.label}';

  String _body(Reminder r) {
    final pond = r.pondName == null ? '' : '${r.pondName} — ';
    return switch (r.type) {
      ReminderType.feed => '$pondমাছকে খাবার দিন',
      ReminderType.lime => '$pondআজ চুন দেওয়ার দিন',
      ReminderType.net => '$pondআজ জাল টেনে মাছ দেখুন',
      ReminderType.harvest => '$pondমাছ ধরার সময় হয়েছে — ওজন দেখে নিন',
    };
  }

  Future<void> _schedule(Reminder r) => _notify.schedule(
        id: r.notificationId,
        title: _title(r),
        body: _body(r),
        when: r.dueAt,
        daily: r.type.daily,
      );

  /// Saves and schedules. Returns false if the alert could not be set
  /// (e.g. the time is already past).
  Future<bool> add(Reminder r) async {
    await _notify.requestPermission();
    await _box.put(r.id, r.toMap());
    await SyncOutbox.upsert(table, r.id);
    if (r.type.daily) {
      await _schedule(r);
      return true;
    }
    return _notify.schedule(
      id: r.notificationId,
      title: _title(r),
      body: _body(r),
      when: r.dueAt,
    );
  }

  Future<void> toggleDone(Reminder r) async {
    final Reminder next;
    if (r.type.daily) {
      next = r.isDone()
          ? r.copyWith(clearDoneDay: true)
          : r.copyWith(doneDay: dayKey(DateTime.now()));
      // Daily alert keeps running either way.
    } else {
      next = r.copyWith(done: !r.done);
      if (next.done) {
        await _notify.cancel(r.notificationId);
      } else {
        await _schedule(next);
      }
    }
    await _box.put(next.id, next.toMap());
    await SyncOutbox.upsert(table, next.id);
  }

  Future<void> delete(Reminder r) async {
    await _notify.cancel(r.notificationId);
    await _box.delete(r.id);
    await SyncOutbox.delete(table, r.id);
  }

  /// After "clear data" or reinstall: put alerts back for saved reminders.
  Future<void> rescheduleAll() async {
    for (final r in all()) {
      if (!r.type.daily && r.done) continue;
      await _schedule(r);
    }
  }
}
