import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class HeroBattleBackground extends StatefulWidget {
  final bool isPaused;
  final bool isWorking;
  final bool isLowPerformance;

  const HeroBattleBackground({
    super.key, 
    required this.isPaused, 
    required this.isWorking,
    this.isLowPerformance = false,
  });

  @override
  State<HeroBattleBackground> createState() => _HeroBattleBackgroundState();
}

class _HeroBattleBackgroundState extends State<HeroBattleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rand = Random();
  
  // Parallax Offsets
  double _skyOffset = 0.0;
  double _mtnOffset = 0.0;
  double _forestOffset = 0.0;
  double _nearForestOffset = 0.0;
  double _floorOffset = 0.0;

  // Render Seeds
  final List<double> _mtnHeights = List.generate(12, (_) => 100.0 + Random().nextDouble() * 120.0);
  final List<double> _treeSpacings = List.generate(15, (_) => 140.0 + Random().nextDouble() * 180.0);
  final List<double> _treeHeights = List.generate(15, (_) => 80.0 + Random().nextDouble() * 100.0);

  // States
  double _heroBounce = 0.0;
  double _monsterX = 1.35; 
  int _monsterType = 0; 
  bool _monsterDying = false;
  double _monsterDieAnim = 0.0;
  final List<_GoldParticle> _gold = [];
  double _prevHeroBounce = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40));
    if (!widget.isPaused) _controller.repeat();
    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(HeroBattleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  void _update() {
    if (widget.isPaused) return;

    setState(() {
      double speed = widget.isWorking ? 0.3 : 0.08;
      
      _skyOffset = (_skyOffset + 0.00001) % 1.0;
      _mtnOffset = (_mtnOffset + 0.00006 * speed) % 1.0;
      _forestOffset = (_forestOffset + 0.0004 * speed) % 1.0;
      _nearForestOffset = (_nearForestOffset + 0.001 * speed) % 1.0;
      _floorOffset = (_floorOffset + 0.003 * speed) % 1.0;

      _prevHeroBounce = _heroBounce;
      _heroBounce = sin(_controller.value * 50 * 2 * pi); // ~314.15, ensures seamless reset at 0.0/1.0

      if (widget.isWorking) {
        if (!_monsterDying) {
          // Monster approaches the strike zone (0.43)
          _monsterX = max(0.43, _monsterX - 0.007); 
 
          // TRIGGER DEATH: When monster reached the strike zone AND hero hits the bottom of the bounce
          // (Signaler: current bounce is up, prev was down => just hit the bottom)
          if (_monsterX <= 0.45 && _prevHeroBounce < _heroBounce && _prevHeroBounce < -0.98) { 
            _monsterX = 0.43; // Snap to hit position
            _monsterDying = true;
            _monsterDieAnim = 0.0;
            final int particleCount = widget.isLowPerformance ? 3 : 9;
            for (int i = 0; i < particleCount; i++) {
              _gold.add(_GoldParticle(
                x: 0.43 + _rand.nextDouble() * 0.05,
                y: 0.7 + _rand.nextDouble() * 0.05, 
                vx: _rand.nextDouble() * 0.03 - 0.015,
                vy: -_rand.nextDouble() * 0.05 - 0.01,
              ));
            }
          }
        } else {
          _monsterDieAnim += 0.04; // Slower, weightier death
          if (_monsterDieAnim >= 1.0) {
            _monsterDying = false;
            _monsterX = 1.35;
            _monsterType = _rand.nextInt(6);
          }
        }
      } else {
        if (_monsterX < 1.35) _monsterX += 0.03;
        _monsterDying = false;
      }

      for (var p in _gold) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.0025;
      }
      _gold.removeWhere((p) => p.y > 1.1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _BattlePainter(
            skyOffset: _skyOffset,
            mtnOffset: _mtnOffset,
            forestOffset: _forestOffset,
            nearForestOffset: _nearForestOffset,
            floorOffset: _floorOffset,
            heroBounce: _heroBounce,
            monsterX: _monsterX,
            monsterType: _monsterType,
            monsterDieAnim: _monsterDieAnim,
            monsterDying: _monsterDying,
            isWorking: widget.isWorking,
            gold: List.from(_gold),
            mtnHeights: _mtnHeights,
            treeHeights: _treeHeights,
            treeSpacings: _treeSpacings,
            isLowPerformance: widget.isLowPerformance,
          ),
        ),
      ),
    );
  }
}

