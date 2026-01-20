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
import '../views/settings/language_setting.dart';
import '../views/onboarding/survey_page.dart';
import '../views/provinces/province_detail_page.dart';
import '../views/dishes/dish_detail_page.dart';
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
      case RouteNames.languageSettings:
        return MaterialPageRoute(builder: (_) => const LanguageSettingsPage());
      case RouteNames.survey:
        return MaterialPageRoute(builder: (_) => const SurveyPage());
      case RouteNames.provinceDetail:
        final provinceId = settings.arguments as String?;
        if(provinceId == null || provinceId.isEmpty){
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body:  Center(child: Text('Missing provinces id')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProvinceDetailPage(provinceId: provinceId),
        );
      case RouteNames.dishDetail:
        final dishId = settings.arguments as String?;
        if (dishId == null || dishId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing dish id')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => DishDetailPage(dishId: dishId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
