// Basic smoke test: the app should build and show its bottom navigation
// without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mosque_finder/main.dart';
import 'package:mosque_finder/services/locale_controller.dart';

void main() {
  testWidgets('App builds and shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(MosqueFinderApp(localeController: LocaleController()));
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
