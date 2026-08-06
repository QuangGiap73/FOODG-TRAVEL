import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/router/route_names.dart';
import 'package:food_travel/views/splash/splash_gate.dart';
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
        home: const AppStartupGate(),
        routes: {
          RouteNames.authGate: (_) => const _RouteMarker('auth-gate'),
          RouteNames.onboarding: (_) => const _RouteMarker('onboarding'),
        },
      ),
    );

    // Resolve SharedPreferences, play the splash animation, then process the
    // replacement route scheduled by its animation status listener.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
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
