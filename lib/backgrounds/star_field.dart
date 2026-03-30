import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarFieldBackground extends StatefulWidget {
  final bool isPaused;
  final bool isLowPerformance;
  const StarFieldBackground({super.key, this.isPaused = false, this.isLowPerformance = false});
  @override
  State<StarFieldBackground> createState() => _StarFieldBackgroundState();
}
class _StarFieldBackgroundState extends State<StarFieldBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 40));
    if (!widget.isPaused) _ctrl.repeat();
  }
  @override
  void didUpdateWidget(StarFieldBackground oldWidget) {
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
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF080820), Color(0xFF0A0A0A)],
                ),
              ),
            ),
            CustomPaint(painter: StarFieldPainter(_ctrl.value, widget.isLowPerformance)),
          ],
        )
      ),
    );
  }
}
class StarFieldPainter extends CustomPainter {
  final double p;
  final bool isLowPerformance;
  StarFieldPainter(this.p, this.isLowPerformance);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // 1. Deep Nebula Glows (Atmospheric) - No blurs here, just gradients
    if (!isLowPerformance) _drawNebula(canvas, size);

    final starCount = isLowPerformance ? 80 : (size.width < 300 ? 50 : 250); 
    for (int i = 0; i < starCount; i++) {
      final seed = i * 1447;
      final x3d = ((seed % 1000) / 500.0) - 1.0;
      final y3d = ((seed % 997) / 498.5) - 1.0;
      final baseZ = (seed % 100) / 100.0;
      
      final z = (baseZ - p * 6.0) % 1.0;
      if (z <= 0.01) continue;
      
      final depthScale = (1.0 - z).clamp(0.0, 1.0);
      final projX = cx + (x3d / z) * cx;
      final projY = cy + (y3d / z) * cy;
      
      if (projX < -50 || projX > size.width + 50 || projY < -50 || projY > size.height + 50) continue;

      final twinkle = 0.5 + 0.5 * math.sin(p * 50 + seed);
      
      Color coreColor = Colors.white;
      if (seed % 7 == 0) {
          coreColor = Colors.lightBlueAccent;
      } else if (seed % 11 == 0) {
          coreColor = Colors.orangeAccent;
      }
      
      final paint = Paint()
        ..color = coreColor.withValues(alpha: depthScale * twinkle)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.0 + (depthScale * 2.5);

      final zPrev = z + 0.03 * (1.0 + depthScale);
      final pxPrev = cx + (x3d / zPrev) * cx;
      final pyPrev = cy + (y3d / zPrev) * cy;
      
      canvas.drawLine(Offset(pxPrev, pyPrev), Offset(projX, projY), paint);

      if (depthScale > 0.8) {
         canvas.drawCircle(Offset(projX, projY), paint.strokeWidth * 3, Paint()..color = coreColor.withValues(alpha: (depthScale - 0.8) * 0.2));
      }
    }
  }

  void _drawNebula(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.indigo.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, p1);
    
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.deepPurple.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.8), radius: size.width * 0.5));
    canvas.drawRect(Offset.zero & size, p2);
  }

  @override
  bool shouldRepaint(StarFieldPainter old) => old.p != p;
}
