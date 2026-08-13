import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'foods_logo_painter.dart';
import 'foods_splash_constants.dart';
import 'foods_splash_progress.dart';

class FoodsAnimatedLogo extends StatelessWidget {
  const FoodsAnimatedLogo({
    super.key,
    required this.progress,
    this.referenceAsset = 'assets/foodg_logo_vector.svg',
  });

  final FoodsSplashProgress progress;
  final String referenceAsset;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 1 - progress.finalLogo,
            child: CustomPaint(painter: FoodsLogoPainter(progress: progress)),
          ),
          if (progress.finalLogo > 0)
            Opacity(
              opacity: progress.finalLogo,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  FoodsSplashConstants.logoColor,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(referenceAsset, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }
}

/// Optional development overlay; it is never registered in production routes.
class FoodsLogoDebugPreview extends StatelessWidget {
  const FoodsLogoDebugPreview({
    super.key,
    this.showReferenceLogo = false,
    this.referenceOpacity = 0.25,
    this.painterOpacity = 0.75,
    this.controllerProgress = 1,
  });

  final bool showReferenceLogo;
  final double referenceOpacity;
  final double painterOpacity;
  final double controllerProgress;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ColoredBox(
      color: FoodsSplashConstants.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: SizedBox.square(
              dimension: side,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (showReferenceLogo)
                    Opacity(
                      opacity: referenceOpacity.clamp(0.0, 1.0),
                      child: SvgPicture.asset(
                        'assets/foodg_logo_vector.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  Opacity(
                    opacity: painterOpacity.clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: FoodsLogoPainter(
                        progress: FoodsSplashProgress.fromValue(
                          controllerProgress.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
