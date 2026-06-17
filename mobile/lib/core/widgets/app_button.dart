import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final Color? color;

  const AppButton(
      {Key? key,
      required this.label,
      required this.onPressed,
      this.enabled = true,
      this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled
            ? (color ?? AppColors.primary)
            : AppColors.secondary.withOpacity(0.6),
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: enabled ? onPressed : null,
      child: Text(label,
          style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
