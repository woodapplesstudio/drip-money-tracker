import 'package:flutter/material.dart';

class WealthParticleBackground extends StatefulWidget {
  final bool isPaused;
  final bool isLowPerformance;
  const WealthParticleBackground({super.key, this.isPaused = false, this.isLowPerformance = false});

  @override
  State<WealthParticleBackground> createState() => _WealthParticleBackgroundState();
}

class _WealthParticleBackgroundState extends State<WealthParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    if (!widget.isPaused) _ctrl.repeat();
  }
  @override
  void didUpdateWidget(WealthParticleBackground oldWidget) {
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
        builder: (context, _) => Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFF1E140A), // Deep Chocolate Brown
                Color(0xFF0F0A05), // Dark Sepia
                Color(0xFF050301), // Near Black
              ],
            ),
          ),
          child: CustomPaint(
            painter: WealthPainter(_ctrl.value, widget.isLowPerformance),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class WealthPainter extends CustomPainter {
  final double p;
  final bool isLowPerformance;
  static final Map<String, TextPainter> _cachedTP = {};

  WealthPainter(this.p, this.isLowPerformance);

  TextPainter _getTP(String sym, double size) {
    final key = "$sym-$size";
    if (!_cachedTP.containsKey(key)) {
      _cachedTP[key] = TextPainter(
        text: TextSpan(
          text: sym,
          style: TextStyle(color: Colors.amberAccent.withValues(alpha: 0.5), fontSize: size, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _cachedTP[key]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final List<String> symbols = ["₱", "\$", "€", "₿", "¥"];
    final count = isLowPerformance ? 10 : (size.width < 300 ? 12 : 30); 
    final scale = size.width < 300 ? 0.6 : 1.0;

    for (int i = 0; i < count; i++) {
        double x = (0.05 + (i * 0.13) + p * (1 + (i % 2))) % 1.0 * size.width;
        double y = (0.05 + (i * 0.19) + p * (1 + (i % 3))) % 1.0 * size.height;
       
       final double fontSize = (18 + (i % 12).toDouble()) * scale;
       final tp = _getTP(symbols[i % symbols.length], fontSize);
       
       tp.paint(canvas, Offset(x, y));
    }
  }
  @override
  bool shouldRepaint(covariant WealthPainter oldDelegate) => oldDelegate.p != p;
}
