import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Snake border with a heart icon at the head.
/// Now supports an optional fixed [height] to avoid infinite-height errors.
class SnakeBorderWithHeart extends StatefulWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double snakeLength; // px along path
  final double speed; // >1 faster
  final BorderRadius borderRadius;
  final int tailSegments; // 1 = no fade tail
  final double heartSize; // icon size
  final Color heartColor;
  final double? height; // NEW: optional fixed height

  const SnakeBorderWithHeart({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.strokeWidth = 3.0,
    this.snakeLength = 180.0,
    this.speed = 1.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.tailSegments = 6,
    this.heartSize = 22.0,
    this.heartColor = Colors.pink,
    this.height,
  });

  @override
  SnakeBorderWithHeartState createState() => SnakeBorderWithHeartState();
}

class SnakeBorderWithHeartState extends State<SnakeBorderWithHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final baseMillis = 5000;
    final durationMillis = (baseMillis / widget.speed).round().clamp(100, 60000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMillis),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SnakeBorderWithHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      final baseMillis = 5000;
      final durationMillis = (baseMillis / widget.speed).round().clamp(100, 60000);
      _controller.duration = Duration(milliseconds: durationMillis);
      _controller.reset();
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Compute head tangent (position + angle) along the rounded rect path
  Tangent? _computeHeadTangentForSize(Size size, double progress) {
    if (size.width <= 0 || size.height <= 0) return null;
    final rect = Offset.zero & size;
    final rrect = widget.borderRadius.toRRect(rect);
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;

    final totalLength = metrics.fold<double>(0, (t, m) => t + m.length);
    if (totalLength <= 0) return null;

    double start = (progress * totalLength) % totalLength;
    double consumed = 0.0;
    for (final metric in metrics) {
      final len = metric.length;
      if (start <= consumed + len) {
        final local = start - consumed;
        return metric.getTangentForOffset(local);
      }
      consumed += len;
    }

    final last = metrics.last;
    return last.getTangentForOffset(last.length);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with SizedBox if height was provided; inside we use LayoutBuilder to get width.
    return (widget.height != null)
        ? SizedBox(
            height: widget.height,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final size = Size(width, widget.height!);

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final tangent = _computeHeadTangentForSize(size, _controller.value);
                  final headPos = tangent?.position ?? const Offset(-1000, -1000);
                  final headAngle = tangent?.angle ?? 0.0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _SnakeSinglePainterWithParams(
                          progress: _controller.value,
                          color: widget.color,
                          strokeWidth: widget.strokeWidth,
                          snakeLength: widget.snakeLength,
                          borderRadius: widget.borderRadius,
                          tailSegments: widget.tailSegments,
                        ),
                        child: SizedBox(
                          width: width,
                          height: widget.height,
                          child: widget.child,
                        ),
                      ),
                      Positioned(
                        left: headPos.dx - widget.heartSize / 2,
                        top: headPos.dy - widget.heartSize / 2,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: headAngle,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.favorite,
                              size: widget.heartSize,
                              color: widget.heartColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          )
        : // height not provided: attempt to use child's size (if constraints are bounded),
          // otherwise fallback to a default height to avoid infinite height scenarios.
          LayoutBuilder(builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight;
            final usedHeight = hasBoundedHeight ? constraints.maxHeight : 600.0;
            final size = Size(constraints.maxWidth, usedHeight);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final tangent = _computeHeadTangentForSize(size, _controller.value);
                final headPos = tangent?.position ?? const Offset(-1000, -1000);
                final headAngle = tangent?.angle ?? 0.0;

                return SizedBox(
                  height: usedHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _SnakeSinglePainterWithParams(
                          progress: _controller.value,
                          color: widget.color,
                          strokeWidth: widget.strokeWidth,
                          snakeLength: widget.snakeLength,
                          borderRadius: widget.borderRadius,
                          tailSegments: widget.tailSegments,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: usedHeight,
                          child: widget.child,
                        ),
                      ),
                      Positioned(
                        left: headPos.dx - widget.heartSize / 2,
                        top: headPos.dy - widget.heartSize / 2,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: headAngle,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.favorite,
                              size: widget.heartSize,
                              color: widget.heartColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          });
  }
}

/// The painter used above (same as earlier). Keep this in your file.
/// I assume you already have this class; if not, paste the implementation from your working version:
class _SnakeSinglePainterWithParams extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double strokeWidth;
  final double snakeLength;
  final BorderRadius borderRadius;
  final int tailSegments;

  _SnakeSinglePainterWithParams({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.snakeLength,
    required this.borderRadius,
    required this.tailSegments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (t, m) => t + m.length);
    if (totalLength <= 0) return;

    final start = (progress * totalLength) % totalLength;
    final end = start + snakeLength;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    void drawRangeNoWrap(double a, double b, Paint p) {
      double consumed = 0.0;
      for (final metric in metrics) {
        final segLen = metric.length;
        final segStartGlobal = consumed;
        final segEndGlobal = consumed + segLen;

        final overlapStart = math.max(a, segStartGlobal);
        final overlapEnd = math.min(b, segEndGlobal);

        if (overlapEnd > overlapStart) {
          final localS = overlapStart - segStartGlobal;
          final localE = overlapEnd - segStartGlobal;
          final extracted = metric.extractPath(localS, localE);
          canvas.drawPath(extracted, p);
        }

        consumed += segLen;
        if (consumed >= b) break;
      }
    }

    void drawRange(double a, double b, Paint p) {
      final normA = a % totalLength;
      final normB = b % totalLength;

      if (b - a >= totalLength) {
        drawRangeNoWrap(0.0, totalLength, p);
        return;
      }

      if (normA < normB) {
        drawRangeNoWrap(normA, normB, p);
      } else {
        drawRangeNoWrap(normA, totalLength, p);
        if (normB > 0) drawRangeNoWrap(0.0, normB, p);
      }
    }

    if (tailSegments <= 1) {
      paint.color = color;
      drawRange(start, end, paint);
    } else {
      final part = snakeLength / tailSegments;
      for (int i = 0; i < tailSegments; i++) {
        final segA = start + (i * part);
        final segB = segA + part;

        final t = (i + 1) / tailSegments;
        final alpha = (t * 255).round().clamp(20, 255);
        paint.color = color.withAlpha(alpha);
        drawRange(segA, segB, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeSinglePainterWithParams old) {
    return old.progress != progress ||
        old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.snakeLength != snakeLength ||
        old.tailSegments != tailSegments;
  }
}
