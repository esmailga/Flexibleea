import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Read-only star display supporting half stars.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppColors.amber,
          ),
      ],
    );
  }
}

/// Tappable 1-5 star picker with a little pop on selection.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i star${i == 1 ? '' : 's'}',
            onPressed: () => onChanged(i),
            icon: AnimatedScale(
              scale: i <= value ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 36,
                color: AppColors.amber,
              ),
            ),
          ),
      ],
    );
  }
}
