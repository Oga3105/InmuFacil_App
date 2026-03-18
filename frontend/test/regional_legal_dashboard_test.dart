import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:inmufacil_frontend/presentation/widgets/property/regional_legal_dashboard_widget.dart';

void main() {
  group('RegionalLegalDashboardWidget', () {
    testWidgets('Madrid no muestra bloque de cedula', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: true,
              hasNotaSimple: true,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('Cedula'), findsNothing);
    });

    testWidgets('Barcelona muestra bloque de cedula', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '08001',
              hasCee: false,
              hasNotaSimple: false,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('Cedula'), findsWidgets);
    });

    testWidgets('Propietario con docs incompletos ve aviso', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: false,
              hasNotaSimple: false,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('documentacion aun no ha sido verificada'), findsOneWidget);
    });

    testWidgets('Propietario con todos los docs NO ve aviso', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: true,
              hasNotaSimple: true,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('documentacion aun no ha sido verificada'), findsNothing);
    });

    testWidgets('No propietario no ve aviso aunque docs incompletos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: false,
              hasNotaSimple: false,
              isOwner: false,
            ),
          ),
        ),
      );
      expect(find.textContaining('documentacion aun no ha sido verificada'), findsNothing);
    });

    testWidgets('Calificacion energetica CEE se muestra si se provee', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: true,
              hasNotaSimple: true,
              ceeGrade: 'B',
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('Calificacion: B'), findsOneWidget);
    });

    testWidgets('Valencia muestra bloque de cedula (Comunitat Valenciana)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '46001',
              hasCee: false,
              hasNotaSimple: false,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('Cedula'), findsWidgets);
    });

    testWidgets('Nota simple caducada muestra mensaje de caducidad', (tester) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 100));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: true,
              hasNotaSimple: true,
              notaSimpleDate: oldDate,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('caducado'), findsOneWidget);
    });

    testWidgets('Nota simple reciente no muestra caducidad', (tester) async {
      final recentDate = DateTime.now().subtract(const Duration(days: 10));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegionalLegalDashboardWidget(
              postalCode: '28001',
              hasCee: true,
              hasNotaSimple: true,
              notaSimpleDate: recentDate,
              isOwner: true,
            ),
          ),
        ),
      );
      expect(find.textContaining('caducado'), findsNothing);
    });
  });
}
