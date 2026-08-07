import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../router/route_names.dart';
import 'foods_animated_logo.dart';
import 'foods_splash_constants.dart';
import 'foods_splash_progress.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.hasSeenOnboarding,
    this.destinationRoute,
    this.duration = FoodsSplashConstants.duration,
    this.navigateOnComplete = true,
    this.animateToBottomNavigation = false,
    this.initialization,
    this.onCompleted,
  });

  final bool hasSeenOnboarding;
  final String? destinationRoute;
  final Duration duration;
  final bool navigateOnComplete;
  final bool animateToBottomNavigation;
  final Future<void>? initialization;
  final VoidCallback? onCompleted;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _hasNavigated = false;
  bool _completionStarted = false;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _controller.duration = FoodsSplashConstants.reducedMotionDuration;
      _controller.value = 2450 / 2900;
    }
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    final initialization = widget.initialization;
    if (initialization == null) {
      _controller.forward();
      return;
    }

    // Draw through the completed-logo stage, but do not run the exit/fade
    // while Firebase, theme, or locale are still initializing. Otherwise the
    // logo disappears and leaves a blank orange screen on a cold app start.
    const holdValue = 2650 / 2900;
    final holdDuration = Duration(
      milliseconds: (_controller.duration!.inMilliseconds * holdValue).round(),
    );
    await _controller.animateTo(
      holdValue,
      duration: holdDuration,
      curve: Curves.linear,
    );
    try {
      await initialization;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('FOODS startup initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) setState(() => _initializationError = error);
      return;
    }
    if (mounted) _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _controller.value < 0.999 ||
        !mounted ||
        _completionStarted) {
      return;
    }
    _completionStarted = true;
    if (_hasNavigated) return;
    _hasNavigated = true;
    widget.onCompleted?.call();
    if (!widget.navigateOnComplete) return;
    Navigator.of(context).pushReplacementNamed(
      widget.destinationRoute ??
          (widget.hasSeenOnboarding
              ? RouteNames.authGate
              : RouteNames.onboarding),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = FoodsSplashProgress.fromValue(_controller.value);
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = constraints.biggest;
              final logoSize = math.min(
                screenSize.width * FoodsSplashConstants.logoWidthFactor,
                screenSize.height * FoodsSplashConstants.logoHeightFactor,
              );
              final startCenter = Offset(
                screenSize.width / 2,
                screenSize.height * 0.44,
              );
              final targetCenter = _bottomNavigationTarget(context, screenSize);
              final translate =
                  widget.animateToBottomNavigation
                      ? Offset.lerp(startCenter, targetCenter, progress.exit)! -
                          startCenter
                      : Offset(0, 10 * progress.exit);
              final scale =
                  widget.animateToBottomNavigation
                      ? 1 - 0.87 * progress.exit
                      : 1 - 0.08 * progress.exit;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: FoodsSplashConstants.backgroundColor.withValues(
                      alpha: 1 - progress.exit,
                    ),
                  ),
                  Positioned(
                    left: startCenter.dx - logoSize / 2,
                    top: startCenter.dy - logoSize / 2,
                    width: logoSize,
                    height: logoSize,
                    child: Transform.translate(
                      offset: translate,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: 1 - progress.exit,
                          child: FoodsAnimatedLogo(progress: progress),
                        ),
                      ),
                    ),
                  ),
                  if (_initializationError != null)
                    const SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không thể khởi tạo ứng dụng. Vui lòng mở lại ứng dụng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Offset _bottomNavigationTarget(BuildContext context, Size screenSize) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const itemCount = FoodsSplashConstants.bottomNavigationItemCount;
    const index = FoodsSplashConstants.locationItemIndex;
    return Offset(
      screenSize.width * ((index + 0.5) / itemCount),
      screenSize.height - safeBottom - 52,
    );
  }
}
