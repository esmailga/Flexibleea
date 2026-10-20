import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme/app_theme.dart';
import '../features/listing/listing_details_screen.dart';
import '../models/expertise_listing.dart';
import 'app_avatar.dart';
import 'riyal.dart';
import 'skeleton.dart';

/// Feed card for a listing. Opens the details screen with a container
/// transform so the card visually expands into the page.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.showStatus = false,
    this.trailing,
  });

  final ExpertiseListing listing;
  final bool showStatus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 450),
      closedElevation: 0,
      openElevation: 0,
      closedColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      openColor: theme.scaffoldBackgroundColor,
      middleColor: theme.scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      openBuilder: (_, __) => ListingDetailsScreen(listingId: listing.id, initial: listing),
      closedBuilder: (_, open) => InkWell(
        onTap: open,
        child: _CardBody(listing: listing, showStatus: showStatus, trailing: trailing),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.listing, required this.showStatus, this.trailing});

  final ExpertiseListing listing;
  final bool showStatus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = listing.dateLabel;
    final time = listing.timeLabel(context);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(imageUrl: listing.ownerImage, name: listing.displayOwner, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.displayOwner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (listing.hourlyRate != null || listing.legacyRate.isNotEmpty)
                RateText(
                  listing: listing,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              listing.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (showStatus)
                InfoPill(
                  label: listing.isOpen ? 'Open' : 'Paused',
                  icon: listing.isOpen ? Icons.circle : Icons.pause_circle_filled_rounded,
                  color: listing.isOpen ? AppColors.success : scheme.outline,
                ),
              if (listing.category.isNotEmpty)
                InfoPill(label: listing.category, icon: iconForCategory(listing.category)),
              if (date.isNotEmpty)
                InfoPill(label: date, icon: Icons.event_rounded, color: AppColors.teal),
              if (time.isNotEmpty)
                InfoPill(label: time, icon: Icons.schedule_rounded, color: AppColors.amber),
            ],
          ),
        ],
      ),
    );
  }
}
