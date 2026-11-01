import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The required safety note, always shown on disease results.
class DisclaimerBox extends StatelessWidget {
  const DisclaimerBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warn, width: 2.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.warnText, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warnText)),
          ),
        ],
      ),
    );
  }
}
