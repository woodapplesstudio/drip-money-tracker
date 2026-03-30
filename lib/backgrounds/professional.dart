import 'package:flutter/material.dart';


class ProfessionalBackground extends StatefulWidget {
  final bool isPaused;
  const ProfessionalBackground({super.key, this.isPaused = false});
  @override
  State<ProfessionalBackground> createState() => _ProfessionalBackgroundState();
}
class _ProfessionalBackgroundState extends State<ProfessionalBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    if (!widget.isPaused) _ctrl.repeat(reverse: true);
  }
  @override
  void didUpdateWidget(ProfessionalBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _ctrl.stop();
      } else {
        _ctrl.repeat(reverse: true);
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
        builder: (context, _) => CustomPaint(
          painter: ProfessionalPainter(_ctrl.value),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D14), Color(0xFF0A0A0A), Color(0xFF111118)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ProfessionalPainter extends CustomPainter {
  final double p;
  ProfessionalPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    
    const gridSize = 50.0; // Increased
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final baseline = size.height * 0.7;
    path.moveTo(0, baseline);
    
    // Optimized step
    for (double x = 0; x <= size.width + 4; x += 4) {
      final wave1 = 12 * (0.5 + 0.5 * _sin((x / (size.width + 1) + p) * 2 * 3.14159));
      final wave2 = 5 * (0.5 + 0.5 * _sin((x / (size.width + 1) * 3 + p * 2) * 2 * 3.14159));
      path.lineTo(x, baseline - wave1 - wave2);
    }
    canvas.drawPath(path, linePaint);

    // Replace MaskFilter.blur with RadialGradient for massive speedup
    final accentPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 0.04 + 0.02 * p),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, 0), radius: 300));
    
    canvas.drawCircle(Offset(size.width, 0), 300, accentPaint);
  }
  double _sin(double x) {
    // Approximate sine for performance
    x = x % (2 * 3.14159);
    return x < 3.14159
      ? (4 * x * (3.14159 - x)) / (3.14159 * 3.14159) * 0.9
      : -((4 * (x - 3.14159) * (6.28318 - x)) / (3.14159 * 3.14159)) * 0.9;
  }
  @override
  bool shouldRepaint(ProfessionalPainter old) => old.p != p;
}
