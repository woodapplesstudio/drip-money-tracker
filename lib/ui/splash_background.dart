import 'dart:math' as math;
import 'package:flutter/material.dart';

class BrandedSplashBackground extends StatefulWidget {
  final double progress;
  const BrandedSplashBackground({super.key, required this.progress});
  @override
  State<BrandedSplashBackground> createState() => _BrandedSplashBackgroundState();
}

class _BrandedSplashBackgroundState extends State<BrandedSplashBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_DripParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    for (int i = 0; i < 40; i++) {
      _particles.add(_DripParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble() * 1.5,
        opacity: 0.1 + _random.nextDouble() * 0.4,
        size: 1 + _random.nextDouble() * 3,
      ));
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
          painter: _SplashPainter(_particles, _ctrl.value, widget.progress),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DripParticle {
  double x, y, speed, opacity, size;
  _DripParticle({required this.x, required this.y, required this.speed, required this.opacity, required this.size});
}

class _SplashPainter extends CustomPainter {
  final List<_DripParticle> particles;
  final double time;
  final double progress;
  _SplashPainter(this.particles, this.time, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;

    // 1. Perspective Grid
    double gridSpacing = 60.0;
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Rising Data Particles
    for (var p in particles) {
      final y = (p.y * size.height - (time * p.speed * 200)) % size.height;
      final paint = Paint()
        ..color = const Color(0xFF00FF88).withValues(alpha: p.opacity * (1.0 - (y / size.height)))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size);
      
      canvas.drawCircle(Offset(p.x * size.width, y), p.size, paint);
    }

    // 3. Central Radial Glow that expands with progress
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF88).withValues(alpha: 0.15 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Offset.zero & size, radialPaint);
  }

  @override
  bool shouldRepaint(_SplashPainter old) => true;
}
