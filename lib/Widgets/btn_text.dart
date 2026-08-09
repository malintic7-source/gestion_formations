import 'package:flutter/material.dart';

Widget myTextBtn(String text, List<Color> colors, VoidCallback onPressed) {
  return Container(
    height: 50,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(30),
    ),
    child: TextButton(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
