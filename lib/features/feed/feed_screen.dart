import 'package:flutter/material.dart';

import '../../core/domain/fish_species.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/big_number_field.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/species_picker.dart';
import 'feed_calculator.dart';
import 'feed_result_screen.dart';

/// Khabar Hisab. Can be opened empty from Home, or pre-filled from a pond.
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    this.initialSpecies,
    this.initialCount,
    this.initialWeightG,
  });

  final FishSpecies? initialSpecies;
  final int? initialCount;
  final double? initialWeightG;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FishSpecies? _species;
  late final TextEditingController _count;
  late final TextEditingController _weight;
  String? _error;

  @override
  void initState() {
    super.initState();
    _species = widget.initialSpecies;
    final c = widget.initialCount;
    final w = widget.initialWeightG;
    _count = TextEditingController(text: c == null ? '' : Bn.digits(c));
    _weight = TextEditingController(
        text: w == null ? '' : Bn.number(w, maxDecimals: 1));
  }

  @override
  void dispose() {
    _count.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _calculate() {
    final species = _species;
    final count = Bn.parseInt(_count.text);
    final weight = Bn.parse(_weight.text);
    String? error;
    if (species == null) {
      error = 'মাছের জাত বেছে নিন।';
    } else if (count == null || count <= 0) {
      error = 'মাছের সংখ্যা লিখুন।';
    } else if (weight == null || weight <= 0) {
      error = 'মাছের গড় ওজন লিখুন।';
    } else if (weight > 5000) {
      error = 'ওজন গ্রামে লিখুন (যেমন ২৫০)।';
    }
    setState(() => _error = error);
    if (error != null) return;

    FocusScope.of(context).unfocus();
    final result = FeedCalculator.calculate(
        species: species!, count: count!, avgWeightG: weight!);
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FeedResultScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('খাবার হিসাব'),
        backgroundColor: AppColors.cardFeed,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('মাছের জাত', icon: Icons.set_meal),
          // "অন্য মাছ" uses the general fish feeding rate.
          SpeciesPicker(
            selected: _species,
            onSelected: (s) => setState(() => _species = s),
          ),
          BigNumberField(
            controller: _count,
            label: 'পুকুরে এখন কতটি মাছ',
            icon: Icons.numbers,
            unit: 'টি',
            decimal: false,
          ),
          BigNumberField(
            controller: _weight,
            label: 'একটি মাছের গড় ওজন',
            icon: Icons.scale,
            unit: 'গ্রাম',
            helper: 'কয়েকটি মাছ মেপে গড় করুন',
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
            label: 'হিসাব করুন',
            icon: Icons.calculate,
            color: AppColors.cardFeed,
            onPressed: _calculate,
          ),
        ],
      ),
    );
  }
}