class _GoldParticle {
  double x, y, vx, vy;
  _GoldParticle({required this.x, required this.y, required this.vx, required this.vy});
}

class _BattlePainter extends CustomPainter {
  final double skyOffset, mtnOffset, forestOffset, nearForestOffset, floorOffset, heroBounce, monsterX, monsterDieAnim;
  final int monsterType;
  final bool monsterDying, isWorking;
  final List<_GoldParticle> gold;
  final List<double> mtnHeights, treeHeights, treeSpacings;
  final bool isLowPerformance;

  _BattlePainter({
    required this.skyOffset, 
    required this.mtnOffset,
    required this.forestOffset, 
    required this.nearForestOffset,
    required this.floorOffset,
    required this.heroBounce,
    required this.monsterX,
    required this.monsterType,
    required this.monsterDieAnim,
    required this.monsterDying,
    required this.isWorking,
    required this.gold,
    required this.mtnHeights,
    required this.treeHeights,
    required this.treeSpacings,
    this.isLowPerformance = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final h = size.height;
    final w = size.width;
    final int hour = DateTime.now().hour;
    
    // Time of Day Logic
    bool isDay = hour >= 7 && hour < 16;
    bool isSunset = hour >= 16 && hour < 19;
    bool isNight = !isDay && !isSunset;

    // REDUCED PLATFORM HEIGHT
    double yHorizon = h * 0.72;

    // 1. SKY & BACKGROUND COLORS
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    List<Color> skyColors;
    Color mountainColor;
    Color forestFarColor;
    Color forestNearColor;
    Color floorColor;
    Color gridLineColor;

    if (isDay) {
      skyColors = [const Color(0xFF4A90E2), const Color(0xFF87CEEB)];
      mountainColor = const Color(0xFF5D6D7E);
      forestFarColor = const Color(0xFF1E5128);
      forestNearColor = const Color(0xFF191A19);
      floorColor = const Color(0xFF1A1A1A);
      gridLineColor = Colors.white.withValues(alpha: 0.05);
    } else if (isSunset) {
      skyColors = [const Color(0xFF2C3E50), const Color(0xFFFD746C)];
      mountainColor = const Color(0xFF4A3B31);
      forestFarColor = const Color(0xFF2E2219);
      forestNearColor = const Color(0xFF1A0F0A);
      floorColor = const Color(0xFF0F0B08);
      gridLineColor = Colors.orangeAccent.withValues(alpha: 0.05);
    } else {
      skyColors = [const Color(0xFF010206), const Color(0xFF060812)];
      mountainColor = const Color(0xFF0C0E1A);
      forestFarColor = const Color(0xFF05100B);
      forestNearColor = const Color(0xFF030806);
      floorColor = const Color(0xFF080808);
      gridLineColor = Colors.white.withValues(alpha: 0.01);
    }

    canvas.drawRect(skyRect, Paint()..shader = LinearGradient(
      colors: skyColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(skyRect));

    // 1.5 CELESTIAL BODY (Sun/Moon) - Softened opacity
    final celestialPaint = Paint();
    if (isDay || isSunset) {
      celestialPaint.color = (isDay ? Colors.amberAccent : Colors.orangeAccent).withValues(alpha: 0.15);
      if (!isLowPerformance) {
         celestialPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, isDay ? 50 : 80);
      }
      canvas.drawCircle(Offset(w * 0.75, isDay ? h * 0.2 : h * 0.55), isDay ? 70 : 85, celestialPaint);
      canvas.drawCircle(Offset(w * 0.75, isDay ? h * 0.2 : h * 0.55), isDay ? 35 : 50, Paint()..color = (isDay ? Colors.yellow : Colors.deepOrangeAccent).withValues(alpha: 0.25));
    } else {
      // Moon for night - Ethereal silver
      canvas.drawCircle(Offset(w * 0.75, h * 0.2), 30, Paint()..color = Colors.white.withValues(alpha: 0.25));
      if (!isLowPerformance) {
        canvas.drawCircle(Offset(w * 0.75, h * 0.2), 45, Paint()..color = Colors.white.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));
      }
    }

    // Stars - Only at night or sunset (faintly)
    if (!isDay) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: isNight ? 0.1 : 0.03)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
      final Random sR = Random(42);
      final List<Offset> starPoints = [];
      final int starCount = isLowPerformance ? 20 : 60;
      for (int i = 0; i < starCount; i++) {
          starPoints.add(Offset(sR.nextDouble() * w, sR.nextDouble() * h * 0.68));
      }
      canvas.drawPoints(PointMode.points, starPoints, starPaint);
    }

    // 2. MOUNTAINS
    _drawSeamlessMountains(canvas, size, mtnOffset, yHorizon * 0.85, mountainColor);

    // 3. FOREST LAYERS
    _drawSeamlessForest(canvas, size, forestOffset, yHorizon * 0.98, forestFarColor, 0.85);
    _drawSeamlessForest(canvas, size, nearForestOffset, yHorizon, forestNearColor, 1.25);

    // 4. FLOOR
    canvas.drawRect(Rect.fromLTWH(0, yHorizon, w, h - yHorizon), Paint()..color = floorColor);
    final detailPaint = Paint()..color = gridLineColor;
    for (int i = 0; i < 12; i++) {
        double lx = ((i / 12.0 + floorOffset) % 1.0) * w;
        canvas.drawLine(Offset(lx, yHorizon), Offset(lx, h), detailPaint);
    }

    // 5. CAPSULE HERO
    _drawCapsuleHero(canvas, w * 0.28, yHorizon);

    // 6. MONSTER
    if (monsterX < 1.35) {
       _drawMonster(canvas, monsterX * w, yHorizon);
    }

    // 7. GOLD - Reduced blur impact
    final goldP = Paint()..color = const Color(0xFFFFD700);
    for (var p in gold) {
      canvas.drawCircle(Offset(p.x * w, p.y * h), 3, goldP);
    }
  }

  void _drawSeamlessMountains(Canvas canvas, Size size, double offset, double yBase, Color color) {
      final paint = Paint()..color = color;
      final double width = size.width * 2.2;
      void drawP(double xS) {
          final path = Path();
          path.moveTo(xS, size.height);
          for (int i = 0; i <= mtnHeights.length; i++) {
              double tx = xS + (i / mtnHeights.length.toDouble()) * width;
              double hVal = mtnHeights[i % mtnHeights.length];
              if (i == 0) {
                  path.lineTo(tx, yBase - hVal * 0.4);
              } else {
                  double midX = tx - (width / mtnHeights.length) / 2;
                  path.quadraticBezierTo(midX, yBase - hVal * 1.3, tx, yBase - hVal * 0.4);
              }
          }
          path.lineTo(xS + width, size.height);
          path.close();
          canvas.drawPath(path, paint);
      }
      double xB = -offset * width;
      drawP(xB); drawP(xB + width);
  }

  void _drawSeamlessForest(Canvas canvas, Size size, double offset, double yBase, Color color, double scale) {
      final paint = Paint()..color = color;
      double currentWidth = 0.0;
      for (int i = 0; i < treeHeights.length; i++) {
          currentWidth += treeSpacings[i] * scale;
      }
      
      void drawT(double xS) {
          final forestPath = Path(); // Create ONE path per forest segment
          double tx = xS;
          for (int i = 0; i < treeHeights.length; i++) {
              double treeH = treeHeights[i] * scale;
              double treeW = 30 * scale;
              forestPath.moveTo(tx - treeW, yBase);
              forestPath.lineTo(tx, yBase - treeH);
              forestPath.lineTo(tx + treeW, yBase);
              tx += treeSpacings[i] * scale;
          }
          canvas.drawPath(forestPath, paint);
      }
      
      double xB = -offset * currentWidth * 3;
      xB = xB % currentWidth;
      drawT(xB - currentWidth); 
      drawT(xB); 
      drawT(xB + currentWidth);
  }

  void _drawCapsuleHero(Canvas canvas, double x, double y) {
    final frameP = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.fill;
    final goldNeon = const Color(0xFFFFD700);
    final glow = isLowPerformance ? null : (Paint()..color = goldNeon.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    
    double b = heroBounce * (isWorking ? 4 : 2);
    
    // 1. Body (Matte Black)
    canvas.drawRRect(RRect.fromLTRBAndCorners(x - 15, y - 55 + b, x + 15, y + b, topLeft: const Radius.circular(15), topRight: const Radius.circular(15)), frameP);
    // Neon Trim
    final trimP = Paint()..color = goldNeon..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawRRect(RRect.fromLTRBAndCorners(x - 15, y - 55 + b, x + 15, y + b, topLeft: const Radius.circular(15), topRight: const Radius.circular(15)), trimP);
    if (!isLowPerformance && glow != null) canvas.drawRRect(RRect.fromLTRBAndCorners(x - 15, y - 55 + b, x + 15, y + b, topLeft: const Radius.circular(15), topRight: const Radius.circular(15)), glow);
    
    // 2. Visor
    canvas.drawRect(Rect.fromLTWH(x + 5, y - 48 + b, 12, 6), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(x + 8, y - 46 + b, 8, 2), Paint()..color = goldNeon);

    // 4. PICKAXE (REMODELED)
    if (isWorking) {
        // --- PICKAXE EXPERIMENT VARIABLES ---
        // Cock back at Top (1.0), Hit at Bottom (-1.0)
        double phase = (heroBounce + 1.0) / 2.0; 
        double swing = 1.0 - (phase * 3.0); // -2.0 at Top, 1.0 at Bottom 
        
        // Pivot Point (Shoulder level)
       double pivotX = x + 12;
       double pivotY = y - 28 + b;
       
       canvas.save();
       canvas.translate(pivotX, pivotY);
       canvas.rotate(swing); 
       
       // Handle
       canvas.drawLine(const Offset(0, 0), const Offset(65, 0), Paint()..color = const Color(0xFF444444)..strokeWidth = 5..strokeCap = StrokeCap.round);
       
       // DOUBLE-HEADED GOLD PICK
       final axeHead = Path();
       axeHead.moveTo(60, -10);
       axeHead.quadraticBezierTo(54, 0, 60, 10);
       axeHead.lineTo(65, 30); // tip
       axeHead.quadraticBezierTo(75, 0, 65, -30); // curved back
       axeHead.close();
       
       canvas.drawPath(axeHead, Paint()..color = goldNeon..style = PaintingStyle.fill);
       if (!isLowPerformance) canvas.drawPath(axeHead, Paint()..color = goldNeon.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
       
       // Black structural circle (middle of pick head)
       canvas.drawCircle(const Offset(65, 0), 3, Paint()..color = Colors.black);
       
       if (phase < 0.15) {
          final impactP = Paint()..color = Colors.white.withValues(alpha: 0.8);
          if (!isLowPerformance) impactP.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
          canvas.drawCircle(const Offset(68, 0), 10, impactP);
       }
       canvas.restore();
    } else {
       canvas.save();
       canvas.translate(x + 15, y - 20 + b);
       canvas.rotate(1.2);
       canvas.drawLine(const Offset(0, 0), const Offset(45, 0), Paint()..color = const Color(0xFF444444)..strokeWidth = 3);
       canvas.restore();
    }
  }

  void _drawMonster(Canvas canvas, double x, double y) {
    double opacity = (monsterDying ? (1.0 - monsterDieAnim) : 1.0).clamp(0.0, 1.0);
    if (opacity <= 0) return;
    
    // Theme-matched Monster Colors
    const monsterColors = [
      Color(0xFF00FF88), // Matrix Green
      Color(0xFFFF00FF), // Cyberpunk Magenta
      Color(0xFF00E5FF), // Electric Cyan
      Color(0xFFFF3D00), // Crimson Red
      Color(0xFFD500F9), // Royal Purple
      Color(0xFFFFD700), // Gold
    ];
    
    Color mColor = monsterColors[monsterType % monsterColors.length];
    final paint = Paint()..color = mColor.withValues(alpha: opacity);
    
    double shake = monsterDying ? (sin(monsterDieAnim * 60) * 15) : 0;
    double sq = sin(heroBounce * 3) * 8;
    final path = Path();
    path.moveTo(x - 26 + shake, y);
    path.quadraticBezierTo(x + shake, y - 58 + sq, x + 26 + shake, y);
    path.close();
    
    if (!isLowPerformance) {
       final glowP = Paint()..color = mColor.withValues(alpha: 0.3 * opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
       canvas.drawPath(path, glowP);
    }
    
    canvas.drawPath(path, paint);
    final eyeP = Paint()..color = Colors.black.withValues(alpha: opacity);
    canvas.drawCircle(Offset(x - 8 + shake, y - 20 + sq / 2), 3, eyeP);
    canvas.drawCircle(Offset(x + 8 + shake, y - 20 + sq / 2), 3, eyeP);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! _BattlePainter) return true;
    return !isWorking ? (oldDelegate.heroBounce != heroBounce) : true;
  }
}
extension ColorAlphaSplit on Color {
  Color splitAlpha(double a) => withValues(alpha: a);
  Paint asPaint() => Paint()..color = this;
}
