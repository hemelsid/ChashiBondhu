import 'package:flutter/material.dart';

import '../../core/data/bd_districts.dart';
import '../../core/storage/app_settings.dart';
import '../../core/sync/sync_outbox.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/choice_grid.dart';
import '../../core/widgets/section_title.dart';

/// Pick বিভাগ → জেলা → (optional) উপজেলা. Done once; change in Settings.
/// Pops with true when saved.
class DistrictPickerScreen extends StatefulWidget {
  const DistrictPickerScreen({super.key});

  @override
  State<DistrictPickerScreen> createState() => _DistrictPickerScreenState();
}

class _DistrictPickerScreenState extends State<DistrictPickerScreen> {
  String? _division;
  District? _district;
  late final TextEditingController _upazila =
      TextEditingController(text: AppSettings.upazila);

  @override
  void initState() {
    super.initState();
    final current = districtById(AppSettings.districtId);
    _division = current?.division;
    _district = current;
  }

  @override
  void dispose() {
    _upazila.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final d = _district;
    if (d == null) return;
    await AppSettings.setArea(d.id, _upazila.text);
    await SyncOutbox.upsert('users', 'me');
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final division = _division;
    final district = _district;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আপনার এলাকা'),
        backgroundColor: AppColors.cardWeather,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('বিভাগ', icon: Icons.map),
          ChoiceGrid<String>(
            columns: 2,
            tileHeight: 72,
            options: [
              for (final v in kDivisions)
                ChoiceOption(value: v, label: v, icon: Icons.location_city),
            ],
            selected: division,
            onSelected: (v) => setState(() {
              if (_division != v) _district = null;
              _division = v;
            }),
          ),
          if (division != null) ...[
            const SectionTitle('জেলা', icon: Icons.place),
            ChoiceGrid<District>(
              columns: 2,
              tileHeight: 72,
              options: [
                for (final d in kDistricts.where((d) => d.division == division))
                  ChoiceOption(value: d, label: d.name, icon: Icons.place),
              ],
              selected: district,
              onSelected: (d) => setState(() => _district = d),
            ),
          ],
          if (district != null) ...[
            const SectionTitle('উপজেলা (না লিখলেও চলবে)', icon: Icons.home_work),
            TextField(
              controller: _upazila,
              style: const TextStyle(fontSize: 21),
              decoration: const InputDecoration(hintText: 'যেমন: ত্রিশাল'),
            ),
            const SizedBox(height: 24),
            BigButton(
              label: 'সংরক্ষণ করুন',
              icon: Icons.check,
              color: AppColors.cardWeather,
              onPressed: _save,
            ),
          ],
        ],
      ),
    );
  }
}
