import 'package:baraqah_mobile/core/widgets/app_button.dart';
import 'package:baraqah_mobile/core/widgets/loading_indicator.dart';
import 'package:baraqah_mobile/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';

class ReviewPage extends StatefulWidget {
  static const String routeName = '/reviews';
  const ReviewPage({Key? key}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  int _quality = 3;
  int _safety = 3;
  int _communication = 3;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewsBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Submit Review')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<ReviewsBloc, ReviewsState>(
            listener: (context, state) {
              if (state is ReviewsSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Review submitted successfully')));
                Navigator.pop(context);
              }
              if (state is ReviewsFailure) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              return ListView(
                children: [
                  TextField(
                      controller: _sessionController,
                      decoration:
                          const InputDecoration(labelText: 'Session ID')),
                  const SizedBox(height: 16),
                  _ratingSlider('Quality', _quality,
                      (value) => setState(() => _quality = value)),
                  _ratingSlider('Safety', _safety,
                      (value) => setState(() => _safety = value)),
                  _ratingSlider('Communication', _communication,
                      (value) => setState(() => _communication = value)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(labelText: 'Feedback'),
                      maxLines: 4),
                  const SizedBox(height: 24),
                  if (state is ReviewsLoading)
                    const Center(child: LoadingIndicator()),
                  if (state is! ReviewsLoading)
                    AppButton(label: 'Submit Review', onPressed: _submitReview),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ratingSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (value) => onChanged(value.toInt())),
      ],
    );
  }

  void _submitReview() {
    context.read<ReviewsBloc>().add(SubmitReviewRequested(
          sessionId: _sessionController.text,
          ratingOverall: _quality * 2, // Map 1-5 scale to 1-10
          ratingFoodQuality: _quality * 2,
          ratingValue: _safety * 2,
          ratingService: _communication * 2,
          reviewText: _feedbackController.text,
        ));
  }
}
