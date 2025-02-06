import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/LevelSelectionScreen.dart';
import 'Registration.dart';
import 'forgot_password_page.dart';
import 'login_page.dart';

class Navigation {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) {
          return FirebaseAuth.instance.currentUser != null
              ? LevelSelectionScreen(user: FirebaseAuth.instance.currentUser!)
              : LoginPage();
        });
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => LevelSelectionScreen(user: FirebaseAuth.instance.currentUser!));
      case '/forget_password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case '/registration':
        return MaterialPageRoute(builder: (_) => RegistrationPage());
      default:
        return MaterialPageRoute(builder: (_) => LoginPage());
    }
  }
}
