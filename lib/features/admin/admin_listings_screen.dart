import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/expertise_listing.dart';
import '../../services/expertise_repository.dart';
import '../../widgets/feedback.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/search_field.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  late Stream<List<ExpertiseListing>> _stream =
      context.read<ExpertiseRepository>().watchAll();
  String _query = '';
  final Set<String> _deleting = {};

  Future<void> _delete(ExpertiseListing listing) async {
    final ok = await confirmAction(
      context,
      title: 'Delete listing?',
      message: '"${listing.displayTitle}" by ${listing.displayOwner} and its reviews will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting.add(listing.id));
    try {
      await context.read<ExpertiseRepository>().delete(listing);
      if (mounted) showMessage(context, 'Listing deleted');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _deleting.remove(listing.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: SearchField(
            hint: 'Search listings',
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ExpertiseListing>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(
                  error: snapshot.error!,
                  onRetry: () => setState(
                      () => _stream = context.read<ExpertiseRepository>().watchAll()),
                );
              }
              if (!snapshot.hasData) return const SkeletonList();
              final listings = snapshot.data!.where((l) => l.matches(query: _query)).toList();
              if (listings.isEmpty) {
                return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No listings');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: listings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final listing = listings[i];
                  final deleting = _deleting.contains(listing.id);
                  return ListingCard(
                    listing: listing,
                    showStatus: true,
                    trailing: deleting
                        ? const SizedBox.square(
                            dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : IconButton(
                            tooltip: 'Delete listing',
                            onPressed: () => _delete(listing),
                            icon: Icon(Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error),
                          ),
                  )
                      .animate(key: ValueKey(listing.id))
                      .fadeIn(delay: (i < 8 ? i * 40 : 0).ms)
                      .slideY(begin: 0.08, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
