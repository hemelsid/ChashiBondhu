import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/big_number_field.dart';
import 'water_result_screen.dart';
import 'water_rules.dart';
import 'water_ui.dart';

/// Pani Check: enter whatever you measured (one or more), get a signal.
class WaterCheckScreen extends StatefulWidget {
  const WaterCheckScreen({super.key});

  @override
  State<WaterCheckScreen> createState() => _WaterCheckScreenState();
}

class _WaterCheckScreenState extends State<WaterCheckScreen> {
  final _controllers = {
    for (final p in WaterParam.values) p: TextEditingController(),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _check() {
    final values = <WaterParam, double>{};
    for (final p in WaterParam.values) {
      final text = _controllers[p]!.text;
      if (text.trim().isEmpty) continue;
      final v = Bn.parse(text);
      if (v == null || !WaterRules.isPlausible(p, v)) {
        setState(() => _error = '${p.label}: সংখ্যাটি ঠিক মনে হচ্ছে না। আবার দেখুন।');
        return;
      }
      values[p] = v;
    }
    if (values.isEmpty) {
      setState(() => _error = 'অন্তত একটি মাপ লিখুন।');
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();

    final report = WaterRules.check(
      ph: values[WaterParam.ph],
      oxygen: values[WaterParam.oxygen],
      ammonia: values[WaterParam.ammonia],
      temperature: values[WaterParam.temperature],
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WaterResultScreen(report: report),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('পানি চেক'),
        backgroundColor: AppColors.cardWater,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('যেটা মেপেছেন শুধু সেটাই লিখুন',
                style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
          ),
          for (final p in WaterParam.values)
            BigNumberField(
              controller: _controllers[p]!,
              label: p.label,
              icon: p.icon,
              unit: p.unit,
              helper: p.okRangeText,
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
            label: 'চেক করুন',
            icon: Icons.fact_check,
            color: AppColors.cardWater,
            onPressed: _check,
          ),
        ],
      ),
    );
  }
}
