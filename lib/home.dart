import 'package:flutter/material.dart';
import 'login/screens/login_screen.dart';

// Backwards-compatibility wrapper
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
