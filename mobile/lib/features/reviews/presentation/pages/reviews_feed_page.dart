import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/review.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';

class ReviewsFeedPage extends StatefulWidget {
  const ReviewsFeedPage({Key? key}) : super(key: key);

  @override
  State<ReviewsFeedPage> createState() => _ReviewsFeedPageState();
}

class _ReviewsFeedPageState extends State<ReviewsFeedPage> {
  late final ReviewsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ReviewsBloc>()..add(FetchRecentReviewsRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baraqah Verified Reviews'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _bloc.add(FetchRecentReviewsRequested());
          },
          child: BlocBuilder<ReviewsBloc, ReviewsState>(
            builder: (context, state) {
              if (state is ReviewsLoading) {
                return const Center(child: LoadingIndicator());
              }
              if (state is ReviewsFailure) {
                return Center(child: ErrorCard(message: state.message));
              }
              if (state is RecentReviewsLoadSuccess) {
                final reviews = state.reviews;
                if (reviews.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No verified reviews yet. Go out and eat!')),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return _ReviewItem(review: reviews[index]);
                  },
                );
              }
              return const Center(child: Text('Pull to refresh reviews'));
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = review.createdAt != null
        ? DateFormat.yMMMd().format(review.createdAt!.toLocal())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    review.authorName != null && review.authorName!.isNotEmpty
                        ? review.authorName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName ?? 'Anonymous User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 14, color: AppColors.accent),
                                const SizedBox(width: 3),
                                Text(
                                  'Baraqah: ${(review.authorScore ?? 5.0).toStringAsFixed(1)} / 7.0',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.restaurantName ?? 'Unknown Restaurant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${review.ratingOverall}/10',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.reviewText,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
