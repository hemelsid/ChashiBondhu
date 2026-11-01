import 'package:flutter/material.dart';

import '../../../core/domain/signal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/signal_style.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/utils/ids.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/big_number_field.dart';
import '../../../core/widgets/choice_grid.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/section_title.dart';
import '../../feed/feed_calculator.dart';
import '../../water/water_check_screen.dart';
import '../data/observations.dart';
import '../data/pond_log.dart';
import '../data/pond_repository.dart';
import 'observation_ui.dart';

/// "30-second" daily entry. Everything is pre-filled from the last entry so
/// on a normal day the farmer only taps সংরক্ষণ.
class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key, required this.summary});

  final PondSummary summary;

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _date = DateTime.now();
  late final TextEditingController _feed;
  final TextEditingController _dead = TextEditingController(text: '০');
  final TextEditingController _note = TextEditingController();
  WaterColor? _waterColor;
  FishBehavior _behavior = FishBehavior.normal;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.summary;
    final last = s.lastLog;
    // Suggest yesterday's feed, or the calculator amount for a new pond.
    final suggestedFeed = last?.feedKg ??
        FeedCalculator.calculate(
          species: s.pond.species,
          count: s.currentStock,
          avgWeightG: s.pond.avgWeightG,
        ).dailyKg;
    _feed = TextEditingController(text: Bn.number(suggestedFeed, maxDecimals: 2));
    _waterColor = last?.waterColor ?? WaterColor.lightGreen;
  }

  @override
  void dispose() {
    _feed.dispose();
    _dead.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final feed = Bn.parse(_feed.text) ?? 0;
    final dead = _dead.text.trim().isEmpty ? 0 : Bn.parseInt(_dead.text);
    if (feed < 0 || feed > 10000) {
      setState(() => _error = 'খাবারের পরিমাণ ঠিক করে লিখুন।');
      return;
    }
    if (dead == null || dead < 0) {
      setState(() => _error = 'মরা মাছের সংখ্যা ঠিক করে লিখুন।');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });

    final now = DateTime.now();
    final log = PondLog(
      id: newId(),
      pondId: widget.summary.pond.id,
      date: Bn.dateOnly(_date),
      feedKg: feed,
      deadCount: dead,
      waterColor: _waterColor,
      behavior: _behavior,
      note: _note.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await PondRepository.instance.saveLog(log);
    if (!mounted) return;

    final stock = widget.summary.currentStock - dead;
    final signal = log.signalFor(stock);
    final navigator = Navigator.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আজকের হিসাব সংরক্ষণ হয়েছে ✓')),
    );

    if (signal == Signal.ok) {
      navigator.pop();
      return;
    }
    final goWater = await _showWarning(signal, log.tips(stock));
    if (!mounted) return;
    if (goWater) {
      navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const WaterCheckScreen()));
    } else {
      navigator.pop();
    }
  }

  Future<bool> _showWarning(Signal signal, List<String> tips) async {
    final result = await showBigDialog<bool>(
      context,
      dismissible: false,
      background: signal.background,
      icon: Icon(signal.icon, size: 60, color: signal.color),
      title: Text(signal.label,
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: signal.textColor)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(t, style: const TextStyle(fontSize: 18)),
            ),
        ],
      ),
      buttons: (ctx) => [
        BigButton(
          label: 'পানি চেক করুন',
          icon: Icons.water_drop,
          color: AppColors.cardWater,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
        BigButton(
          label: 'ঠিক আছে',
          icon: Icons.check,
          outlined: true,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.summary.pond.name),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          DateField(
            label: 'তারিখ',
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          BigNumberField(
            controller: _feed,
            label: 'আজ কত খাবার দিয়েছেন',
            icon: Icons.rice_bowl,
            unit: 'কেজি',
            step: 0.5,
          ),
          BigNumberField(
            controller: _dead,
            label: 'মরা মাছ কয়টি',
            icon: Icons.remove_circle_outline,
            unit: 'টি',
            step: 1,
            decimal: false,
          ),
          const SectionTitle('পানির রং', icon: Icons.palette),
          ChoiceGrid<WaterColor>(
            options: waterColorOptions(),
            selected: _waterColor,
            onSelected: (c) => setState(() => _waterColor = c),
          ),
          const SectionTitle('মাছের আচরণ', icon: Icons.visibility),
          ChoiceGrid<FishBehavior>(
            options: behaviorOptions(),
            selected: _behavior,
            onSelected: (b) => setState(() => _behavior = b),
          ),
          const SectionTitle('নোট (না লিখলেও চলবে)', icon: Icons.notes),
          TextField(
            controller: _note,
            maxLines: 2,
            style: const TextStyle(fontSize: 19),
            decoration: const InputDecoration(hintText: 'যেমন: চুন দিয়েছি'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error,
                  style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          BigButton(
            label: 'সংরক্ষণ করুন',
            icon: Icons.check,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
