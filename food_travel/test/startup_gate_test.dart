import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/views/splash/app_startup_gate.dart';
import 'package:food_travel/views/splash/foods_splash_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpStartup(
    WidgetTester tester, {
    required bool hasSeenOnboarding,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (hasSeenOnboarding) 'onboarding_seen': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppStartupGate(
          onboardingDestination: const _RouteMarker('onboarding'),
          authenticatedBuilder: (onResolved, allowInitialSurvey) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onResolved());
            return const _RouteMarker('auth-gate');
          },
        ),
      ),
    );

    // Resolve startup/auth below the overlay, then finish the splash.
    await tester.pump();
    await tester.pump(FoodsSplashConstants.duration);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch opens onboarding', (tester) async {
    await pumpStartup(tester, hasSeenOnboarding: false);

    expect(find.text('onboarding'), findsOneWidget);
    expect(find.text('auth-gate'), findsNothing);
  });

  testWidgets('returning launch skips onboarding', (tester) async {
    await pumpStartup(tester, hasSeenOnboarding: true);

    expect(find.text('auth-gate'), findsOneWidget);
    expect(find.text('onboarding'), findsNothing);
  });
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
