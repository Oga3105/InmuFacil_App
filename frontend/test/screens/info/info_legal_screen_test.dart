// @Jules — TDD: Legal screens test suite
// Validates that /info/privacy and /info/terms render without error
// and contain the expected key legal content for InmuFacil.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:inmufacil_frontend/presentation/screens/info/info_screen.dart';

Widget _wrapRoute(String initialPath, InfoPageType type) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: initialPath,
      routes: [
        GoRoute(
          path: initialPath,
          builder: (_, __) => InfoScreen(pageType: type),
        ),
      ],
    ),
  );
}

void main() {
  group('InfoScreen — Privacy Policy', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.privacy),
        ),
      );
      await tester.pump();
      expect(find.byType(InfoScreen), findsOneWidget);
    });

    testWidgets('shows Privacidad in app bar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.privacy),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Privacidad'), findsWidgets);
    });

    testWidgets('contains Responsable del tratamiento section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.privacy),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Responsable'), findsWidgets);
    });

    testWidgets('contains Inteligencia Artificial section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.privacy),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Inteligencia Artificial'), findsWidgets);
    });

    testWidgets('mentions AES-256 encryption in header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.privacy),
        ),
      );
      await tester.pump();
      // AES-256 is shown in the always-visible compliance badge in the hero header
      expect(find.textContaining('AES-256'), findsWidgets);
    });

    testWidgets('route /info/privacy resolves via GoRouter', (tester) async {
      await tester.pumpWidget(_wrapRoute('/info/privacy', InfoPageType.privacy));
      await tester.pumpAndSettle();
      expect(find.byType(InfoScreen), findsOneWidget);
    });
  });

  group('InfoScreen — Terms and Conditions', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.terms),
        ),
      );
      await tester.pump();
      expect(find.byType(InfoScreen), findsOneWidget);
    });

    testWidgets('shows Terminos in app bar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.terms),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Terminos'), findsWidgets);
    });

    testWidgets('contains P2P platform section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.terms),
        ),
      );
      await tester.pump();
      expect(find.textContaining('P2P'), findsWidgets);
    });

    testWidgets('contains IA responsibility disclaimer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.terms),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Inteligencia Artificial'), findsWidgets);
    });

    testWidgets('contains Arras / timeline section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoScreen(pageType: InfoPageType.terms),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Arras'), findsWidgets);
    });

    testWidgets('route /info/terms resolves via GoRouter', (tester) async {
      await tester.pumpWidget(_wrapRoute('/info/terms', InfoPageType.terms));
      await tester.pumpAndSettle();
      expect(find.byType(InfoScreen), findsOneWidget);
    });
  });
}
