import 'package:flutter/animation.dart';

class FoodsSplashProgress {
  const FoodsSplashProgress({
    required this.seedDot,
    required this.sStroke,
    required this.sFill,
    required this.bowl,
    required this.steamLeft,
    required this.steamRight,
    required this.route,
    required this.locationPin,
    required this.decorationDots,
    required this.finalLogo,
    required this.exit,
  });

  factory FoodsSplashProgress.fromValue(double value) {
    return FoodsSplashProgress(
      seedDot: _interval(value, 200, 380, Curves.easeOutBack),
      sStroke: _interval(value, 320, 1250, Curves.easeInOutCubic),
      sFill: _interval(value, 1110, 1250, Curves.easeOut),
      bowl: _interval(value, 1050, 1600, Curves.easeOutCubic),
      steamLeft: _interval(value, 1450, 1810, Curves.easeOutCubic),
      steamRight: _interval(value, 1550, 1900, Curves.easeOutCubic),
      route: _interval(value, 1750, 2250, Curves.easeInOutCubic),
      locationPin: _interval(value, 2100, 2450, Curves.easeOutBack),
      decorationDots: _interval(value, 2200, 2500, Curves.easeOut),
      finalLogo: _interval(value, 2450, 2570, Curves.easeOut),
      exit: _interval(value, 2650, 2900, Curves.easeInOutCubic),
    );
  }

  factory FoodsSplashProgress.completed() => FoodsSplashProgress.fromValue(1);

  final double seedDot;
  final double sStroke;
  final double sFill;
  final double bowl;
  final double steamLeft;
  final double steamRight;
  final double route;
  final double locationPin;
  final double decorationDots;
  final double finalLogo;
  final double exit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodsSplashProgress &&
          seedDot == other.seedDot &&
          sStroke == other.sStroke &&
          sFill == other.sFill &&
          bowl == other.bowl &&
          steamLeft == other.steamLeft &&
          steamRight == other.steamRight &&
          route == other.route &&
          locationPin == other.locationPin &&
          decorationDots == other.decorationDots &&
          finalLogo == other.finalLogo &&
          exit == other.exit;

  @override
  int get hashCode => Object.hash(
    seedDot,
    sStroke,
    sFill,
    bowl,
    steamLeft,
    steamRight,
    route,
    locationPin,
    decorationDots,
    finalLogo,
    exit,
  );

  static double _interval(
    double controllerValue,
    int beginMilliseconds,
    int endMilliseconds,
    Curve curve,
  ) {
    final begin = beginMilliseconds / 2900;
    final end = endMilliseconds / 2900;
    if (controllerValue <= begin) return 0;
    if (controllerValue >= end) return 1;
    return curve.transform((controllerValue - begin) / (end - begin));
  }
}
