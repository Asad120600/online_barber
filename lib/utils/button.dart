import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const Button({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250, // Set button width to match parent width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.deepOrange; // Color when button is pressed
              }
              return Colors.orange; // Default color
            },
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white), // Set text color to white
          child: child,
        ),
      ),
    );
  }
}
