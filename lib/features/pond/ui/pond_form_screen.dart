import 'package:flutter/material.dart';

import '../../../core/domain/fish_species.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/utils/ids.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/big_number_field.dart';
import '../../../core/widgets/choice_grid.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/section_title.dart';
import '../data/pond.dart';
import '../data/pond_repository.dart';

/// Add a new pond, or edit one when [existing] is given.
class PondFormScreen extends StatefulWidget {
  const PondFormScreen({super.key, this.existing});

  final Pond? existing;

  @override
  State<PondFormScreen> createState() => _PondFormScreenState();
}

class _PondFormScreenState extends State<PondFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _count;
  late final TextEditingController _weight;
  FishSpecies? _species;
  late DateTime _stockDate;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _area = TextEditingController(
        text: p == null ? '' : Bn.number(p.areaShotok, maxDecimals: 2));
    _count = TextEditingController(text: p == null ? '' : Bn.digits(p.stockCount));
    _weight = TextEditingController(
        text: p == null ? '' : Bn.number(p.avgWeightG, maxDecimals: 1));
    _species = p?.species;
    _stockDate = p?.stockDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _count.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final area = Bn.parse(_area.text);
    final count = Bn.parseInt(_count.text);
    final weight = Bn.parse(_weight.text);
    final species = _species;

    String? error;
    if (name.isEmpty) {
      error = 'পুকুরের নাম লিখুন।';
    } else if (area == null || area <= 0) {
      error = 'পুকুরের আয়তন (শতক) লিখুন।';
    } else if (species == null) {
      error = 'মাছের জাত বেছে নিন।';
    } else if (count == null || count <= 0) {
      error = 'কতটি মাছ ছেড়েছেন লিখুন।';
    } else if (weight == null || weight <= 0) {
      error = 'মাছের গড় ওজন (গ্রাম) লিখুন।';
    }
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.existing;
    final pond = old == null
        ? Pond(
            id: newId(),
            name: name,
            areaShotok: area!,
            species: species!,
            stockCount: count!,
            stockDate: _stockDate,
            avgWeightG: weight!,
            createdAt: now,
            updatedAt: now,
          )
        : old.copyWith(
            name: name,
            areaShotok: area,
            species: species,
            stockCount: count,
            stockDate: _stockDate,
            avgWeightG: weight,
          );
    await PondRepository.instance.savePond(pond);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পুকুর সংরক্ষণ হয়েছে ✓')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'পুকুর বদলান' : 'নতুন পুকুর'),
        backgroundColor: AppColors.cardPond,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('পুকুরের নাম', icon: Icons.edit),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: 'যেমন: বাড়ির পুকুর'),
          ),
          BigNumberField(
            controller: _area,
            label: 'আয়তন',
            icon: Icons.square_foot,
            unit: 'শতক',
          ),
          const SectionTitle('মাছের জাত', icon: Icons.set_meal),
          ChoiceGrid<FishSpecies>(
            options: [
              for (final s in FishSpecies.values)
                ChoiceOption(value: s, label: s.label, emoji: s.emoji),
            ],
            selected: _species,
            onSelected: (s) => setState(() => _species = s),
          ),
          BigNumberField(
            controller: _count,
            label: 'মজুদ সংখ্যা (কতটি ছেড়েছেন)',
            icon: Icons.numbers,
            unit: 'টি',
            decimal: false,
          ),
          DateField(
            label: 'ছাড়ার তারিখ',
            value: _stockDate,
            onChanged: (d) => setState(() => _stockDate = d),
          ),
          BigNumberField(
            controller: _weight,
            label: 'একটি মাছের গড় ওজন',
            icon: Icons.scale,
            unit: 'গ্রাম',
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
            color: AppColors.cardPond,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
