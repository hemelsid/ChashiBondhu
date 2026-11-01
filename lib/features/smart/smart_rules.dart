import 'dart:math';

import '../../core/domain/signal.dart';
import '../../core/utils/bangla.dart';
import '../biosecurity/biosecurity.dart';
import '../disease/common/disease_matcher.dart';
import '../disease/common/disease_report.dart';
import '../feed/feed_calculator.dart';
import '../pond/data/pond.dart';
import '../pond/data/pond_log.dart';
import '../reminders/reminder.dart';
import '../weather/weather_models.dart';

/// Where the "do it" button on an insight takes the farmer.
enum InsightAction {
  dailyLog,
  waterCheck,
  feed,
  pondDetail,
  diseaseReport,
  weather,
  biosecurity,
  reminders,
}

/// One smart alert or tip ("আজকের কাজ"). Everything is decided offline from
/// the farmer's own records — no internet, no guessing beyond simple rules.
class Insight {
  const Insight({
    required this.signal,
    required this.title,
    required this.detail,
    required this.action,
    this.targetId,
  });

  /// danger / warn = needs action today; ok = a helpful tip.
  final Signal signal;
  final String title;
  final String detail;
  final InsightAction action;

  /// Pond id, report id … depending on [action].
  final String? targetId;
}

class PondSnapshot {
  const PondSnapshot({required this.pond, required this.logs, required this.currentStock});

  final Pond pond;

  /// Newest first.
  final List<PondLog> logs;
  final int currentStock;
}

class SmartInputs {
  const SmartInputs({
    required this.now,
    this.ponds = const [],
    this.reports = const [],
    this.reminders = const [],
    this.thisWeekBio,
    this.weatherTip,
  });

  final DateTime now;
  final List<PondSnapshot> ponds;
  final List<DiseaseReport> reports;
  final List<Reminder> reminders;
  final BioCheck? thisWeekBio;

  /// From the last saved forecast (null if none or too old).
  final WeatherTip? weatherTip;
}

class SmartRules {
  SmartRules._();

  /// After this hour a missing daily log becomes a reminder.
  static const logDueHour = 17;
  static const overfeedFactor = 1.3;
  static const weightStaleDays = 15;
  static const harvestSoonDays = 14;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<Insight> build(SmartInputs inp) {
    final out = <Insight>[];
    final today = _day(inp.now);

    for (final s in inp.ponds) {
      out.addAll(_pondInsights(s, inp.now, today));
    }

    // Disease check said "বেশি" in the last 3 days.
    for (final r in inp.reports) {
      if (today.difference(_day(r.date)).inDays > 2) continue;
      if (r.results.isEmpty || r.results.first.likelihood != Likelihood.high) continue;
      out.add(Insight(
        signal: Signal.warn,
        title: '${r.subject}: ${r.results.first.name} হতে পারে',
        detail: 'রোগ চেকে সম্ভাবনা বেশি এসেছে। পরামর্শ মেনে চলুন, অবস্থা খারাপ হলে অফিসারকে জানান।',
        action: InsightAction.diseaseReport,
        targetId: r.id,
      ));
    }

    // Weather ahead.
    final tip = inp.weatherTip;
    if (tip != null && tip.signal != Signal.ok) {
      out.add(Insight(
        signal: tip.signal,
        title: tip.title,
        detail: tip.text,
        action: InsightAction.weather,
      ));
    }

    // Biosecurity this week.
    final bio = inp.thisWeekBio;
    if (bio != null && bio.score < 50) {
      out.add(Insight(
        signal: Signal.warn,
        title: 'জীবাণু-নিরাপত্তা নম্বর কম (${Bn.digits(bio.score)})',
        detail: 'বাকি কাজগুলো এই সপ্তাহে করে টিক দিন। রোগ ঠেকাতে এগুলো জরুরি।',
        action: InsightAction.biosecurity,
      ));
    } else if (bio == null && inp.ponds.isNotEmpty && inp.now.weekday == DateTime.thursday) {
      out.add(const Insight(
        signal: Signal.ok,
        title: 'এই সপ্তাহের জীবাণু-নিরাপত্তা চেক',
        detail: 'সপ্তাহ শেষ হওয়ার আগে ৬টি কাজে টিক দিন।',
        action: InsightAction.biosecurity,
      ));
    }

    // Reminders due (useful on PC, where the phone alert does not ring).
    for (final r in inp.reminders) {
      if (r.isDone(now: inp.now)) continue;
      final dueToday = r.type.daily
          ? (inp.now.hour * 60 + inp.now.minute) >= (r.dueAt.hour * 60 + r.dueAt.minute)
          : !_day(r.dueAt).isAfter(today);
      if (!dueToday) continue;
      final overdue = !r.type.daily && _day(r.dueAt).isBefore(today);
      out.add(Insight(
        signal: Signal.warn,
        title: overdue ? '${r.type.label} — সময় পার হয়েছে' : r.type.label,
        detail: '${r.pondName == null ? '' : '${r.pondName}: '}কাজ হলে রিমাইন্ডারে টিক দিন।',
        action: InsightAction.reminders,
      ));
    }

    out.sort((a, b) => b.signal.index.compareTo(a.signal.index));
    return out;
  }

