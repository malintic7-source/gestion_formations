import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget poleDialog(BuildContext context, String title, String message) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.7,
    child: AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton.icon(
          icon: Icon(Icons.call),
          label: Text('Appeler'),
          onPressed: () async {
            await launchUrl(Uri.parse('https://callto:+22392753558'));
          },
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
          icon: Icon(Icons.message),
          label: Text('WhatsApp'),
          onPressed: () async {
            await launchUrl(Uri.parse('https://wa.me/22392753558'));
          },
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}
