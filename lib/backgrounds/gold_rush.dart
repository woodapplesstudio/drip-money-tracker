import 'package:flutter/material.dart';
import 'dart:math' as math;

class GoldRushBackground extends StatefulWidget {
  final bool isPaused;
  final bool isWorking; 
  final bool isLowPerformance;
  const GoldRushBackground({super.key, this.isPaused = false, this.isWorking = false, this.isLowPerformance = false});

  @override
  State<GoldRushBackground> createState() => _GoldRushBackgroundState();
}

class _GoldRushBackgroundState extends State<GoldRushBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final math.Random _random = math.Random();
  final List<_FallingCoin> _coins = [];
  double _lastDropTime = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _ctrl.addListener(_updatePhysics);
    if (!widget.isPaused && widget.isWorking) _ctrl.repeat();
  }

  void _updatePhysics() {
    if (widget.isPaused) return;
    
    final double currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Drop coins if working
    final double spawnRate = widget.isLowPerformance ? 1.2 : 0.4;
    if (widget.isWorking && currentTime - _lastDropTime > spawnRate) {
       _coins.add(_FallingCoin(
          x: _random.nextDouble(),
          y: -0.1,
          v: 0.2 + _random.nextDouble() * 0.4,
          rotation: _random.nextDouble() * math.pi * 2,
          rSpeed: (_random.nextDouble() - 0.5) * 3,
          scale: 0.5 + _random.nextDouble() * 0.8,
          startTime: currentTime,
       ));
       _lastDropTime = currentTime;
    }

    // Update and prune
    _coins.removeWhere((c) => currentTime - c.startTime > 8.0 || c.y > 0.95);
    for (var c in _coins) {
       double dt = 0.016; // 60fps
       c.y += c.v * dt;
       c.rotation += c.rSpeed * dt;
       // Add some horizontal drift
       c.x += math.sin(currentTime + c.startTime) * 0.002;
    }
    
    // performance: Only rebuild if there are coins to show or if we are actively working
    if (_coins.isNotEmpty || widget.isWorking) {
       setState(() {});
    } else {
       _ctrl.stop(); // No more work, no more coins => stop updates
    }
  }

  @override
  void didUpdateWidget(GoldRushBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused || widget.isWorking != oldWidget.isWorking) {
       if (widget.isPaused || !widget.isWorking) {
          // Note: If coins exist, the _updatePhysics will stop the controller Once they fall.
          if (_coins.isEmpty) _ctrl.stop(); 
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0B01), // Deep dark gold-tinted black
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. DYNAMIC: Falling coins
          CustomPaint(
            painter: _GoldRushPainter(_coins),
            size: Size.infinite,
          ),
          // 2. STATIC: Wealth floor (treated as an asset)
          RepaintBoundary(
            child: _StaticWealthFloor(isLowPerformance: widget.isLowPerformance),
          ),
        ],
      ),
    );
  }
}

class _StaticWealthFloor extends StatelessWidget {
  final bool isLowPerformance;
  const _StaticWealthFloor({this.isLowPerformance = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WealthFloorPainter(isLowPerformance),
      size: Size.infinite,
    );
  }
}

class _WealthFloorPainter extends CustomPainter {
  final TextPainter _tp;
  final bool isLowPerformance;
  _WealthFloorPainter(this.isLowPerformance) : _tp = TextPainter(
    text: const TextSpan(text: "\$", style: TextStyle(color: Color(0xFFB8860B), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final sRand = math.Random(777);
    final gold = const Color(0xFFFFD700);
    final darkGold = const Color(0xFFB8860B);

    final int floorCount = isLowPerformance ? 100 : 400;
    for (int i = 0; i < floorCount; i++) { 
        double x = sRand.nextDouble() * size.width;
        double yFactor = math.pow(sRand.nextDouble(), 0.7).toDouble(); 
        double y = size.height - (yFactor * 100);
        double scale = 0.3 + sRand.nextDouble() * 0.5;
        double rot = sRand.nextDouble() * math.pi * 2;
        double opacity = 0.5 + (0.3 * (1 - yFactor));

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rot);
        canvas.scale(scale);
        
        canvas.drawCircle(Offset.zero, 10, Paint()..color = darkGold.withValues(alpha: opacity));
        canvas.drawCircle(Offset.zero, 8, Paint()..color = gold.withValues(alpha: opacity));
        _tp.paint(canvas, Offset(-_tp.width / 2, -_tp.height / 2));
        
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FallingCoin {
  double x, y, v, rotation, rSpeed, scale;
  final double startTime;
  _FallingCoin({required this.x, required this.y, required this.v, required this.rotation, required this.rSpeed, required this.scale, required this.startTime});
}

class _GoldRushPainter extends CustomPainter {
  final List<_FallingCoin> coins;
  final TextPainter _tp;

  _GoldRushPainter(this.coins) : _tp = TextPainter(
    text: const TextSpan(text: "\$", style: TextStyle(color: Color(0xFFB8860B), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = const Color(0xFFFFD700);
    final darkGold = const Color(0xFFB8860B);

    for (var c in coins) {
       canvas.save();
       canvas.translate(c.x * size.width, c.y * size.height);
       canvas.rotate(c.rotation);
       canvas.scale(c.scale);
       
       canvas.drawCircle(Offset.zero, 14, Paint()..color = darkGold);
       canvas.drawCircle(Offset.zero, 12, Paint()..color = gold);
       _tp.paint(canvas, Offset(-_tp.width / 2, -_tp.height / 2));
       
       canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GoldRushPainter old) => true; 
}
