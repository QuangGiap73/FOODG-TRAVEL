import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// (bat buoc de FCM xu ly dung khi app tat)
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
  // Dang ky handler background (truoc khi runApp)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final themeController = ThemeController();
  await themeController.load();
  final localeController = LocaleController();
  await localeController.load();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
  runApp(MyApp(
    themeController: themeController,
    localeController: localeController,
    hasSeenOnboarding: hasSeenOnboarding,
    ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, 
    required this.themeController,
    required this.localeController,
    required this.hasSeenOnboarding,
    });

  final ThemeController themeController;
  final LocaleController localeController;
  final bool hasSeenOnboarding;

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
            initialRoute: hasSeenOnboarding
                ? RouteNames.authGate
                : RouteNames.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
      },
    );
  }
}
