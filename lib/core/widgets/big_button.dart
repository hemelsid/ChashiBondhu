import 'package:flutter/material.dart';

/// Full-width, 66 px tall button with icon. Easy to hit with a thumb.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
    );
    final iconWidget = Icon(icon, size: 30);
    final c = color;

    final Widget button = outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: iconWidget,
            label: text,
            style: c == null
                ? null
                : OutlinedButton.styleFrom(
                    foregroundColor: c,
                    side: BorderSide(color: c, width: 2),
                  ),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: iconWidget,
            label: text,
            style: c == null ? null : FilledButton.styleFrom(backgroundColor: c),
          );

    return SizedBox(width: double.infinity, height: 66, child: button);
  }
}
