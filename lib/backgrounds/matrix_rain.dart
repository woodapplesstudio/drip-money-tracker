import 'package:flutter/material.dart';

class MatrixRainBackground extends StatefulWidget {
  final bool isPaused;
  final bool isLowPerformance;
  const MatrixRainBackground({super.key, this.isPaused = false, this.isLowPerformance = false});
  @override
  State<MatrixRainBackground> createState() => _MatrixRainBackgroundState();
}
class _MatrixRainBackgroundState extends State<MatrixRainBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15));
    if (!widget.isPaused) _ctrl.repeat();
  }
  @override
  void didUpdateWidget(MatrixRainBackground oldWidget) {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF050F05)),
          CustomPaint(painter: MatrixRainPainter(_ctrl.value, widget.isLowPerformance)),
        ],
      )
    );
  }
}
class MatrixRainPainter extends CustomPainter {
  final double p;
  final bool isLowPerformance;
  
  // Separate caches for performance
  static final Map<String, TextPainter> _headTP = {};
  static final Map<String, TextPainter> _trailTP = {};

  MatrixRainPainter(this.p, this.isLowPerformance);

  TextPainter _getHeadTP(String char) {
    if (!_headTP.containsKey(char)) {
      _headTP[char] = TextPainter(
        text: TextSpan(
          text: char, 
          style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.greenAccent.withValues(alpha: 0.8), blurRadius: 8)])
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _headTP[char]!;
  }

  TextPainter _getTrailTP(String char) {
    if (!_trailTP.containsKey(char)) {
      _trailTP[char] = TextPainter(
        text: TextSpan(
          text: char, 
          style: const TextStyle(color: Color(0xFF00CC44), fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500)
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _trailTP[char]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const chars = ['0','1','₱','\$','€','↑','↓','█','▒','░'];
    final colWidth = isLowPerformance ? 48.0 : 32.0; 
    final cols = (size.width / colWidth).ceil();
    

    for (int c = 0; c < cols; c++) {
      final seed = c * 7919;
      final speed = 0.3 + (seed % 5) * 0.12; 
      final offset = (seed % 100) / 100.0;
      final progress = (p * speed + offset) % 1.0;
      
      final startY = progress * (size.height + 250) - 125;
      final numChars = isLowPerformance ? 12 : 24; 
      
      for (int r = 0; r < numChars; r++) {
        final charY = startY - r * 18;
        if (charY < -30 || charY > size.height + 30) continue;
        
        final double opacity = r == 0 ? 1.0 : (1.0 - r / numChars) * 0.5;
        final String char = chars[(seed + r) % chars.length];
        
        if (r == 0) {
           _getHeadTP(char).paint(canvas, Offset(c * colWidth, charY));
        } else {
           final tp = _getTrailTP(char);
           canvas.saveLayer(
             Rect.fromLTWH(c * colWidth, charY, tp.width, tp.height),
             Paint()..color = Colors.black.withValues(alpha: opacity), // Use alpha to blend the painter
           );
           tp.paint(canvas, Offset(c * colWidth, charY));
           canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(MatrixRainPainter old) => old.p != p;
}
