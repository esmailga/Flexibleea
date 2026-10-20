import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/expertise_listing.dart';
import '../../models/review.dart';
import '../../services/expertise_repository.dart';
import '../../services/session.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/star_rating.dart';
import '../profile/profile_screen.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.listing,
    required this.reviews,
    required this.loading,
    required this.average,
    required this.canWrite,
  });

  final ExpertiseListing listing;
  final List<Review> reviews;
  final bool loading;
  final double? average;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<Session>();
    final myUid = session.uid;
    final mine = reviews.where((r) => !r.isLegacy && r.authorId == myUid).firstOrNull;
    final canModerate = session.isAdmin || myUid == listing.ownerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Reviews',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (average != null) ...[
              StarRating(rating: average!, size: 18),
              const SizedBox(width: 6),
              Text(average!.toStringAsFixed(1),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (canWrite)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: OutlinedButton.icon(
              onPressed: () => showReviewComposer(context, listing: listing, existing: mine),
              icon: Icon(mine == null ? Icons.rate_review_outlined : Icons.edit_note_rounded),
              label: Text(mine == null ? 'Write a review' : 'Edit your review'),
            ),
          ),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (reviews.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.forum_outlined, size: 36, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('No reviews yet', style: theme.textTheme.titleSmall),
                  if (canWrite)
                    Text('Worked with ${listing.displayOwner}? Share how it went.',
                        textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          )
        else
          for (final (i, review) in reviews.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewTile(
                review: review,
                canDelete: !review.isLegacy && (review.authorId == myUid || canModerate),
                onDelete: () => _delete(context, review),
              )
                  .animate(key: ValueKey('${review.id}-${review.isLegacy}'))
                  .fadeIn(delay: (i < 6 ? i * 50 : 0).ms)
                  .slideX(begin: 0.05, end: 0),
            ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, Review review) async {
    final ok = await confirmAction(
      context,
      title: 'Delete review?',
      message: 'This review will be removed for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<ExpertiseRepository>().deleteReview(listing.id, review.authorId);
      if (context.mounted) showMessage(context, 'Review deleted');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.canDelete, required this.onDelete});

  final Review review;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = review.authorName.isEmpty ? 'Member' : review.authorName;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: review.authorId.isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: review.authorId))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(imageUrl: review.authorImage, name: name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (review.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(timeAgo(review.createdAt!), style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                    if (review.rating != null) ...[
                      const SizedBox(height: 2),
                      StarRating(rating: review.rating!.toDouble(), size: 15),
                    ],
                    const SizedBox(height: 6),
                    Text(review.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete review',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showReviewComposer(
  BuildContext context, {
  required ExpertiseListing listing,
  Review? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReviewComposer(listing: listing, existing: existing),
  );
}

class _ReviewComposer extends StatefulWidget {
  const _ReviewComposer({required this.listing, this.existing});

  final ExpertiseListing listing;
  final Review? existing;

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  final _formKey = GlobalKey<FormState>();
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  late int _rating = widget.existing?.rating ?? 5;
  bool _saving = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<Session>();
    final me = session.profile;
    if (me == null) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await context.read<ExpertiseRepository>().saveReview(
            widget.listing.id,
            Review(
              id: me.id,
              authorId: me.id,
              authorName: me.name,
              authorImage: me.imageUrl,
              body: _body.text.trim(),
              rating: _rating,
            ),
          );
      if (mounted) showMessage(context, 'Thanks for your review!');
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Rate ${widget.listing.displayOwner}' : 'Update your review',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLength: 500,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => Validators.minLength(v, 7, 'review'),
              decoration: const InputDecoration(
                hintText: 'What was it like working together?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            LoadingButton(label: 'Post review', icon: Icons.send_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
