import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final int value;
  final Function(int) onChanged;

  const RatingStars({Key? key, required this.value, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final active = index < value;
        return IconButton(
          onPressed: () => onChanged(index + 1),
          icon: Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? AppColors.accent : AppColors.textSecondary,
          ),
        );
      }),
    );
  }
}
