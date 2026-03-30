import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidFlowBackground extends StatefulWidget {
  final bool isPaused;
  const LiquidFlowBackground({super.key, this.isPaused = false});
  @override
  State<LiquidFlowBackground> createState() => _LiquidFlowBackgroundState();
}

class _LiquidFlowBackgroundState extends State<LiquidFlowBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (!widget.isPaused) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(LiquidFlowBackground oldWidget) {
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
        color: const Color(0xFF041221), // Deeper water floor
        child: CustomPaint(
          painter: WaterFlowPainter(_ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class WaterFlowPainter extends CustomPainter {
  final double p;
  WaterFlowPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      _drawWave(canvas, size, i);
    }
  }

  void _drawWave(Canvas canvas, Size size, int i) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.12 - (i * 0.03))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final yBase = size.height * (0.4 + i * 0.15);
    final amplitude = 25.0 + (i * 12);
    final frequency = 0.006 + (i * 0.002);
    
    // CRITICAL: phaseShift must be a multiple of p * pi * 2 for seamless looping
    final phaseShift = p * math.pi * 2;
    final layerOffset = i * 2.1; // Static offset per layer

    path.moveTo(0, size.height);
    path.lineTo(0, yBase);
    
    for (double x = 0; x <= size.width + 10; x += 10) {
      // Primary wave
      double y = yBase + math.sin(x * frequency + phaseShift + layerOffset) * amplitude;
      // Secondary harmonized wave (must also loop seamlessly)
      // We use 2.0 * phaseShift so it completes 2 cycles while p goes 0->1
      y += math.sin(x * (frequency * 1.5) + (phaseShift * 2.0) + layerOffset) * (amplitude * 0.4);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Subtle Highlights
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawPath(path, glintPaint);
  }

  @override
  bool shouldRepaint(WaterFlowPainter old) => old.p != p;
}
