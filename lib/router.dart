import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    default:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
  }
}