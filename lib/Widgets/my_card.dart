import 'package:flutter/material.dart';

Widget myCard(
  String title,
  String subtitle,
  IconData icon,
  Color iconColor,
  Color cardColor,
  Color titleColor,
  Color subTitleColor,
  double iconSize,
  double cardWidth,
  double cardHeight,
  void Function()? onPressed,
) {
  return InkWell(
    splashColor: Colors.deepPurple.withValues(alpha: 0.5),
    hoverColor: Colors.deepPurple.withValues(alpha: 0.1),
    radius: 12,
    onTap: onPressed,
    child: Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          Text(subtitle, style: TextStyle(fontSize: 14, color: subTitleColor)),
          SizedBox(height: 5),
        ],
      ),
    ),
  );
}
