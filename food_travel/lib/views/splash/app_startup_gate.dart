import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_gate.dart';
import '../onboarding/onboarding_carousel.dart';
import 'foods_splash_constants.dart';
import 'splash_gate.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    this.initialization,
    this.authenticatedBuilder,
    this.onboardingDestination,
  });

  final Future<void>? initialization;
  final Widget Function(VoidCallback onResolved, bool allowInitialSurvey)?
  authenticatedBuilder;
  final Widget? onboardingDestination;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final Future<_StartupDecision> _startup = _resolveStartup();
  final Completer<void> _destinationReady = Completer<void>();
  bool _showSplash = true;

  Future<_StartupDecision> _resolveStartup() async {
    final initialization = widget.initialization;
    if (initialization != null) await initialization;
    final preferences = await SharedPreferences.getInstance();
    return _StartupDecision(
      hasSeenOnboarding: preferences.getBool('onboarding_seen') ?? false,
    );
  }

  Future<void> get _readyToReveal async {
    final decision = await _startup;
    if (!decision.hasSeenOnboarding) return;
    await _destinationReady.future;
  }

  void _handleAuthResolved() {
    if (!_destinationReady.isCompleted) _destinationReady.complete();
  }

  void _finishSplash() {
    if (!mounted || !_showSplash) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<_StartupDecision>(
            future: _startup,
            builder: (context, snapshot) {
              final decision = snapshot.data;
              if (decision == null) {
                return const ColoredBox(
                  color: FoodsSplashConstants.backgroundColor,
                );
              }
              if (!decision.hasSeenOnboarding) {
                return widget.onboardingDestination ??
                    const OnboardingCarousel();
              }
              return widget.authenticatedBuilder?.call(
                    _handleAuthResolved,
                    !_showSplash,
                  ) ??
                  AuthGate(
                    onResolved: _handleAuthResolved,
                    allowInitialSurvey: !_showSplash,
                  );
            },
          ),
          if (_showSplash)
            SplashGate(
              hasSeenOnboarding: true,
              initialization: _readyToReveal,
              navigateOnComplete: false,
              onCompleted: _finishSplash,
            ),
        ],
      ),
    );
  }
}

class _StartupDecision {
  const _StartupDecision({required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;
}
