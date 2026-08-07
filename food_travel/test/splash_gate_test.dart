import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/views/splash/foods_splash_constants.dart';
import 'package:food_travel/views/splash/splash_gate.dart';

void main() {
  testWidgets('Splash renders and completes only once', (tester) async {
    var completionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          hasSeenOnboarding: true,
          navigateOnComplete: false,
          onCompleted: () => completionCount++,
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(FoodsSplashConstants.duration ~/ 2);
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(FoodsSplashConstants.duration ~/ 2);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completionCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completionCount, 1);
  });

  testWidgets('Reduced motion completes in a short duration', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
        home: SplashGate(
          hasSeenOnboarding: true,
          navigateOnComplete: false,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(completed, isTrue);
  });

  testWidgets('holds completed logo until startup initialization finishes', (
    tester,
  ) async {
    final initialization = Completer<void>();
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          hasSeenOnboarding: true,
          initialization: initialization.future,
          navigateOnComplete: false,
          onCompleted: () => completed = true,
        ),
      ),
    );

    await tester.pump(FoodsSplashConstants.duration);
    expect(completed, isFalse);
    expect(find.byType(CustomPaint), findsWidgets);

    initialization.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
  });
}
