import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlassVaultBackground extends StatefulWidget {
  final bool isPaused;
  const GlassVaultBackground({super.key, this.isPaused = false});
  @override
  State<GlassVaultBackground> createState() => _GlassVaultBackgroundState();
}

class _GlassVaultBackgroundState extends State<GlassVaultBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 40));
    if (!widget.isPaused) _ctrl.repeat();
  }
  
  @override
  void didUpdateWidget(GlassVaultBackground oldWidget) {
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
    final sz = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF02050A)),
            
            // Optimized Environment Lighting - Multiple orbs in one CustomPaint
            CustomPaint(
              painter: _OrbPainter(_ctrl.value),
              size: Size.infinite,
            ),
    
            // Thick Overlapping Glass Sheets - Simplified for performance
            _GlassSheet(w: sz.width * 1.8, h: sz.height * 0.45, rotation: 0.5, p: _ctrl.value, offset: 0.1),
            _GlassSheet(w: sz.width * 1.8, h: sz.height * 0.55, rotation: -0.3, p: _ctrl.value, offset: 0.6),
          ],
        )
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double p;
  _OrbPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrb(canvas, size, Colors.blueAccent, 0.0, 0.4, 0.3);
    _drawOrb(canvas, size, Colors.deepPurpleAccent, 0.5, 0.3, 0.4);
    _drawOrb(canvas, size, Colors.cyanAccent, 1.2, 0.5, 0.5);
  }

  void _drawOrb(Canvas canvas, Size size, Color color, double offset, double dx, double dy) {
    final x = size.width * 0.5 + math.cos(p * math.pi * 2 + offset) * size.width * dx;
    final y = size.height * 0.5 + math.sin(p * math.pi * 2 + offset) * size.height * dy;
    
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 150));
    
    canvas.drawCircle(Offset(x, y), 150, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.p != p;
}

class _GlassSheet extends StatelessWidget {
  final double w, h, rotation, p, offset;
  const _GlassSheet({required this.w, required this.h, required this.rotation, required this.p, required this.offset});

  @override
  Widget build(BuildContext context) {
    // Seamless translation
    final xOff = math.sin(p * math.pi * 2 + offset) * 40;
    final yOff = math.cos(p * math.pi * 2 + offset) * 80;

    return Positioned(
      left: -w * 0.1 + xOff,
      top: 100 + yOff,
      child: Transform.rotate(
        angle: rotation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: w, height: h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.01),
                  ],
                ),
              ),
              child: Stack(
                children: [
                   // Seamless Specular Glint
                   Positioned.fill(
                     child: CustomPaint(
                       painter: _GlintPainter((p + offset) % 1.0),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  final double progress;
  _GlintPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Glint moves from -50% to 150% of width for a clean sweep
    final double x = -w * 0.5 + (progress * w * 2);
    
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, 0, w * 0.5, h));
    
    canvas.drawRect(Rect.fromLTWH(x, 0, w * 0.5, h), paint);
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.progress != progress;
}
