import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'choice_grid.dart';

/// Like [ChoiceGrid] but many tiles can be ticked (symptom checklist).
class MultiChoiceGrid<T> extends StatelessWidget {
  const MultiChoiceGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.columns = 2,
    this.tileHeight = 124,
  });

  final List<ChoiceOption<T>> options;
  final Set<T> selected;
  final ValueChanged<T> onToggle;
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
                child: _Tile<T>(
                  option: o,
                  selected: selected.contains(o.value),
                  onTap: () => onToggle(o.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile<T> extends StatelessWidget {
  const _Tile({required this.option, required this.selected, required this.onTap});

  final ChoiceOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = option.icon;
    return Material(
      color: selected ? AppColors.selectedBg : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 3.5 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, size: 46, color: option.iconColor ?? AppColors.primary)
                  else
                    Text(option.emoji ?? '', style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.15,
                        color: AppColors.textDark,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 30,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
