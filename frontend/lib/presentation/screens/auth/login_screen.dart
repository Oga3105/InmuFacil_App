import 'package:flutter/material.dart';

/// Login screen - Placeholder for @UIBuilder implementation
/// 
/// @UIBuilder: This is your workspace for the login screen.
/// Requirements:
/// - Email/password input fields
/// - Login button
/// - Register navigation link
/// - Form validation
/// - Loading state during authentication
/// 
/// Connect to AuthProvider (to be created) for business logic.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InmuFácil - Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_work,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Placeholder - @UIBuilder will implement this screen',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
