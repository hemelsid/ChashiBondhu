import 'package:flutter/material.dart';

import '../domain/fish_species.dart';
import '../theme/app_colors.dart';
import 'choice_grid.dart';

/// Fish type picker: 6 common fish first, "আরও মাছ" opens the rest,
/// and "অন্য মাছ" shows a box to type any name.
class SpeciesPicker extends StatefulWidget {
  const SpeciesPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.customName,
  });

  final FishSpecies? selected;
  final ValueChanged<FishSpecies> onSelected;

  /// Name box for "অন্য মাছ". When null, "অন্য মাছ" is not offered.
  final TextEditingController? customName;

  @override
  State<SpeciesPicker> createState() => _SpeciesPickerState();
}

class _SpeciesPickerState extends State<SpeciesPicker> {
  late bool _showMore = widget.selected != null && !FishSpecies.main.contains(widget.selected);

  @override
  Widget build(BuildContext context) {
    final custom = widget.customName;
    final list = [
      ...FishSpecies.main,
      if (_showMore)
        ...FishSpecies.more.where((s) => s != FishSpecies.other || custom != null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceGrid<FishSpecies>(
          options: [
            for (final s in list) ChoiceOption(value: s, label: s.label, emoji: s.emoji),
          ],
          selected: widget.selected,
          onSelected: widget.onSelected,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: TextButton.icon(
            onPressed: () => setState(() => _showMore = !_showMore),
            icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more, size: 30),
            label: Text(_showMore ? 'কম দেখান' : 'আরও মাছ (শিং, মাগুর, কৈ, পাবদা …)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        if (custom != null && widget.selected == FishSpecies.other) ...[
          const SizedBox(height: 4),
          TextField(
            controller: custom,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'মাছের নাম লিখুন (যেমন: টেংরা)',
              prefixIcon: Icon(Icons.edit, color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}
