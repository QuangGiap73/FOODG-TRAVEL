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
import 'views/splash/app_startup_gate.dart';

// Handler khi push den luc app dang background/terminated
// (bat buoc de FCM xu ly dung khi app tat)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final themeController = ThemeController();
  final localeController = LocaleController();
  final initialization = Future.wait<void>([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    themeController.load(),
    localeController.load(),
  ]);
  runApp(
    MyApp(
      themeController: themeController,
      localeController: localeController,
      initialization: initialization,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.themeController,
    required this.localeController,
    this.home,
    this.initialization,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final Widget? home;
  final Future<void>? initialization;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, localeController]),
      builder: (context, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => FavoriteController()),
            ChangeNotifierProvider(
              // Like bai viet cong dong
              create: (_) => PostLikeController(),
            ),
            ChangeNotifierProvider(create: (_) => PlaceFavoriteController()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FOODS',
            scaffoldMessengerKey: appScaffoldMessengerKey,
            navigatorKey: appNavigatorKey,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeController.themeMode,
            locale: localeController.locale,
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home ?? AppStartupGate(initialization: initialization),
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
      },
    );
  }
}
