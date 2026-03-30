import 'package:flutter/material.dart';

class CyberGridBackground extends StatefulWidget {
  final bool isPaused;
  const CyberGridBackground({super.key, this.isPaused = false});

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (!widget.isPaused) _ctrl.repeat();
  }
  @override
  void didUpdateWidget(CyberGridBackground oldWidget) {
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
      builder: (context, _) => CustomPaint(
        painter: GridPainter(_ctrl.value),
        child: Container(),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double progress;
  GridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;

    final double h = size.height;
    final double w = size.width;
    final double midX = w / 2;
    final double horizon = h * 0.4;

    for (int i = -15; i <= 15; i++) {
       canvas.drawLine(Offset(midX + i * 80, h), Offset(midX + i * 15, horizon), paint);
    }

    for (int i = 0; i < 25; i++) {
      double yVal = horizon + (h - horizon) * ((i + progress) / 25);
      canvas.drawLine(Offset(0, yVal), Offset(w, yVal), paint);
    }
  }
  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.progress != progress;
}
