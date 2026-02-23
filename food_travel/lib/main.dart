import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'controller/favorite/favorite_controller.dart';
import 'controller/community/post_like_controller.dart';
import 'controller/restaurants/place_favorite_controller.dart';
import 'controller/theme_controller.dart';
import 'controller/l10n/locale_controller.dart';
import 'config/app_scaffold_messenger.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

// Handler khi push den luc app dang background/terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Dang ky handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final themeController = ThemeController();
  await themeController.load();
  final localeController = LocaleController();
  await localeController.load();
  runApp(MyApp(
    themeController: themeController,
    localeController: localeController,
    ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, 
    required this.themeController,
    required this.localeController,
    });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, localeController]),
      builder: (context, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => FavoriteController(),
            ),
            ChangeNotifierProvider(
              // Like bai viet cong dong
              create: (_) => PostLikeController(),
            ),
            ChangeNotifierProvider(
              create: (_) => PlaceFavoriteController(),
            ),

          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FoodG Travel',
            scaffoldMessengerKey: appScaffoldMessengerKey,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeController.themeMode,
            locale: localeController.locale,
            supportedLocales: const [
              Locale('vi'),
              Locale('en'),
            ],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            initialRoute: RouteNames.authGate,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
      },
    );
  }
}
