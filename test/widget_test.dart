import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transport_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // Remplace MyApp() par TransportApp()

    // Vérifie que le compteur commence à 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Appuie sur l'icône '+' et déclenche un nouveau rendu.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Vérifie que le compteur a incrémenté.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
