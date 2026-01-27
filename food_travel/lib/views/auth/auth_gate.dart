import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../controller/favorite/favorite_controller.dart';
import '../../controller/restaurants/place_favorite_controller.dart';
import '../home/home_screen.dart';
import '../onboarding/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        context.read<FavoriteController>().bindUser(snapshot.data?.uid);
        context.read<PlaceFavoriteController>().bindUser(snapshot.data?.uid);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}
