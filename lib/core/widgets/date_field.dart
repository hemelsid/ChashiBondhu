import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/bangla.dart';
import 'section_title.dart';

/// Shows a date as "আজ" / "গতকাল" / "১ নভেম্বর ২০২৬"; tap to change.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isAfter(now) ? now : value,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: label,
      cancelText: 'বাতিল',
      confirmText: 'ঠিক আছে',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label, icon: Icons.calendar_month),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            onPressed: () => _pick(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Bn.relativeDate(value),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ),
                const Text('বদলান',
                    style: TextStyle(fontSize: 17, color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
