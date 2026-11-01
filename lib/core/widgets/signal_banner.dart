import 'package:flutter/material.dart';

import '../domain/signal.dart';
import '../theme/app_colors.dart';
import '../theme/signal_style.dart';

/// Big green / yellow / red result box.
class SignalBanner extends StatelessWidget {
  const SignalBanner({
    super.key,
    required this.signal,
    required this.title,
    this.subtitle,
  });

  final Signal signal;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: signal.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: signal.color, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: signal.color, shape: BoxShape.circle),
            child: Icon(signal.icon, color: signal.onColor, size: 42),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.label,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: signal.textColor)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(sub,
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured dot for lists.
class SignalDot extends StatelessWidget {
  const SignalDot(this.signal, {super.key, this.size = 16});

  final Signal signal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: signal.color, shape: BoxShape.circle),
    );
  }
}
