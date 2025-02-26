import 'package:flutter/material.dart';

class RedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width; // Optional width parameter

  const RedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.width, // Accept width as an optional parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, // Set the width of the button
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.redAccent, Colors.red],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}
