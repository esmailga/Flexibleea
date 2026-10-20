import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme/app_theme.dart';

/// Circular avatar with a cached network image and a gradient-initials
/// fallback for missing or broken URLs.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 48,
    this.ring = false,
  });

  final String imageUrl;
  final String name;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name, size: size);
    final image = imageUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          );

    final avatar = ClipOval(child: SizedBox.square(dimension: size, child: image));
    if (!ring) return avatar;
    return Container(
      padding: EdgeInsets.all(size * 0.04 + 1),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.heroGradient,
      ),
      child: Container(
        padding: EdgeInsets.all(size * 0.03 + 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: avatar,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
