import 'package:flutter/material.dart';

Widget myTextField(String hintText, IconData icon, bool isPassword) {
  return TextField(
    obscureText: isPassword,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
