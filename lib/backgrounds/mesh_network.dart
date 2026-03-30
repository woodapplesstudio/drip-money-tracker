import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshNetworkBackground extends StatefulWidget {
  final bool isPaused;
  final bool isLowPerformance;
  const MeshNetworkBackground({super.key, this.isPaused = false, this.isLowPerformance = false});
  @override
  State<MeshNetworkBackground> createState() => _MeshNetworkBackgroundState();
}

class _MeshNetworkBackgroundState extends State<MeshNetworkBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final math.Random _random = math.Random();
  final List<_MeshPoint> _points = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    
    // Create detailed mesh points
    int pointCount = widget.isLowPerformance ? 25 : 80;
    for (int i = 0; i < pointCount; i++) {
      _points.add(_MeshPoint(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speedX: (1 + _random.nextInt(3)) * (_random.nextBool() ? 1 : -1), // Speed as integer for seamless wrap
        speedY: (1 + _random.nextInt(3)) * (_random.nextBool() ? 1 : -1),
        pulseOffset: _random.nextDouble() * math.pi * 2,
      ));
    }
    
    if (!widget.isPaused) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(MeshNetworkBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _ctrl.stop();
      } else {
        _ctrl.repeat();
      }
    }
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        color: const Color(0xFF0B0C10),
        child: CustomPaint(
          painter: _MeshPainter(_points, _ctrl.value, widget.isLowPerformance),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MeshPoint {
  double x, y, speedX, speedY, pulseOffset;
  _MeshPoint({required this.x, required this.y, required this.speedX, required this.speedY, required this.pulseOffset});
}

class _MeshPainter extends CustomPainter {
  final List<_MeshPoint> points;
  final double p;
  final bool isLowPerformance;
  _MeshPainter(this.points, this.p, this.isLowPerformance);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.cyanAccent;
    final linePaint = Paint()..strokeWidth = 1.2;

    List<Offset> pts = [];
    for (var pt in points) {
      double x = (pt.x * size.width + p * pt.speedX * size.width) % size.width;
      double y = (pt.y * size.height + p * pt.speedY * size.height) % size.height;
      pts.add(Offset(x, y));
    }

    final maxDist = size.width * 0.3; // Relative to canvas size
    final skipStep = isLowPerformance ? 3 : (size.width < 300 ? 2 : 1);

    // Draw Connections
    for (int i = 0; i < pts.length; i += skipStep) {
      for (int j = i + skipStep; j < pts.length; j += skipStep) {
        final dist = (pts[i] - pts[j]).distance;
        if (dist < maxDist) {
          final opacity = (1.0 - dist / maxDist) * 0.2;
          
          // Pulse effect
          final pulse = (0.5 + 0.5 * math.sin(p * math.pi * 10 + points[i].pulseOffset)).clamp(0.0, 1.0);
          final pulseOpacity = opacity + (pulse * 0.15);
          
          linePaint.color = Colors.cyanAccent.withValues(alpha: pulseOpacity);
          canvas.drawLine(pts[i], pts[j], linePaint);
        }
      }
    }

    // Draw Nodes with Glow
    for (int i = 0; i < pts.length; i += skipStep) {
      if (!isLowPerformance) {
        final glowPaint = Paint()..color = Colors.cyanAccent.withValues(alpha: isLowPerformance ? 0.2 : 0.08); 
        if (!isLowPerformance) {
           glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        }
        canvas.drawCircle(pts[i], isLowPerformance ? 4 : 6, glowPaint);
      }
      canvas.drawCircle(pts[i], 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.p != p;
}
