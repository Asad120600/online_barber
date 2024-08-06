import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmButtonText;
  final VoidCallback onPressed;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmButtonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          child: Text(confirmButtonText),
          onPressed: () {
            Navigator.of(context).pop();
            onPressed();
          },
        ),
      ],
    );
  }
}
