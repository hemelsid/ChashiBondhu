import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.label,
    this.emoji,
    this.icon,
    this.iconColor,
    this.swatch,
  });

  final T value;
  final String label;

  /// One of these is shown above the label: [swatch] colour circle,
  /// [icon], or [emoji]. (Photos can be added here later.)
  final String? emoji;
  final IconData? icon;
  final Color? iconColor;
  final Color? swatch;
}

/// Big tap tiles instead of dropdowns: picture + short word.
class ChoiceGrid<T> extends StatelessWidget {
  const ChoiceGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.columns = 3,
    this.tileHeight = 112,
  });

  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final int columns;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width =
            ((constraints.maxWidth - gap * (columns - 1)) / columns).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final o in options)
              SizedBox(
                width: width,
                height: tileHeight,
                child: _ChoiceTile<T>(
                  option: o,
                  selected: o.value == selected,
                  onTap: () => onSelected(o.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = option.swatch;
    final icon = option.icon;
    final Widget visual;
    if (swatch != null) {
      visual = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: swatch,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26, width: 2),
        ),
      );
    } else if (icon != null) {
      visual = Icon(icon, size: 40, color: option.iconColor ?? AppColors.primary);
    } else {
      visual = Text(option.emoji ?? '', style: const TextStyle(fontSize: 34));
    }

    return Material(
      color: selected ? AppColors.selectedBg : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 3 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  visual,
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.15,
                        color: AppColors.textDark,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}
