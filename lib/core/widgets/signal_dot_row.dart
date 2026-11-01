import 'package:flutter/material.dart';

import '../domain/signal.dart';
import 'signal_banner.dart';

/// Small history row: coloured dot, label, value.
class SignalDotRow extends StatelessWidget {
  const SignalDotRow({
    super.key,
    required this.signal,
    required this.label,
    required this.value,
  });

  final Signal signal;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SignalDot(signal, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
