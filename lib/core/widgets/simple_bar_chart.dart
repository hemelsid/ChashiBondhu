import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/bangla.dart';

/// Tiny offline bar chart (no package). Bangla numbers, big labels.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.height = 170,
    this.highlight,
  });

  final List<double> values;

  /// Short label under each bar (e.g. "১২/১০"). Only some are drawn.
  final List<String> labels;
  final Color color;
  final double height;

  /// Optional: colour per bar (e.g. red for many dead fish).
  final Color? Function(double value)? highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(values, labels, color, highlight),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.values, this.labels, this.color, this.highlight);

  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color? Function(double value)? highlight;

  static const _labelH = 24.0;
  static const _topH = 22.0;

  void _text(Canvas canvas, String s, Offset center, double size,
      {Color color = AppColors.textMuted, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: kAppFont,
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.fold<double>(0, max);
    final chartH = size.height - _labelH - _topH;
    final slot = size.width / values.length;
    final barW = min(28.0, slot * 0.65);

    // Base line
    final base = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2;
    final baseY = _topH + chartH;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), base);

    // Show at most ~6 labels so text never overlaps.
    final labelEvery = max(1, (values.length / 6).ceil());

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final h = maxV <= 0 ? 0.0 : (v / maxV) * chartH;
      final cx = slot * i + slot / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, baseY - max(h, v > 0 ? 3 : 0), barW,
            max(h, v > 0 ? 3 : 0)),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = highlight?.call(v) ?? color);

      final isLast = i == values.length - 1;
      if (v == maxV && maxV > 0 || isLast) {
        _text(canvas, Bn.number(v), Offset(cx, baseY - h - 11), 13,
            color: AppColors.textDark, bold: true);
      }
      if (i % labelEvery == 0 || isLast) {
        if (i < labels.length) {
          _text(canvas, labels[i], Offset(cx, baseY + _labelH / 2 + 2), 13);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.labels != labels || old.color != color;
}
