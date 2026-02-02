import 'package:flutter/material.dart';

/// Bo style chu dung rieng cho trang chi tiet quan.
/// Muc tieu: dep hon, de doc hon, va dong nhat sang/toi.
class PlaceDetailTypography {
  const PlaceDetailTypography._();

  static TextStyle title(Color color) => TextStyle(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.35,
        color: color,
      );

  static TextStyle sectionTitle(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bodyStrong(Color color) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.05,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.05,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle chip(Color color) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: color,
      );
}
