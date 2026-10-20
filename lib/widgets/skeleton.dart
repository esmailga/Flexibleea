import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';

/// Shimmering placeholder cards shown while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.sliver = false});

  final int count;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    Widget item(int i) => const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: _SkeletonCard(),
        );
    if (sliver) {
      return SliverList.builder(itemCount: count, itemBuilder: (_, i) => item(i));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, i) => item(i),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final block = scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: block, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(double.infinity, 16),
                  const SizedBox(height: 10),
                  bar(120, 12),
                  const SizedBox(height: 14),
                  Row(children: [bar(80, 22), const SizedBox(width: 8), bar(64, 22)]),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1300.ms,
          color: scheme.surface.withValues(alpha: 0.6),
        );
  }
}

/// Rounded "pill" used for small facts like category or rate.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
