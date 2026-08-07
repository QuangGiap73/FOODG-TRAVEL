import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class PathAnimationUtils {
  static Path extractPathByProgress(Path source, double progress) {
    final metrics = source.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return Path();
    final totalLength = metrics.fold<double>(
      0,
      (sum, item) => sum + item.length,
    );
    var remaining = totalLength * progress.clamp(0.0, 1.0);
    final result = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(remaining, metric.length);
      result.addPath(metric.extractPath(0, length), Offset.zero);
      remaining -= length;
    }
    return result;
  }

  static Offset? getPathPosition(Path source, double progress) {
    final metrics = source.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return null;
    final totalLength = metrics.fold<double>(
      0,
      (sum, item) => sum + item.length,
    );
    var remaining = totalLength * progress.clamp(0.0, 1.0);
    for (final metric in metrics) {
      if (remaining <= metric.length) {
        return metric.getTangentForOffset(remaining)?.position;
      }
      remaining -= metric.length;
    }
    return metrics.last.getTangentForOffset(metrics.last.length)?.position;
  }

  static void drawProgressiveDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double progress,
    required double dashLength,
    required double gapLength,
  }) {
    final metrics = source.computeMetrics().toList(growable: false);
    final totalLength = metrics.fold<double>(
      0,
      (sum, item) => sum + item.length,
    );
    var remainingReveal = totalLength * progress.clamp(0.0, 1.0);
    for (final metric in metrics) {
      final revealed = math.min(remainingReveal, metric.length);
      var offset = 0.0;
      while (offset < revealed) {
        final dashEnd = math.min(offset + dashLength, revealed);
        canvas.drawPath(metric.extractPath(offset, dashEnd), paint);
        offset += dashLength + gapLength;
      }
      remainingReveal -= revealed;
      if (remainingReveal <= 0) break;
    }
  }
}
