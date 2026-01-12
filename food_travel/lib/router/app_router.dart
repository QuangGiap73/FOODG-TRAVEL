import 'package:flutter/material.dart';

import '../views/auth/auth_gate.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/home/home_screen.dart';
import '../views/onboarding/welcome_screen.dart';
import '../views/personal/edit_personal.dart';
import '../views/personal/personal.dart';
import '../views/settings/change_password_page.dart';
import '../views/settings/theme_settings.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.personal:
        return MaterialPageRoute(builder: (_) => const PersonalPage());
      case RouteNames.editPersonal:
        return MaterialPageRoute(builder: (_) => const EditPersonalPage());
      case RouteNames.themeSettings:
        return MaterialPageRoute(builder: (_) => const ThemeSettingsPage());
      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
