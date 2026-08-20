// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_formations/Pages/Login/welcom_page.dart';

void main() {
  testWidgets('WelcomPage renders logo and access button', (WidgetTester tester) async {
    // Build our app welcome page directly.
    await tester.pumpWidget(const MaterialApp(home: WelcomPage()));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Formations'), findsOneWidget);
  });
}
