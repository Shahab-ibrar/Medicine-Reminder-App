import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder_app/main.dart';

void main() {
  testWidgets('Splash screen shows app title and loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MediMind'), findsOneWidget);
    expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
  });
}
