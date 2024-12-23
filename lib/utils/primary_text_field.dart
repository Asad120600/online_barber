import 'package:flutter/material.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String text;
  final Icon? prefixIcon;
  final bool obsecure;
  final Widget? suffixIcon;

  const PrimaryTextField({
    super.key,
    required this.controller,
    required this.text,
    this.prefixIcon,
    this.obsecure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obsecure,
      decoration: InputDecoration(
        hintText: text,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
