import 'dart:math' as math;

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
  });

  final bool hasSeenOnboarding;

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
      duration: const Duration(milliseconds: 2900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.of(context).pushReplacementNamed(
            widget.hasSeenOnboarding ? RouteNames.authGate : RouteNames.onboarding,
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
                        height: 320,
                        child: CustomPaint(
                          size: const Size(260, 320),
                          painter: _LogoStrokePainter(progress: _controller.value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: titleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - titleFade.value) * 18),
                          child: const Text(
                            'FoodS',
                            style: TextStyle(
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

class _LogoStrokePainter extends CustomPainter {
  _LogoStrokePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
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

    final leftSteamPath = Path()
      ..moveTo(size.width * 0.39, size.height * 0.20)
      ..cubicTo(
        size.width * 0.33,
        size.height * 0.12,
        size.width * 0.43,
        size.height * 0.08,
        size.width * 0.41,
        size.height * 0.02,
      );
    final rightSteamPath = Path()
      ..moveTo(size.width * 0.49, size.height * 0.24)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.15,
        size.width * 0.55,
        size.height * 0.12,
        size.width * 0.52,
        size.height * 0.06,
      );
    final sPath = Path()
      ..moveTo(size.width * 0.66, size.height * 0.24)
      ..cubicTo(
        size.width * 0.57,
        size.height * 0.20,
        size.width * 0.34,
        size.height * 0.24,
        size.width * 0.31,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.51,
        size.width * 0.63,
        size.height * 0.50,
        size.width * 0.70,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.73,
        size.width * 0.58,
        size.height * 0.85,
        size.width * 0.24,
        size.height * 0.81,
      );
    final route = Path()
      ..moveTo(size.width * 0.56, size.height * 0.57)
      ..cubicTo(
        size.width * 0.61,
        size.height * 0.52,
        size.width * 0.72,
        size.height * 0.49,
        size.width * 0.78,
        size.height * 0.51,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.53,
        size.width * 0.88,
        size.height * 0.37,
        size.width * 0.76,
        size.height * 0.31,
      );
    final bowlTopPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.83)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.76,
        size.width * 0.82,
        size.height * 0.83,
      );
    final bowlBottomPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.83)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 1.02,
        size.width * 0.82,
        size.height * 0.83,
      );
    final bowlInnerPath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.79,
        size.width * 0.76,
        size.height * 0.84,
      );

    _drawPathProgress(canvas, leftSteamPath, strokePaint, steamLeft);
    _drawPathProgress(canvas, rightSteamPath, strokePaint, steamRight);

    final sShadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.16 * sBody)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawPathProgress(canvas, sPath, sShadowPaint, sBody);
    _drawPathProgress(canvas, sPath, strokePaint, sBody);

    _drawDashedPath(
      canvas,
      route,
      strokePaint,
      dashProgress: routeProgress,
      dashLength: 12,
      gapLength: 9,
    );

    if (routeProgress > 0) {
      final dotPosition = _pointOnPath(route, routeProgress);
      canvas.drawCircle(dotPosition, 6, fillPaint);
    }

    if (accentProgress > 0) {
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.69),
        5 * accentProgress,
        fillPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.90, size.height * 0.86),
        5 * accentProgress,
        fillPaint,
      );
    }

    if (pinProgress > 0) {
      canvas.save();
      final pinCenter = Offset(size.width * 0.78, size.height * 0.28);
      canvas.translate(pinCenter.dx, pinCenter.dy);
      final scale = Curves.elasticOut.transform(pinProgress);
      canvas.scale(scale);
      final pinPath = Path()
        ..moveTo(0, 38)
        ..cubicTo(-18, 14, -28, 1, -28, -16)
        ..cubicTo(-28, -39, -12, -54, 0, -54)
        ..cubicTo(12, -54, 28, -39, 28, -16)
        ..cubicTo(28, 1, 18, 14, 0, 38)
        ..close();
      canvas.drawPath(pinPath, fillPaint);
      canvas.drawCircle(Offset.zero, 10, Paint()..color = const Color(0xFFFF5A00));
      canvas.restore();
    }

    _drawPathProgress(canvas, bowlTopPath, strokePaint, bowlProgress);
    _drawPathProgress(canvas, bowlBottomPath, strokePaint, bowlProgress);
    _drawPathProgress(
      canvas,
      bowlInnerPath,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
      accentProgress,
    );
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
    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return Offset.zero;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));
    return tangent?.position ?? Offset.zero;
  }

  @override
  bool shouldRepaint(covariant _LogoStrokePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
