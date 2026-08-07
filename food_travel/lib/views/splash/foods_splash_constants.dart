import 'package:flutter/material.dart';

abstract final class FoodsSplashConstants {
  // The stage ratios stay unchanged; the longer controller duration gives
  // viewers enough time to follow each drawn stroke.
  static const duration = Duration(milliseconds: 4200);
  static const reducedMotionDuration = Duration(milliseconds: 400);
  static const designSize = Size.square(1254);
  static const backgroundColor = Color(0xFFFF5700);
  static const logoColor = Colors.white;
  static const logoWidthFactor = 0.76;
  static const logoHeightFactor = 0.48;
  static const bottomNavigationItemCount = 5;
  static const locationItemIndex = 2;
}
