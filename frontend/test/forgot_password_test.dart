import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:inmufacil_frontend/presentation/screens/auth/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen renderiza campo de email y boton', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enviar enlace de recuperacion'), findsOneWidget);
    expect(find.text('Volver al inicio de sesion'), findsOneWidget);
  });

  testWidgets('Mostrar error si email vacio al enviar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.tap(find.text('Enviar enlace de recuperacion'));
    await tester.pump();
    expect(find.text('Introduce tu email.'), findsOneWidget);
  });

  testWidgets('No solicita biometria en ningun punto del flujo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ForgotPasswordScreen()),
    );
    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.textContaining('biometr'), findsNothing);
  });
}
