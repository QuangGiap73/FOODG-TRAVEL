import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../controller/favorite/favorite_controller.dart';
import '../../controller/community/post_like_controller.dart';
import '../../controller/restaurants/place_favorite_controller.dart';
import '../../services/notifications/notification_service.dart';
import '../home/home_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../splash/splash_gate.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.showLoginSuccessAnimation = false,
  });

  final bool showLoginSuccessAnimation;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _showLoginSuccessAnimation;

  @override
  void initState() {
    super.initState();
    _showLoginSuccessAnimation = widget.showLoginSuccessAnimation;
  }

  void _finishLoginAnimation() {
    if (!mounted || !_showLoginSuccessAnimation) return;
    setState(() => _showLoginSuccessAnimation = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        context.read<FavoriteController>().bindUser(snapshot.data?.uid);
        // Bind user cho like bai viet
        context.read<PostLikeController>().bindUser(snapshot.data?.uid);
        context.read<PlaceFavoriteController>().bindUser(snapshot.data?.uid);
        // Bind user cho thong bao:
        // - xin quyen
        // - lay token
        // - luu vao Firestore
        NotificationService().bindUser(snapshot.data?.uid);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          if (!widget.showLoginSuccessAnimation) {
            return const HomeScreen();
          }

          return PopScope(
            canPop: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeScreen(
                  allowInitialSurvey: !_showLoginSuccessAnimation,
                ),
                if (_showLoginSuccessAnimation)
                  SplashGate(
                    hasSeenOnboarding: true,
                    finalLogoAsset: 'assets/logo.jpg',
                    duration: const Duration(milliseconds: 3600),
                    navigateOnComplete: false,
                    onCompleted: _finishLoginAnimation,
                  ),
              ],
            ),
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
