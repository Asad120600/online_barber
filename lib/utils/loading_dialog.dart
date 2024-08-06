import 'package:flutter/material.dart';
import 'loading_dots.dart';

class LoadingDialog extends StatelessWidget {
  final String message;
  final Color dotColor;
  final double dotSize;
  final int numDots;
  final Duration duration;

  const LoadingDialog({
    super.key,
    required this.message,
    this.dotColor = Colors.orange,
    this.dotSize = 10.0,
    this.numDots = 3,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingDots(
              dotColor: dotColor,
              dotSize: dotSize,
              numDots: numDots,
              duration: duration,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
