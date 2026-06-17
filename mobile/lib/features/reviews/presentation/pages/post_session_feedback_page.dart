import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../di/injection.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';
import '../../../sessions/domain/entities/session.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';

class PostSessionFeedbackPage extends StatefulWidget {
  final String sessionId;
  final String restaurantId;
  final String restaurantName;
  final List<SessionAttendee> attendeesToReview;

  const PostSessionFeedbackPage({
    Key? key,
    required this.sessionId,
    required this.restaurantId,
    required this.restaurantName,
    required this.attendeesToReview,
  }) : super(key: key);

  @override
  State<PostSessionFeedbackPage> createState() => _PostSessionFeedbackPageState();
}

class _PostSessionFeedbackPageState extends State<PostSessionFeedbackPage> {
  late final ReviewsBloc _bloc;
  int _currentStep = 0; // 0: Restaurant review, 1: Participant reviews

  // Step 1: Restaurant rating states
  int _foodRating = 8; // Default to 8/10
  final TextEditingController _restaurantFeedbackController = TextEditingController();

  // Step 2: Participant reviews states
  int _currentParticipantIndex = 0;
  int _participantRating = 5; // Default to 5/7 stars
  final TextEditingController _participantFeedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ReviewsBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    _restaurantFeedbackController.dispose();
    _participantFeedbackController.dispose();
    super.dispose();
  }

  void _submitRestaurantReview() {
    _bloc.add(SubmitReviewRequested(
      sessionId: widget.sessionId,
      restaurantId: widget.restaurantId,
      ratingOverall: _foodRating,
      reviewText: _restaurantFeedbackController.text.trim(),
    ));
  }

  void _skipRestaurantReview() {
    _goToNextStep();
  }

  void _submitParticipantReview() {
    if (widget.attendeesToReview.isEmpty) return;
    final targetUser = widget.attendeesToReview[_currentParticipantIndex];
    _bloc.add(SubmitUserReviewRequested(
      sessionId: widget.sessionId,
      targetUserId: targetUser.userId,
      rating: _participantRating,
      reviewText: _participantFeedbackController.text.trim(),
    ));
  }

  void _skipParticipantReview() {
    _goToNextParticipantOrFinish();
  }

  void _goToNextStep() {
    setState(() {
      _currentStep = 1;
      _currentParticipantIndex = 0;
      _participantRating = 5;
      _participantFeedbackController.clear();
    });
  }

  void _goToNextParticipantOrFinish() {
    if (widget.attendeesToReview.isNotEmpty &&
        _currentParticipantIndex < widget.attendeesToReview.length - 1) {
      setState(() {
        _currentParticipantIndex++;
        _participantRating = 5;
        _participantFeedbackController.clear();
      });
    } else {
      _finishFeedback();
    }
  }

  void _finishFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      MainNavigationPage.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentStep == 0 ? 'Food Review' : 'Rate Participants'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Prevent backing out mid-review
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<ReviewsBloc, ReviewsState>(
            listener: (context, state) {
              if (state is ReviewsFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.message}')),
                );
              } else if (state is ReviewsSuccess) {
                if (_currentStep == 0) {
                  _goToNextStep();
                } else {
                  _goToNextParticipantOrFinish();
                }
              }
            },
            builder: (context, state) {
              if (state is ReviewsLoading) {
                return const Center(child: LoadingIndicator());
              }
              return _currentStep == 0
                  ? _buildRestaurantReviewStep()
                  : _buildParticipantReviewStep();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'How was the food at ${widget.restaurantName}?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Help the community with an honest verified rating out of 10.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Center(
          child: Text(
            '$_foodRating / 10',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Slider(
          value: _foodRating.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() {
              _foodRating = val.round();
            });
          },
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _restaurantFeedbackController,
          decoration: const InputDecoration(
            labelText: 'Write a review (optional)',
            hintText: 'e.g. Delicious biryani, but service was slow.',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _skipRestaurantReview,
                child: const Text('Skip Rating', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: AppButton(
                label: 'Next Step',
                onPressed: _submitRestaurantReview,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildParticipantReviewStep() {
    if (widget.attendeesToReview.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No other participants to rate',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Since you were the only attendee checked in for this session, there are no other participants to rate on this participant rating page.',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Go to Home',
            onPressed: _finishFeedback,
          ),
          const SizedBox(height: 10),
        ],
      );
    }

    final targetUser = widget.attendeesToReview[_currentParticipantIndex];
    final progress = '(${_currentParticipantIndex + 1}/${widget.attendeesToReview.length})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Rate $progress: ${targetUser.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Rate their Baraqah (reliability & attitude) out of 7 stars.',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            return IconButton(
              icon: Icon(
                index < _participantRating ? Icons.star : Icons.star_border,
                size: 38,
                color: AppColors.accent,
              ),
              onPressed: () {
                setState(() {
                  _participantRating = index + 1;
                });
              },
            );
          }),
        ),
        Center(
          child: Text(
            '$_participantRating / 7 Stars',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _participantFeedbackController,
          decoration: const InputDecoration(
            labelText: 'Write feedback (optional)',
            hintText: 'e.g. Very friendly and arrived exactly on time!',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _skipParticipantReview,
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: AppButton(
                label: _currentParticipantIndex == widget.attendeesToReview.length - 1
                    ? 'Finish'
                    : 'Next Participant',
                onPressed: _submitParticipantReview,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