  static List<Insight> _pondInsights(PondSnapshot s, DateTime now, DateTime today) {
    final p = s.pond;
    final out = <Insight>[];
    final daysSinceStock = today.difference(_day(p.stockDate)).inDays;

    // 1. Daily log missing.
    final lastLogDay = s.logs.isEmpty ? null : _day(s.logs.first.date);
    final gap = lastLogDay == null ? null : today.difference(lastLogDay).inDays;
    if ((gap == null && daysSinceStock >= 1) || (gap != null && gap >= 3)) {
      out.add(Insight(
        signal: Signal.warn,
        title: '${p.name}: কয়েক দিন হিসাব লেখা হয়নি',
        detail: 'প্রতিদিন খাবার ও মরা মাছ লিখলে সমস্যা আগে ধরা পড়ে।',
        action: InsightAction.dailyLog,
        targetId: p.id,
      ));
    } else if (gap != null && gap >= 1 && now.hour >= logDueHour) {
      out.add(Insight(
        signal: Signal.ok,
        title: '${p.name}: আজকের হিসাব লিখুন',
        detail: '৩০ সেকেন্ডের কাজ — খাবার আগে থেকেই বসানো থাকে।',
        action: InsightAction.dailyLog,
        targetId: p.id,
      ));
    }

    // 2. Dead fish rising: last 3 days vs the 3 days before.
    final deadByDay = <DateTime, int>{};
    for (final l in s.logs) {
      final d = _day(l.date);
      deadByDay[d] = (deadByDay[d] ?? 0) + l.deadCount;
    }
    int sumDays(int from, int to) {
      var t = 0;
      for (var i = from; i <= to; i++) {
        t += deadByDay[DateTime(today.year, today.month, today.day - i)] ?? 0;
      }
      return t;
    }

    final last3 = sumDays(0, 2);
    final prev3 = sumDays(3, 5);
    final dangerLimit = max(30, (s.currentStock * 0.01).round());
    if (last3 >= dangerLimit) {
      out.add(Insight(
        signal: Signal.danger,
        title: '${p.name}: অনেক মাছ মারা যাচ্ছে',
        detail: 'গত ৩ দিনে ${Bn.count(last3)}টি মাছ মারা গেছে। এখনই পানি চেক করুন, '
            'রোগ চেক করুন এবং অফিসারকে জানান।',
        action: InsightAction.waterCheck,
        targetId: p.id,
      ));
    } else if (last3 >= 5 && last3 > prev3 * 1.5) {
      out.add(Insight(
        signal: Signal.warn,
        title: '${p.name}: মরা মাছ বাড়ছে',
        detail: 'গত ৩ দিনে ${Bn.count(last3)}টি, আগের ৩ দিনে ${Bn.count(prev3)}টি। '
            'পানি চেক করুন, খাবার কমান।',
        action: InsightAction.waterCheck,
        targetId: p.id,
      ));
    }

    // 3. Over-feeding compared with the calculator.
    if (s.logs.isNotEmpty && s.currentStock > 0 && p.avgWeightG > 0) {
      final last = s.logs.first;
      final need = FeedCalculator.calculate(
        species: p.species,
        count: s.currentStock,
        avgWeightG: p.avgWeightG,
      ).dailyKg;
      if (need > 0 && last.feedKg > need * overfeedFactor && today.difference(_day(last.date)).inDays <= 1) {
        out.add(Insight(
          signal: Signal.warn,
          title: '${p.name}: খাবার বেশি দিচ্ছেন',
          detail: 'শেষবার ${Bn.weight(last.feedKg)} দিয়েছেন, হিসাবমতো ${Bn.weight(need)} যথেষ্ট। '
              'বেশি খাবার পানি নষ্ট করে। মাছ বড় হলে পুকুরের তথ্যে গড় ওজন বদলান।',
          action: InsightAction.feed,
          targetId: p.id,
        ));
      }
    }

    // 4. Average weight not updated for a while → feed amount gets wrong.
    final sinceUpdate = today.difference(_day(p.updatedAt)).inDays;
    if (daysSinceStock > weightStaleDays && sinceUpdate > weightStaleDays) {
      out.add(Insight(
        signal: Signal.ok,
        title: '${p.name}: মাছ মেপে ওজন বদলান',
        detail: '${Bn.digits(sinceUpdate)} দিন ওজন বদলানো হয়নি। কয়েকটা মাছ মেপে গড় ওজন লিখলে '
            'খাবারের হিসাব ঠিক থাকবে।',
        action: InsightAction.pondDetail,
        targetId: p.id,
      ));
    }

    // 5. Harvest time getting close.
    final cultureDays = kCultureDays[p.species] ?? 180;
    final harvest = DateTime(p.stockDate.year, p.stockDate.month, p.stockDate.day + cultureDays);
    final toHarvest = _day(harvest).difference(today).inDays;
    if (toHarvest <= harvestSoonDays && toHarvest >= -30) {
      out.add(Insight(
        signal: Signal.ok,
        title: '${p.name}: মাছ ধরার সময় কাছে',
        detail: toHarvest > 0
            ? 'আনুমানিক ${Bn.digits(toHarvest)} দিন বাকি (${Bn.date(harvest)})। বাজার দর দেখে ঠিক করুন।'
            : 'আনুমানিক সময় হয়ে গেছে। কয়েকটা মাছ মেপে ও বাজার দর দেখে ঠিক করুন।',
        action: InsightAction.pondDetail,
        targetId: p.id,
      ));
    }
    return out;
  }
}
