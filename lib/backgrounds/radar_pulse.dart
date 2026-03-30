import 'package:flutter/material.dart';
import 'dart:math' as math;

class RadarPulseBackground extends StatefulWidget {
  final bool isPaused;
  final bool isWorking;
  final bool isLowPerformance;
  const RadarPulseBackground({super.key, this.isPaused = false, this.isWorking = false, this.isLowPerformance = false});
  @override
  State<RadarPulseBackground> createState() => _RadarPulseBackgroundState();
}

class _RadarPulseBackgroundState extends State<RadarPulseBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
       vsync: this, 
       duration: widget.isWorking ? const Duration(seconds: 4) : const Duration(seconds: 12)
    );
    if (!widget.isPaused) _ctrl.repeat();
  }
  
  @override
  void didUpdateWidget(RadarPulseBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isWorking != oldWidget.isWorking) {
       _ctrl.duration = widget.isWorking ? const Duration(seconds: 4) : const Duration(seconds: 12);
       if (!widget.isPaused && widget.isWorking) {
         _ctrl.repeat();
       } else {
         _ctrl.stop();
       }
    }

    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused || !widget.isWorking) {
        _ctrl.stop();
      } else {
        _ctrl.repeat();
      }
    }
  }
  
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        color: const Color(0xFF02090C),
        child: CustomPaint(
          painter: RadarPainter(_ctrl.value, widget.isLowPerformance),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double p;
  final bool isLowPerformance;
  RadarPainter(this.p, this.isLowPerformance);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final accentGreen = Colors.greenAccent;

    // 1. Grid / Scanlines
    final gridPaint = Paint()..color = accentGreen.withValues(alpha: 0.05)..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Concentric Circles (The "distance" rings)
    for (int i = 1; i <= 5; i++) {
       canvas.drawCircle(center, (maxRadius / 5) * i, Paint()..color = accentGreen.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }

    // 3. The Sweep Line (THE SPIN)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [accentGreen.withValues(alpha: 0), accentGreen.withValues(alpha: 0.5), accentGreen.withValues(alpha: 0)],
        stops: const [0.0, 0.95, 1.0],
        transform: GradientRotation(p * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    
    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 4. Glowing Pulses
    for (int i = 0; i < 3; i++) {
      double ringP = (p + i / 3.0) % 1.0;
      double radius = ringP * maxRadius;
      double opacity = 0.3 * (1.0 - ringP);
      canvas.drawCircle(center, radius, Paint()..color = accentGreen.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5 + (2 * ringP));
    }

    // 5. Random "Blips" - Optimized for thermal performance
    final blipPaint = Paint()..color = accentGreen;
    if (!isLowPerformance) blipPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final blipPositions = [
       Offset(size.width * 0.3, size.height * 0.4),
       Offset(size.width * 0.8, size.height * 0.2),
       Offset(size.width * 0.6, size.height * 0.7),
       Offset(size.width * 0.1, size.height * 0.8),
    ];
    
    for (int i = 0; i < blipPositions.length; i++) {
        double angle = math.atan2(blipPositions[i].dy - center.dy, blipPositions[i].dx - center.dx);
        if (angle < 0) angle += 2 * math.pi;
        double sweepAngle = (p * 2 * math.pi) % (2 * math.pi);
        
        double diff = (sweepAngle - angle).abs();
        if (diff < 0.2 || diff > 2 * math.pi - 0.2) {
           canvas.drawCircle(blipPositions[i], 3, blipPaint);
           canvas.drawCircle(blipPositions[i], 12, Paint()..color = accentGreen.withValues(alpha: 0.15));
        }
    }

    // 6. Central Glow
    canvas.drawCircle(center, 5, Paint()..color = accentGreen..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  @override
  bool shouldRepaint(RadarPainter old) => old.p != p;
}
