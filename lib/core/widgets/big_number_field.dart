import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/bangla.dart';
import 'section_title.dart';

/// Shows typed digits as Bangla digits (০-৯). Bangla digits are one UTF-16
/// unit each, so the cursor position stays correct.
class BanglaDigitFormatter extends TextInputFormatter {
  const BanglaDigitFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: Bn.digits(newValue.text));
  }
}

/// Big number input with label, unit and optional − / + buttons so the
/// farmer can adjust without typing.
class BigNumberField extends StatelessWidget {
  const BigNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.icon,
    this.step,
    this.decimal = true,
    this.hint,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final IconData? icon;
  final double? step;
  final bool decimal;
  final String? hint;
  final String? helper;

  void _bump(int direction) {
    final s = step ?? 1;
    final current = Bn.parse(controller.text) ?? 0;
    var next = current + direction * s;
    if (next < 0) next = 0;
    final text = Bn.number(next, maxDecimals: decimal ? 2 : 0);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9০-৯.]' : r'[0-9০-৯]')),
        const BanglaDigitFormatter(),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: unit,
        suffixStyle: const TextStyle(fontSize: 18, color: AppColors.textMuted),
      ),
    );

    final h = helper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label, icon: icon),
        if (step == null)
          field
        else
          Row(
            children: [
              _StepButton(icon: Icons.remove, onTap: () => _bump(-1)),
              const SizedBox(width: 8),
              Expanded(child: field),
              const SizedBox(width: 8),
              _StepButton(icon: Icons.add, onTap: () => _bump(1)),
            ],
          ),
        if (h != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(h,
                style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Icon(icon, size: 34),
      ),
    );
  }
}
