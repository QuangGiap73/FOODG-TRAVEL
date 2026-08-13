import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'foods_logo_paths.dart';
import 'foods_splash_constants.dart';
import 'foods_splash_progress.dart';
import 'path_animation_utils.dart';

class FoodsLogoPainter extends CustomPainter {
  const FoodsLogoPainter({required this.progress});

  final FoodsSplashProgress progress;

  @override
  void paint(Canvas canvas, Size size) {
    final design = FoodsSplashConstants.designSize;
    final scale = math.min(
      size.width / design.width,
      size.height / design.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - design.width * scale) / 2,
        (size.height - design.height * scale) / 2,
      )
      ..scale(scale);

    final stroke =
        Paint()
          ..color = FoodsSplashConstants.logoColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final fill =
        Paint()
          ..color = FoodsSplashConstants.logoColor
          ..style = PaintingStyle.fill;

    _drawS(canvas, fill);
    _drawBowl(canvas, stroke, fill);
    _drawSteam(canvas, stroke);
    _drawRoute(canvas, stroke, fill);
    _drawPin(canvas, fill);
    _drawDecorationDots(canvas, fill);
    canvas.restore();
  }

  void _drawS(Canvas canvas, Paint fill) {
    final guideOpacity = (1 - progress.sFill).clamp(0.0, 1.0);
    if (guideOpacity > 0) {
      canvas.drawPath(
        PathAnimationUtils.extractPathByProgress(
          FoodsLogoPaths.sGuidePath,
          progress.sStroke,
        ),
        Paint()
          ..color = FoodsSplashConstants.logoColor.withValues(
            alpha: guideOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 116
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (progress.sFill > 0) {
      canvas.drawPath(
        FoodsLogoPaths.sFinalShapePath,
        Paint()
          ..color = FoodsSplashConstants.logoColor.withValues(
            alpha: progress.sFill,
          ),
      );
    }
    final point = PathAnimationUtils.getPathPosition(
      FoodsLogoPaths.sGuidePath,
      progress.sStroke,
    );
    if (point != null && progress.seedDot > 0 && progress.sStroke < 1) {
      canvas.drawCircle(point, 15 * progress.seedDot, fill);
    }
  }

  void _drawBowl(Canvas canvas, Paint stroke, Paint fill) {
    if (progress.bowl <= 0) return;
    canvas.drawPath(
      PathAnimationUtils.extractPathByProgress(
        FoodsLogoPaths.bowlTopPath,
        progress.bowl,
      ),
      stroke..strokeWidth = 26,
    );
    if (progress.bowl > 0.35) {
      final bodyProgress = ((progress.bowl - 0.35) / 0.65).clamp(0.0, 1.0);
      canvas.drawPath(
        FoodsLogoPaths.bowlBodyPath,
        Paint()
          ..color = FoodsSplashConstants.logoColor.withValues(
            alpha: bodyProgress,
          ),
      );
      canvas.drawPath(
        PathAnimationUtils.extractPathByProgress(
          FoodsLogoPaths.bowlCutoutPath,
          bodyProgress,
        ),
        Paint()
          ..color = FoodsSplashConstants.backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSteam(Canvas canvas, Paint stroke) {
    for (final entry in [
      (FoodsLogoPaths.steamLeftPath, progress.steamLeft),
      (FoodsLogoPaths.steamRightPath, progress.steamRight),
    ]) {
      if (entry.$2 <= 0) continue;
      canvas.save();
      canvas.translate(0, (1 - entry.$2) * 7);
      canvas.drawPath(
        PathAnimationUtils.extractPathByProgress(entry.$1, entry.$2),
        stroke..strokeWidth = 28,
      );
      if (entry.$2 > 0.72) {
        canvas.drawPath(
          entry.$1,
          Paint()
            ..color = FoodsSplashConstants.logoColor.withValues(
              alpha: (entry.$2 - 0.72) / 0.28,
            ),
        );
      }
      canvas.restore();
    }
  }

  void _drawRoute(Canvas canvas, Paint stroke, Paint fill) {
    for (final path in [
      FoodsLogoPaths.routePath,
      FoodsLogoPaths.routeTailPath,
    ]) {
      PathAnimationUtils.drawProgressiveDashedPath(
        canvas,
        path,
        stroke..strokeWidth = 20,
        progress: progress.route,
        dashLength: 34,
        gapLength: 24,
      );
    }
    final point = PathAnimationUtils.getPathPosition(
      FoodsLogoPaths.routePath,
      progress.route,
    );
    if (point != null && progress.route > 0 && progress.route < 1) {
      canvas.drawCircle(point, 12, fill);
    }
  }

  void _drawPin(Canvas canvas, Paint fill) {
    if (progress.locationPin <= 0) return;
    canvas.save();
    canvas.translate(836, 322);
    canvas.scale(0.2 + 0.8 * progress.locationPin);
    canvas.translate(-836, -322);
    canvas.drawPath(
      FoodsLogoPaths.locationPinPath,
      Paint()
        ..color = FoodsSplashConstants.logoColor.withValues(
          alpha: progress.locationPin.clamp(0.0, 1.0),
        ),
    );
    canvas.drawCircle(
      const Offset(836, 300),
      27,
      Paint()..color = FoodsSplashConstants.backgroundColor,
    );
    canvas.restore();
  }

  void _drawDecorationDots(Canvas canvas, Paint fill) {
    for (var index = 0; index < FoodsLogoPaths.decorationDots.length; index++) {
      final delayed = ((progress.decorationDots - index * 0.28) / 0.72).clamp(
        0.0,
        1.0,
      );
      final dot = FoodsLogoPaths.decorationDots[index];
      canvas.drawCircle(dot.$1, dot.$2 * delayed, fill);
    }
  }

  @override
  bool shouldRepaint(covariant FoodsLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
