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
    this.onResolved,
    this.allowInitialSurvey = true,
  });

  final bool showLoginSuccessAnimation;
  final VoidCallback? onResolved;
  final bool allowInitialSurvey;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _showLoginSuccessAnimation;
  bool _reportedResolved = false;

  @override
  void initState() {
    super.initState();
    _showLoginSuccessAnimation = widget.showLoginSuccessAnimation;
  }

  void _finishLoginAnimation() {
    if (!mounted || !_showLoginSuccessAnimation) return;
    setState(() => _showLoginSuccessAnimation = false);
  }

  void _reportResolved() {
    if (_reportedResolved || widget.onResolved == null) return;
    _reportedResolved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onResolved?.call();
    });
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

        _reportResolved();

        if (snapshot.hasData) {
          if (!widget.showLoginSuccessAnimation) {
            return HomeScreen(allowInitialSurvey: widget.allowInitialSurvey);
          }

          return PopScope(
            canPop: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeScreen(allowInitialSurvey: !_showLoginSuccessAnimation),
                if (_showLoginSuccessAnimation)
                  SplashGate(
                    hasSeenOnboarding: true,
                    navigateOnComplete: false,
                    animateToBottomNavigation: true,
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
