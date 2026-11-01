import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final i = icon;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          if (i != null) ...[
            Icon(i, size: 26, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(text, style: AppText.label)),
        ],
      ),
    );
  }
}
