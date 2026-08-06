import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/route_names.dart';

/// Reads the device-level onboarding flag before showing the animated splash.
///
/// This flag is intentionally independent from Firebase authentication: signing
/// out must not make a user repeat the introductory onboarding.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final Future<bool> _hasSeenOnboarding = _loadOnboardingState();

  Future<bool> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFF5A00),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return SplashGate(hasSeenOnboarding: snapshot.data!);
      },
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.hasSeenOnboarding,
    this.destinationRoute,
    this.finalLogoAsset,
    this.duration = const Duration(milliseconds: 2900),
    this.navigateOnComplete = true,
    this.onCompleted,
  });

  final bool hasSeenOnboarding;
  final String? destinationRoute;
  final String? finalLogoAsset;
  final Duration duration;
  final bool navigateOnComplete;
  final VoidCallback? onCompleted;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onCompleted?.call();
          if (!widget.navigateOnComplete) return;
          Navigator.of(context).pushReplacementNamed(
            widget.destinationRoute ??
                (widget.hasSeenOnboarding
                    ? RouteNames.authGate
                    : RouteNames.onboarding),
          );
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.76, 0.93, curve: Curves.easeOut),
    );
    final finalLogoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 0.82, curve: Curves.easeOut),
    );
    final wholeScale = Tween<double>(
      begin: 1,
      end: 0.26,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.90, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
    final wholeOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 2.2),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.90, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFF5A00),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const _SplashBackdrop(),
              Transform.translate(
                offset: Offset(
                  wholeOffset.value.dx * 140,
                  wholeOffset.value.dy * 140,
                ),
                child: Transform.scale(
                  scale: wholeScale.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: widget.finalLogoAsset == null
                                  ? 1
                                  : 1 - finalLogoFade.value,
                              child: CustomPaint(
                                size: const Size.square(260),
                                painter: FoodsLogoPainter(
                                  progress: _controller.value,
                                ),
                              ),
                            ),
                            if (widget.finalLogoAsset != null)
                              Opacity(
                                opacity: finalLogoFade.value,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    widget.finalLogoAsset!,
                                    width: 260,
                                    height: 260,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: titleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - titleFade.value) * 18),
                          child: Text(
                            widget.finalLogoAsset == null
                                ? 'FoodS'
                                : 'FoodG Travel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6A00), Color(0xFFFF4D00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          left: -60,
          top: -40,
          child: _GlowOrb(size: 220, opacity: 0.10),
        ),
        Positioned(
          right: -40,
          bottom: 40,
          child: _GlowOrb(size: 180, opacity: 0.08),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

/// Geometry is authored in the same 1254 x 1254 coordinate system as the
/// reference SVG. Keeping paths separate makes visual overlay tuning possible
/// without touching the animation timeline.
class FoodsLogoPaths {
  FoodsLogoPaths._();

  static Path get steamLeft => Path()
    ..moveTo(536, 99)
    ..cubicTo(560, 145, 552, 180, 515, 224)
    ..cubicTo(478, 266, 478, 299, 495, 325)
    ..cubicTo(450, 296, 450, 246, 475, 214)
    ..cubicTo(512, 169, 535, 150, 536, 99)
    ..close();

  static Path get steamRight => Path()
    ..moveTo(599, 202)
    ..cubicTo(626, 245, 613, 282, 582, 310)
    ..cubicTo(554, 337, 560, 361, 568, 376)
    ..cubicTo(530, 348, 538, 302, 562, 280)
    ..cubicTo(592, 250, 599, 232, 599, 202)
    ..close();

  static Path get sCenterLine => Path()
    ..moveTo(785, 426)
    ..cubicTo(690, 430, 500, 465, 450, 535)
    ..cubicTo(400, 610, 490, 665, 670, 710)
    ..cubicTo(830, 750, 835, 845, 730, 895)
    ..cubicTo(625, 945, 440, 920, 325, 875);

  static Path get sShape => Path()
    ..moveTo(785, 422)
    ..cubicTo(720, 390, 580, 430, 490, 459)
    ..cubicTo(410, 486, 370, 540, 383, 593)
    ..cubicTo(398, 650, 460, 679, 609, 721)
    ..cubicTo(690, 744, 735, 780, 731, 815)
    ..cubicTo(727, 860, 670, 893, 593, 893)
    ..cubicTo(500, 893, 410, 876, 342, 862)
    ..cubicTo(315, 856, 300, 870, 313, 884)
    ..cubicTo(350, 920, 500, 950, 642, 950)
    ..cubicTo(780, 950, 875, 910, 900, 835)
    ..cubicTo(930, 745, 835, 690, 713, 663)
    ..lineTo(658, 651)
    ..cubicTo(565, 630, 516, 603, 516, 562)
    ..cubicTo(516, 520, 575, 485, 686, 465)
    ..cubicTo(750, 453, 790, 438, 785, 422)
    ..close();

  static Path get journey => Path()
    ..moveTo(621, 568)
    ..cubicTo(650, 535, 710, 520, 764, 507)
    ..cubicTo(810, 496, 839, 468, 837, 420);

  static Path get journeyTail => Path()
    ..moveTo(621, 568)
    ..cubicTo(640, 610, 710, 620, 765, 651);

  static Path get pin => Path()
    ..moveTo(836, 242)
    ..cubicTo(802, 242, 777, 266, 777, 301)
    ..cubicTo(777, 338, 810, 374, 836, 402)
    ..cubicTo(862, 374, 895, 338, 895, 301)
    ..cubicTo(895, 266, 870, 242, 836, 242)
    ..close();

  static Path get bowlBody => Path()
    ..moveTo(275, 874)
    ..cubicTo(330, 940, 445, 981, 594, 981)
    ..cubicTo(735, 981, 845, 947, 894, 894)
    ..cubicTo(870, 1015, 760, 1116, 594, 1116)
    ..cubicTo(420, 1116, 305, 1018, 275, 874)
    ..close();

  static Path get bowlMouth => Path()
    ..moveTo(285, 872)
    ..cubicTo(405, 930, 520, 950, 642, 950)
    ..cubicTo(760, 950, 850, 920, 894, 884);

  static Path get bowlNegativeGap => Path()
    ..moveTo(306, 893)
    ..cubicTo(430, 965, 705, 1005, 875, 922);
}

class FoodsLogoPainter extends CustomPainter {
  FoodsLogoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const designExtent = 1254.0;
    final scale = math.min(size.width, size.height) / designExtent;
    final dx = (size.width - designExtent * scale) / 2;
    final dy = (size.height - designExtent * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final steamLeft = ((progress - 0.00) / 0.18).clamp(0.0, 1.0);
    final steamRight = ((progress - 0.08) / 0.18).clamp(0.0, 1.0);
    final sBody = ((progress - 0.16) / 0.34).clamp(0.0, 1.0);
    final routeProgress = ((progress - 0.32) / 0.22).clamp(0.0, 1.0);
    final pinProgress = ((progress - 0.50) / 0.10).clamp(0.0, 1.0);
    final bowlProgress = ((progress - 0.58) / 0.18).clamp(0.0, 1.0);
    final accentProgress = ((progress - 0.68) / 0.12).clamp(0.0, 1.0);

    _drawPathProgress(canvas, FoodsLogoPaths.steamLeft, strokePaint, steamLeft);
    _drawPathProgress(canvas, FoodsLogoPaths.steamRight, strokePaint, steamRight);
    if (steamLeft > 0.72) {
      canvas.drawPath(
        FoodsLogoPaths.steamLeft,
        fillPaint..color = Colors.white.withOpacity((steamLeft - 0.72) / 0.28),
      );
    }
    if (steamRight > 0.72) {
      canvas.drawPath(
        FoodsLogoPaths.steamRight,
        fillPaint..color = Colors.white.withOpacity((steamRight - 0.72) / 0.28),
      );
    }

    final sShadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.16 * sBody)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 116
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawPathProgress(canvas, FoodsLogoPaths.sCenterLine, sShadowPaint, sBody);
    _drawPathProgress(canvas, FoodsLogoPaths.sCenterLine, strokePaint, sBody);
    if (sBody > 0.78) {
      canvas.drawPath(
        FoodsLogoPaths.sShape,
        Paint()
          ..color = Colors.white.withOpacity(
            ((sBody - 0.78) / 0.22).clamp(0.0, 1.0),
          ),
      );
    }

    _drawDashedPath(
      canvas,
      FoodsLogoPaths.journey,
      strokePaint,
      dashProgress: routeProgress,
      dashLength: 46,
      gapLength: 30,
    );
    _drawDashedPath(
      canvas,
      FoodsLogoPaths.journeyTail,
      strokePaint,
      dashProgress: routeProgress,
      dashLength: 46,
      gapLength: 30,
    );

    if (routeProgress > 0) {
      final dotPosition = _pointOnPath(FoodsLogoPaths.journey, routeProgress);
      canvas.drawCircle(dotPosition, 22, fillPaint..color = Colors.white);
    }

    if (accentProgress > 0) {
      canvas.drawCircle(
        const Offset(836, 643),
        10 * accentProgress,
        fillPaint,
      );
      canvas.drawCircle(
        const Offset(946, 817),
        11 * accentProgress,
        fillPaint,
      );
    }

    if (pinProgress > 0) {
      canvas.save();
      final scale = Curves.elasticOut.transform(pinProgress);
      canvas.translate(836, 322);
      canvas.scale(scale);
      canvas.translate(-836, -322);
      canvas.drawPath(FoodsLogoPaths.pin, fillPaint..color = Colors.white);
      canvas.drawCircle(
        const Offset(836, 300),
        27,
        Paint()..color = const Color(0xFFFF5700),
      );
      canvas.restore();
    }

    _drawPathProgress(canvas, FoodsLogoPaths.bowlMouth, strokePaint, bowlProgress);
    _drawPathProgress(canvas, FoodsLogoPaths.bowlBody, strokePaint, bowlProgress);
    if (bowlProgress > 0.70) {
      canvas.drawPath(
        FoodsLogoPaths.bowlBody,
        Paint()
          ..color = Colors.white.withOpacity(
            ((bowlProgress - 0.70) / 0.30).clamp(0, 1),
          ),
      );
    }
    _drawPathProgress(
      canvas,
      FoodsLogoPaths.bowlNegativeGap,
      Paint()
        ..color = const Color(0xFFFF5700).withOpacity(accentProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
      accentProgress,
    );
    canvas.restore();
  }

  void _drawPathProgress(Canvas canvas, Path path, Paint paint, double progress) {
    if (progress <= 0) return;
    for (final metric in path.computeMetrics()) {
      final length = metric.length * progress.clamp(0.0, 1.0);
      canvas.drawPath(metric.extractPath(0, length), paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {required double dashProgress, double dashLength = 12, double gapLength = 8}) {
    for (final metric in path.computeMetrics()) {
      final targetLength = metric.length * dashProgress;
      double distance = 0;
      while (distance < targetLength) {
        final next = math.min(distance + dashLength, targetLength);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  Offset _pointOnPath(Path path, double t) {
    // PathMetrics is a lazy, single-pass iterable on some Flutter engines.
    // Materializing it avoids consuming the first metric in `isEmpty` before
    // reading it again, which otherwise throws "Bad state: No element".
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return Offset.zero;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(
      metric.length * t.clamp(0.0, 1.0),
    );
    return tangent?.position ?? Offset.zero;
  }

  @override
  bool shouldRepaint(covariant FoodsLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Development-only overlay for comparing painter geometry with logo.jpg.
/// It is deliberately not registered in AppRouter or any production flow.
class FoodsLogoDebugPreview extends StatelessWidget {
  const FoodsLogoDebugPreview({
    super.key,
    this.showReferenceLogo = false,
    this.referenceOpacity = 0.25,
    this.painterOpacity = 0.75,
    this.progress = 1,
  });

  final bool showReferenceLogo;
  final double referenceOpacity;
  final double painterOpacity;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return ColoredBox(
      color: const Color(0xFFFF5700),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showReferenceLogo)
                Opacity(
                  opacity: referenceOpacity.clamp(0.0, 1.0),
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.fill),
                ),
              Opacity(
                opacity: painterOpacity.clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: FoodsLogoPainter(
                    progress: progress.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
