import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'controller/theme_controller.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final themeController = ThemeController();
  await themeController.load();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FoodG Travel',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeController.themeMode,
          initialRoute: RouteNames.authGate,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
