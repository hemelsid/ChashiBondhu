import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Simple dialog with big buttons stacked at the bottom.
/// [buttons] are built with the dialog's own context so they can pop it.
Future<T?> showBigDialog<T>(
  BuildContext context, {
  Widget? icon,
  required Widget title,
  Widget? body,
  Color? background,
  required List<Widget> Function(BuildContext dialogContext) buttons,
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (dialogContext) => Dialog(
      backgroundColor: background ?? Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) Center(child: icon),
            if (icon != null) const SizedBox(height: 8),
            DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: title,
            ),
            if (body != null) ...[
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: body)),
            ],
            const SizedBox(height: 20),
            for (final b in buttons(dialogContext)) ...[
              b,
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Yes / no question. Returns true if confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'হ্যাঁ',
  String cancelLabel = 'না',
  Color confirmColor = AppColors.danger,
}) async {
  final result = await showBigDialog<bool>(
    context,
    title: Text(title,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    body: Text(message,
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
    buttons: (ctx) => [
      SizedBox(
        height: 60,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ),
      SizedBox(
        height: 60,
        child: OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
      ),
    ],
  );
  return result ?? false;
}
