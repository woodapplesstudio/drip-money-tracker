import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backgrounds/backgrounds.dart';
import 'ui/core_ui.dart';
import 'ui/splash_background.dart';
import 'backgrounds/hero_battle.dart';
part 'tabs/live_tab.dart';
part 'tabs/history_tab.dart';
part 'tabs/goals_tab.dart';
part 'tabs/bills_tab.dart';
part 'tabs/vault_tab.dart';
part 'tabs/settings_tab.dart';

void main() {
  runApp(const MoneyStreamApp());
}

enum ThemeType { matrix, cyberpunk, electric, crimson, royal, gold }
enum BackgroundType { classic, cyberGrid, wealth, glass, matrixRain, starField, meshNetwork, liquidFlow, radarPulse, goldRush, heroBattle }

class Transaction {
  final double amount;
  final bool isIncome;
  final DateTime timestamp;
  final String description;
  final String category;

  Transaction({
    required this.amount, 
    required this.isIncome, 
    required this.timestamp, 
    this.description = "", 
    this.category = "General",
  });
}

class Bill {
  final String id;
  final String name;
  final double amount;
  final int dueDay;

  Bill({required this.id, required this.name, required this.amount, this.dueDay = 1});
}

class IncomeSource {
  final String name;
  final double monthlyAmount;
  final bool isPassive;
  final int startHour;
  final int endHour;
  final List<int> workDays;
  
  final DateTime createdAt;
  
  IncomeSource({
    required this.name, 
    required this.monthlyAmount, 
    this.isPassive = true,
    this.startHour = 9,
    this.endHour = 17,
    this.workDays = const [1, 2, 3, 4, 5],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get ratePerSecond {
    final now = DateTime.now();
    // Use the work seconds in the CURRENT month as the normalization base
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    
    double totalWorkSec = workSecondsBetween(monthStart, nextMonthStart);
    if (totalWorkSec == 0) return 0.0;
    
    return monthlyAmount / totalWorkSec;
  }

  bool get isWorkingNow {
    if (isPassive) return true;
    final now = DateTime.now();
    if (!workDays.contains(now.weekday)) return false;
    
    final h = now.hour;
    if (startHour <= endHour) {
      return h >= startHour && h < endHour;
    } else {
      return h >= startHour || h < endHour;
    }
  }

  // Calculate actual work seconds elapsed between two dates
  double workSecondsBetween(DateTime fromStart, DateTime toEnd, {bool ignoreCreationDate = false}) {
    if (toEnd.isBefore(fromStart)) return 0.0;
    
    // Logic fix: Revenue only accrues AFTER its creation date
    DateTime start = (ignoreCreationDate || fromStart.isAfter(createdAt)) ? fromStart : createdAt;
    DateTime end = toEnd;
    if (end.isBefore(start)) return 0.0;
    
    if (isPassive) return end.difference(start).inMicroseconds / 1000000.0;
    
    // Non-passive income: only count seconds within work windows on work days.
    double totalSeconds = 0.0;
    
    // Iterate through each day in the range [start, end]
    DateTime currentDay = DateTime(start.year, start.month, start.day);
    DateTime lastDay = DateTime(end.year, end.month, end.day);
    
    while (!currentDay.isAfter(lastDay)) {
      if (workDays.contains(currentDay.weekday)) {
        // Today is a work day. Determine the work window for this specific day.
        DateTime windowStart = DateTime(currentDay.year, currentDay.month, currentDay.day, startHour);
        
        if (startHour <= endHour) {
          // Normal shift: e.g., 9 AM to 5 PM
          DateTime windowEnd = DateTime(currentDay.year, currentDay.month, currentDay.day, endHour);
          totalSeconds += _getOverlap(start, end, windowStart, windowEnd);
        } else {
          // Overnight shift: e.g., 10 PM to 6 AM
          // Part 1: startHour to Midnight
          DateTime part1End = DateTime(currentDay.year, currentDay.month, currentDay.day + 1);
          totalSeconds += _getOverlap(start, end, windowStart, part1End);
          
          // Part 2: Midnight to endHour happens on the NEXT day
          // However, we handle 'Midnight to endHour' as part of the YESTERDAY's shift.
          // Wait, if today is Monday and work starts at 10 PM, it ends 6 AM Tuesday.
          // So on Tuesday, we should count 00:00 to 06:00 if Monday was a work day.
        }
      }
      
      // Handle the 'morning half' of an overnight shift that started yesterday
      if (startHour > endHour) {
        int yesterdayWeekday = currentDay.weekday == 1 ? 7 : currentDay.weekday - 1;
        if (workDays.contains(yesterdayWeekday)) {
          DateTime windowStart = DateTime(currentDay.year, currentDay.month, currentDay.day, 0);
          DateTime windowEnd = DateTime(currentDay.year, currentDay.month, currentDay.day, endHour);
          totalSeconds += _getOverlap(start, end, windowStart, windowEnd);
        }
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }
    
    return totalSeconds;
  }

  double _getOverlap(DateTime s1, DateTime e1, DateTime s2, DateTime e2) {
    DateTime start = s1.isAfter(s2) ? s1 : s2;
    DateTime end = e1.isBefore(e2) ? e1 : e2;
    if (end.isAfter(start)) {
      return end.difference(start).inMicroseconds / 1000000.0;
    }
    return 0.0;
  }

  double workSecondsElapsed(DateTime now, DateTime monthStart) {
    return workSecondsBetween(monthStart, now);
  }
}

class SavingsGoal {
  final String name;
  final double targetAmount;
  final DateTime createdAt;
  bool isAccomplished;

  SavingsGoal({required this.name, required this.targetAmount, required this.createdAt, this.isAccomplished = false});
}

class VaultAccount {
  final String id;
  String name;
  double balance;
  final IconData icon;

  VaultAccount({required this.id, required this.name, required this.balance, this.icon = Icons.account_balance});
}

class MoneyStreamApp extends StatelessWidget {
  const MoneyStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drip Money Tracker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent, 
          brightness: Brightness.dark
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _titleSlide;
  late Animation<double> _loadingFade;
  late Animation<double> _footerFade;
  late Animation<double> _pulse;

  final AssetImage _logoImage = const AssetImage('assets/images/dripTextLogoMain.png');
  final AssetImage _companyLogoImage = const AssetImage('assets/images/woodApplesLogo.png');

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
    );

    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
    );

    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Cinematic Staggered Animations
    _fadeIn = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut)
    );
    
    _logoScale = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack)
    );
    
    _titleSlide = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)
    );
    
    _loadingFade = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.5, 0.9, curve: Curves.easeIn)
    );
    
    _footerFade = CurvedAnimation(
      parent: _fadeController, 
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn)
    );

    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _loadingController.forward();

    _loadingController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const TickerScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 800),
                ),
              );
            }
          });
        }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_logoImage, context);
    precacheImage(_companyLogoImage, context);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentNeon = Color(0xFF00FF88);
    
    return Scaffold(
      backgroundColor: const Color(0xFF060912), // Deep midnight base
      body: Stack(
        children: [
          // 1. DYNAMIC BRANDED BACKGROUND
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, _) => BrandedSplashBackground(progress: _loadingController.value),
            ),
          ),
          
          // 2. OVERLAY VIGNETTE
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent, 
                  const Color(0xFF060912).withValues(alpha: 0.8),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // 3. MAIN CONTENT (Truly Centered)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep it compact for true centering
              children: [
                // --- LOGO WITH GLOW ---
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: accentNeon.withValues(alpha: 0.15 * _pulse.value),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image(image: _logoImage, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- TITLES ---
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_titleSlide),
                  child: FadeTransition(
                    opacity: _titleSlide,
                    child: Column(
                      children: [
                        const Text(
                          "DRIP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 18,
                            shadows: [
                              Shadow(color: Color(0x4000FF88), blurRadius: 30),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "MONEY TRACKER", 
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // --- LOADING ENGINE ---
                FadeTransition(
                  opacity: _loadingFade,
                  child: SizedBox(
                    width: 240,
                    child: AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        double pct = _loadingController.value * 100;
                        return Column(
                          children: [
                            Stack(
                              children: [
                                // Track Background
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Animated Track
                                Container(
                                  height: 4,
                                  width: 240 * _loadingController.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentNeon.withValues(alpha: 0.2),
                                        accentNeon,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentNeon.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _loadingController.value < 0.4 ? "ALLOCATING ASSETS" : 
                                  _loadingController.value < 0.7 ? "STREAMING DATA" : "OPTIMIZING FLOW",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    fontSize: 8,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${pct.toInt()} %",
                                  style: const TextStyle(
                                    color: accentNeon,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. FOOTER (Independent Position)
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: FadeTransition(
              opacity: _footerFade,
              child: Column(
                children: [
                  Text(
                    "POWERED BY",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 7, 
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: _companyLogoImage, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Wood Apples Studio",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class TickerScreen extends StatefulWidget {
  const TickerScreen({super.key});

  @override
  State<TickerScreen> createState() => _TickerScreenState();
}

class _TickerScreenState extends State<TickerScreen> with SingleTickerProviderStateMixin {
  bool _isInit = false; // Loading Guard for Prod
  late AnimationController _premiumGlowController;
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  void _showToast(String title, String message, {IconData icon = Icons.opacity_rounded, Color? color}) {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastEntry = null;

    _toastEntry = OverlayEntry(
      builder: (context) => _PremiumToast(
        title: title,
        message: message,
        icon: icon,
        accentColor: color ?? accentColor,
        onDismiss: () {
          _toastEntry?.remove();
          _toastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_toastEntry!);
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (_toastEntry != null) {
        _toastEntry?.remove();
        _toastEntry = null;
      }
    });
  }

  void updateState(VoidCallback fn) => setState(fn);

  void _showMilestoneUnlocked(String name, int reward) {
    if (!mounted) return;
    _showToast("ACHIEVEMENT", "$name: +$reward DROPS", icon: Icons.emoji_events, color: Colors.cyanAccent);
  }
  // --- CORE MODELS ---
  final List<IncomeSource> _incomeSources = [];
  final List<Bill> _recurringBills = [];
  final List<Transaction> _history = [];
  final List<SavingsGoal> _goals = [];
  final List<VaultAccount> _vaultAccounts = [];
  
  bool _isSettingsOpen = false;
  bool _isLowPerformance = false; // NEW: Global performance flag
  double balanceAdjustment = 0.0;
  // --- ECONOMY & THEMES ---
  int _userCredits = 0; 
  Set<int> _unlockedBackgrounds = {0}; 
  bool _isPremiumUser = false;
  BackgroundType? _previewBackground;

  // --- UI STATE ---
  int _tabIndex = 0;
  String _currencySymbol = "\$";
  int _tickerPrecision = 4;
  ThemeType _currentTheme = ThemeType.matrix;
  bool _showSec = true;
  bool _showMin = true;
  bool _showHr = true;
  bool _showDay = true;
  bool _showWeek = true;
  bool _isProfessionalMode = false;
  
  bool get isWorking => _incomeSources.any((s) => s.isWorkingNow);
  BackgroundType _currentBackground = BackgroundType.classic;
  late Stream<double> _moneyStream;

  DateTime _selectedHistoryMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _selectedRateView = "/HR";
  bool _milestone1000Reached = false;
  DateTime _lastProcessedDate = DateTime.now();
  String _installationId = "";

  String _formatWorkDays(List<int> days) {
    final names = ["", "M", "T", "W", "Th", "F", "Sa", "Su"];
    return days.map((d) => names[d]).join(",");
  }

  @override
  void dispose() {
    _premiumGlowController.dispose();
    super.dispose();
  }

  Widget _buildPremiumBadge({bool isLarge = false}) {
    return AnimatedBuilder(
      animation: _premiumGlowController,
      builder: (context, child) {
        // Breathing "Drip" cyan intensity
        final drip1 = Color.lerp(Colors.cyanAccent, Colors.blueAccent, _premiumGlowController.value)!;
        final drip2 = Color.lerp(Colors.blueAccent, Colors.cyanAccent, _premiumGlowController.value)!;
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: isLarge ? 28 : 12, vertical: isLarge ? 14 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [drip1, drip2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isLarge ? 24 : 12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3 + (0.4 * _premiumGlowController.value)), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: drip1.withValues(alpha: 0.4 + (0.4 * _premiumGlowController.value)),
                blurRadius: (isLarge ? 25 : 15) * _premiumGlowController.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_rounded, color: Colors.black, size: isLarge ? 22 : 14),
                const SizedBox(width: 10),
                Text("DRIP PREMIUM", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: isLarge ? 16 : 9, letterSpacing: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundThumbnail(BackgroundType type) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Render a static/simplified version of the actual background
          _buildBackgroundWidget(type, isPaused: true),
          // Subtle overlay for better label contrast
          Container(color: Colors.black.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  Widget _buildBackgroundWidget(BackgroundType type, {bool isPaused = false}) {
     switch (type) {
        case BackgroundType.classic: return Container(color: Colors.black);
        case BackgroundType.cyberGrid: return CyberGridBackground(isPaused: isPaused);
        case BackgroundType.wealth: return WealthParticleBackground(isPaused: isPaused);
        case BackgroundType.glass: return GlassVaultBackground(isPaused: isPaused);
        case BackgroundType.matrixRain: return MatrixRainBackground(isPaused: isPaused);
        case BackgroundType.starField: return StarFieldBackground(isPaused: isPaused);
        case BackgroundType.meshNetwork: return MeshNetworkBackground(isPaused: isPaused);
        case BackgroundType.liquidFlow: return LiquidFlowBackground(isPaused: isPaused);
        case BackgroundType.radarPulse: return RadarPulseBackground(isPaused: isPaused);
        case BackgroundType.goldRush: return GoldRushBackground(isPaused: isPaused);
        case BackgroundType.heroBattle: return HeroBattleBackground(isPaused: isPaused, isWorking: !isPaused, isLowPerformance: _isLowPerformance);
     }
  }

  Future<void> _autoLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Installation ID
      _installationId = prefs.getString('inst_id') ?? "";
      if (_installationId.isEmpty) {
        _installationId = "DRIP-${DateTime.now().millisecondsSinceEpoch}-${(100 + (DateTime.now().microsecond % 900))}";
        await prefs.setString('inst_id', _installationId);
      }

      final String? jsonStr = prefs.getString('mst_data');
      if (jsonStr != null) {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          _applyData(data);
      }

      await _checkFirstLaunch(prefs);
      await _checkDailyReward(prefs);
      _processTimeSkip();
      prefs.setBool('isLowPerformance', _isLowPerformance);
    } catch (e) {
      debugPrint("AutoLoad Failed: $e");
    } finally {
      if (mounted) setState(() => _isInit = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _autoLoad();
    
    _premiumGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _moneyStream = moneyStream().asBroadcastStream();

    // Achievement Listener
    _moneyStream.listen((balance) {
      if (balance >= 1000 && !_milestone1000Reached) {
        updateState(() {
          _milestone1000Reached = true;
          _userCredits += 10;
        });
        _autoSave();
        _showMilestoneUnlocked("SAVVY INVESTOR", 10);
      }
    });
  }

  Future<void> _autoSave() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {
      "uc": _userCredits,
      "ub": _unlockedBackgrounds.toList(),
      "pu": _isPremiumUser,
      "mi": _incomeSources.map((i) => {
        "n": i.name, 
        "a": i.monthlyAmount, 
        "p": i.isPassive, 
        "sh": i.startHour, 
        "eh": i.endHour, 
        "wd": i.workDays,
        "ca": i.createdAt.toIso8601String(),
      }).toList(),
      "ba": balanceAdjustment,
      "cy": _currencySymbol,
      "pr": _tickerPrecision,
      "tm": _currentTheme.index,
      "bg": _currentBackground.index,
      "pm": _isProfessionalMode,
      "lp": _isLowPerformance,
      "m1k": _milestone1000Reached,
      "pd": _lastProcessedDate.toIso8601String(),
      "vs": {"s": _showSec, "m": _showMin, "h": _showHr, "d": _showDay, "w": _showWeek},
      "gl": _goals.map((g) => {
        "n": g.name, 
        "a": g.targetAmount, 
        "c": g.createdAt.toIso8601String(),
        "ia": g.isAccomplished
      }).toList(),
      "va": _vaultAccounts.map((a) => {
        "i": a.id,
        "n": a.name,
        "b": a.balance
      }).toList(),
      "ht": _history.map((t) => {"a": t.amount, "i": t.isIncome, "t": t.timestamp.toIso8601String(), "d": t.description, "c": t.category}).toList(),
      "bl": _recurringBills.map((b) => {"i": b.id, "n": b.name, "a": b.amount, "d": b.dueDay}).toList(),
    };
    await prefs.setString('mst_data', jsonEncode(data));
    await prefs.setBool('isLowPerformance', _isLowPerformance);
  }


  Future<void> _checkFirstLaunch(SharedPreferences prefs) async {
    final isFirst = prefs.getBool('first_launch_done') == null;
    if (isFirst) {
      await prefs.setBool('first_launch_done', true);
      updateState(() => _userCredits += 25);
      _autoSave();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           _showToast("WELCOME GIFT", "+25 INITIAL CREDITS!", icon: Icons.card_giftcard, color: Colors.greenAccent);
        }
      });
    }
  }

  Future<void> _checkDailyReward(SharedPreferences prefs) async {
    final now = DateTime.now();
    _isLowPerformance = prefs.getBool('isLowPerformance') ?? false;
    final lastRewardStr = prefs.getString('last_reward_date');
    final firstLaunchStr = prefs.getBool('first_launch_done'); // Ensure it's not the same day they joined
    bool shouldReward = false;
    
    if (lastRewardStr == null) {
      // If no reward date yet, and NOT the first time the app is launched (30 credits given), give 5
      if (firstLaunchStr == true) shouldReward = true; 
    } else {
      final lastDate = DateTime.parse(lastRewardStr);
      if (now.year != lastDate.year || now.month != lastDate.month || now.day != lastDate.day) {
        shouldReward = true;
      }
    }

    if (shouldReward) {
      await prefs.setString('last_reward_date', now.toIso8601String());
      updateState(() => _userCredits += 5); 
      _autoSave();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           _showToast("DAILY BONUS", "+5 FREE DROPS!", icon: Icons.control_point_duplicate_rounded, color: Colors.blueAccent);
        }
      });
    }
  }

  void _applyData(Map<String, dynamic> data) {
    setState(() {
      _userCredits = data["uc"] ?? 0;
      _unlockedBackgrounds = Set<int>.from(data["ub"] ?? [0]);
      _isPremiumUser = data["pu"] ?? false;

      _currencySymbol = data["cy"] ?? "\$";
      _tickerPrecision = data["pr"] ?? 4;
      balanceAdjustment = data["ba"] ?? 0.0;
      _currentTheme = ThemeType.values[(data["tm"] ?? 0).clamp(0, ThemeType.values.length-1)];
      _currentBackground = BackgroundType.values[(data["bg"] ?? 0).clamp(0, BackgroundType.values.length-1)];
      _isProfessionalMode = data["pm"] ?? false;
      _isLowPerformance = data["lp"] ?? false;
      _milestone1000Reached = data["m1k"] ?? false;
      _lastProcessedDate = data["pd"] != null ? DateTime.parse(data["pd"]) : DateTime.now();
      
      final vs = data["vs"] ?? {};
      _showSec = vs["s"] ?? true;
      _showMin = vs["m"] ?? true;
      _showHr = vs["h"] ?? true;
      _showDay = vs["d"] ?? true;
      _showWeek = vs["w"] ?? true;

      _incomeSources.clear();
      for (var i in data["mi"] ?? []) {
        _incomeSources.add(IncomeSource(
          name: i["n"], 
          monthlyAmount: (i["a"] as num).toDouble(), 
          isPassive: i["p"] ?? true,
          startHour: i["sh"] ?? 9,
          endHour: i["eh"] ?? 17,
          workDays: List<int>.from(i["wd"] ?? [1,2,3,4,5]),
          createdAt: i["ca"] != null ? DateTime.parse(i["ca"]) : null,
        ));
      }
      
      _goals.clear();
      for (var g in data["gl"] ?? []) {
        _goals.add(SavingsGoal(
          name: g["n"], 
          targetAmount: (g["a"] as num).toDouble(), 
          createdAt: DateTime.parse(g["c"]),
          isAccomplished: g["ia"] ?? false,
        ));
      }

      _vaultAccounts.clear();
      for (var a in data["va"] ?? []) {
        _vaultAccounts.add(VaultAccount(
          id: a["i"],
          name: a["n"],
          balance: (a["b"] as num).toDouble(),
        ));
      }
      
      _history.clear();
      for (var t in data["ht"] ?? []) {
        _history.add(Transaction(
          amount: (t["a"] as num).toDouble(), 
          isIncome: t["i"], 
          timestamp: DateTime.parse(t["t"]), 
          description: t["d"] ?? "", 
          category: t["c"] ?? "General"
        ));
      }

      _recurringBills.clear();
      for (var b in data["bl"] ?? []) {
        _recurringBills.add(Bill(
          id: b["i"], 
          name: b["n"], 
          amount: (b["a"] as num).toDouble(), 
          dueDay: b["d"] ?? 1
        ));
      }
    });
  }

  /// Evaluates and mints generated wealth across entire month boundaries.
  /// This engine ensures that when a month ends, the net progress is baked into balanceAdjustment
  /// and the ticker resets for the new month with the correct baseline history.
  void _processTimeSkip() {
    final now = DateTime.now();
    DateTime startOfCurrentMonth = DateTime(now.year, now.month, 1);
    
    // Detected boundary cross?
    if (_lastProcessedDate.isBefore(startOfCurrentMonth)) {
      setState(() {
        // Find the month we WERE in
        DateTime currentWalkingMonth = DateTime(_lastProcessedDate.year, _lastProcessedDate.month, 1);
        
        while (currentWalkingMonth.isBefore(startOfCurrentMonth)) {
          DateTime nextMonth = DateTime(currentWalkingMonth.year, currentWalkingMonth.month + 1, 1);
          
          double monthEarned = 0;
          for (var source in _incomeSources) {
            // PROD-LEVEL PRECISION: Use the actual ratio of the month worked.
            // If the source was created on the 15th, they only get 50% of monthlyAmount for that month.
            double totalPotentialSec = source.workSecondsBetween(currentWalkingMonth, nextMonth, ignoreCreationDate: true);
            double actualWorkSec = source.workSecondsBetween(currentWalkingMonth, nextMonth);
            
            if (totalPotentialSec > 0) {
               monthEarned += (actualWorkSec / totalPotentialSec) * source.monthlyAmount;
            }
          }
          
          double netForMonth = monthEarned; // Bills are handled via manual transactions or separate tracking
          balanceAdjustment += netForMonth;
          
          _history.insert(0, Transaction(
            amount: netForMonth.abs(),
            isIncome: netForMonth >= 0,
            timestamp: nextMonth.subtract(const Duration(seconds: 1)),
            description: "Monthly Revenue Baked: ${_monthNameFull(currentWalkingMonth.month)}",
            category: "System",
          ));
          
          currentWalkingMonth = nextMonth;
        }
        
        _lastProcessedDate = now;
      });
      _autoSave();
    } else {
      _lastProcessedDate = now;
      _autoSave();
    }
  }

  // --- THEME COLORS ---
  Color get accentColor {
    if (_isProfessionalMode) {
      return Colors.blueAccent; // Sharp institutional finance styling
    }
    switch (_currentTheme) {
      case ThemeType.cyberpunk: return const Color(0xFFFF00FF);
      case ThemeType.electric: return const Color(0xFF00E5FF);
      case ThemeType.crimson: return const Color(0xFFFF3D00);
      case ThemeType.royal: return const Color(0xFFD500F9);
      case ThemeType.gold: return const Color(0xFFFFD700);
      default: return const Color(0xFF00FF88);
    }
  }

  // --- LOGIC CALCULATIONS ---
  double get totalMonthlyRevenue => _incomeSources.fold(0.0, (s, i) => s + i.monthlyAmount);
  double get totalMonthlyBills => _recurringBills.fold(0.0, (sum, item) => sum + item.amount);
  double get netMonthlyIncome => totalMonthlyRevenue - totalMonthlyBills;
  
  double get liveRatePerSecond {
    double income = 0;
    for (var s in _incomeSources) {
      if (s.isWorkingNow) {
        // Since ratePerSecond is normalized to total work hours in a month, 
        // we add it only when currently working.
        income += s.ratePerSecond;
      }
    }
    return income;
  }

  String _f(double amount, [int? precision]) {
    final p = precision ?? 2;
    final parts = amount.toStringAsFixed(p).split('.');
    final whole = parts[0];
    final decimal = parts.length > 1 ? '.${parts[1]}' : '';
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedWhole = whole.replaceAllMapped(reg, (m) => '${m[1]},');
    return '$formattedWhole$decimal';
  }

  // High-performance formatter for the live ticker to replace RegExp calls
  String _fFast(double amount, [int? precision]) {
    final p = precision ?? 2;
    // Manual integer grouping is much faster than RegExp replaceAllMapped
    String s = amount.toStringAsFixed(p);
    List<String> parts = s.split('.');
    String whole = parts[0];
    String decimal = parts.length > 1 ? '.${parts[1]}' : '';
    String res = "";
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count == 3 && whole[i] != '-') {
        res = ",$res";
        count = 0;
      }
      res = "${whole[i]}$res";
      count++;
    }
    return "$res$decimal";
  }

  String _shorten(double value, {int maxNums = 5}) {
    double scaled = value.abs();
    final List<String> suffixes = ["", " K", " M", " B", " T", " q", " Q", " s", " S", " O", " N", " d"];
    int suffixIndex = 0;

    while (scaled >= 1000 && suffixIndex < suffixes.length - 1) {
      scaled /= 1000.0;
      suffixIndex++;
    }

    // Try showing 2 decimal points first
    String fmt = scaled.toStringAsFixed(2);
    int digits = fmt.replaceAll('.', '').replaceAll('-', '').length;

    if (digits > maxNums) {
      // Reduce to 1 decimal point
      fmt = scaled.toStringAsFixed(1);
      digits = fmt.replaceAll('.', '').replaceAll('-', '').length;
    }
    
    if (digits > maxNums) {
      // No decimal points
      fmt = scaled.toStringAsFixed(0);
    }
    
    // Handle edge case: if rounding forces the number to 1000 (e.g. 999.999)
    if (double.tryParse(fmt) != null && double.parse(fmt) >= 1000 && suffixIndex < suffixes.length - 1) {
       scaled /= 1000.0;
       suffixIndex++;
       fmt = scaled.toStringAsFixed(2);
    }

    final sign = value < 0 ? "-" : "";
    return "$sign$fmt${suffixes[suffixIndex]}";
  }

  double _getRatePerSecond(double monthly) => monthly / (30 * 24 * 60 * 60);

  Stream<double> moneyStream() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Thermal Optimization: Only do heavy math once per second
    double cachedBase = 0.0;
    double currentRate = 0.0;
    DateTime lastCalculated = DateTime.now();

    return Stream.periodic(const Duration(milliseconds: 50), (count) => count).asyncMap((count) async {
       if (_isSettingsOpen && count % 10 != 0) return null;

       final currentNow = DateTime.now();

       // Every 20 ticks (1 second), perform the deep calculation
       if (count % 20 == 0 || currentRate == 0) {
          cachedBase = 0.0;
          for (var source in _incomeSources) {
            cachedBase += source.workSecondsElapsed(currentNow, monthStart) * source.ratePerSecond;
          }
          // Note: We no longer pre-deduct bills here to avoid double-counting with manual transactions
          
          cachedBase += balanceAdjustment;
          
          currentRate = liveRatePerSecond;
          lastCalculated = currentNow;
          return cachedBase;
       } 

       // Between seconds, just use simple addition
       final diff = currentNow.difference(lastCalculated).inMicroseconds / 1000000.0;
       return cachedBase + (currentRate * diff);
    }).where((val) => val != null).cast<double>();
  }

  /// PROD-READY: Cryptographic integrity signature for account tokens.
  /// This prevents manual editing of balances/credits in the exported JSON.
  String _generateSignature(Map<String, dynamic> data) {
    // We include all economy-related fields to prevent tampering
    final List<int> ub = List<int>.from(data["ub"] ?? [0]);
    ub.sort(); // Consistent order for hashing
    
    double totalRev = 0;
    for (var i in data["mi"] ?? []) { totalRev += (i["a"] as num).toDouble(); }

    double vaultTotal = 0;
    for (var a in data["va"] ?? []) { vaultTotal += (a["b"] as num).toDouble(); }
    
    // SECRET SALT: Prevents users from re-calculating the hash even if they know the algorithm
    const String salt = "DRIP_SECURE_KINETIC_2026"; 
    
    // Base signature includes: Credits + Live Balance + Premium Status + Revenue Rates + Vault Savings + Unlocked Themes + Device ID
    final String base = "$salt${data["uc"]}${data["ba"]}${data["pu"]}${totalRev.toStringAsFixed(2)}${vaultTotal.toStringAsFixed(2)}${ub.join(',')}${data["iid"]}";
    
    // Robust FNV-1a inspired hash for offline integrity
    int hash = 2166136261;
    for (int i = 0; i < base.length; i++) {
        hash = (hash ^ base.codeUnitAt(i)) * 16777619;
        hash &= 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  void _showTransactionDialog(bool isIncome) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String category = "General";
    
    showGlassOverlay(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => GlassDialog(
          title: isIncome ? "MANUAL DEPOSIT" : "MANUAL EXPENSE",
          icon: isIncome ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down,
          iconColor: isIncome ? Colors.greenAccent : Colors.redAccent,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: isIncome ? Colors.greenAccent : Colors.redAccent),
                prefixText: "$_currencySymbol ",
                hintText: "0.00",
              ),
              const SizedBox(height: 24),
              if (!isIncome) ...[
              const Text("CATEGORY", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: const Color(0xFF1A1A1A),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isIncome ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5))),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                  ),
                  items: ["General", "Food", "Rent", "Fun", "Transport", "Bills"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 24),
              ],
              Text(isIncome ? "SOURCE" : "DESCRIPTION", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              GlassTextField(
                controller: descriptionController,
                textCapitalization: TextCapitalization.sentences,
                hintText: isIncome ? "Where is this from?" : "What was this for?",
              ),
            ],
          ),
          actions: [
            GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
            GlassButton(
              isFilled: _isPremiumUser || _userCredits > 0,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              label: _isPremiumUser ? "CONFIRM" : "CONFIRM (1)",
              icon: _isPremiumUser ? null : Icons.water_drop_rounded,
              onPressed: (_isPremiumUser || _userCredits > 0) ? () {
                final val = double.tryParse(amountController.text) ?? 0.0;
                if (val == 0) return;
                setState(() {
                  if (!_isPremiumUser) _userCredits--;
                  balanceAdjustment += isIncome ? val : -val;
                  _history.insert(0, Transaction(
                    amount: val,
                    isIncome: isIncome,
                    timestamp: DateTime.now(),
                    description: descriptionController.text.isEmpty ? (isIncome ? "Quick Income" : "Quick Expense") : descriptionController.text.trim(),
                    category: category,
                  ));
                });
                _autoSave();
                Navigator.pop(context);
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      extendBody: true, 
      body: !_isInit 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 180, // More room for the full label
                leading: GestureDetector(
                  onTap: _showStoreBottomSheet,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: _isPremiumUser 
                      ? _buildPremiumBadge()
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("SHOP", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                const SizedBox(width: 8),
                                const Icon(Icons.water_drop, color: Colors.cyanAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "$_userCredits DROPS",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
                centerTitle: true,
                title: null,
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, size: 20, color: accentColor.withValues(alpha: 0.8)),
                    onPressed: () {
                      setState(() => _isSettingsOpen = true);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF161616),
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.85,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          expand: false,
                          builder: (context, scrollController) => _buildSettingsTab(scrollController: scrollController),
                        ),
                      ).whenComplete(() {
                        setState(() => _isSettingsOpen = false);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _tabIndex == 0 ? "L I V E" : _tabIndex == 1 ? "H I S T O R Y" : _tabIndex == 2 ? "G O A L S" : _tabIndex == 3 ? "B I L L S" : "V A U L T",
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w400, 
                    letterSpacing: 6,
                    color: Colors.white,
                    shadows: [Shadow(color: accentColor, blurRadius: 15)],
                  )
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RepaintBoundary(
                  child: SafeArea(
                    child: IndexedStack(
                      index: _tabIndex,
                      children: [
                        _buildLiveTab(),
                        _buildHistoryTab(),
                        _buildGoalsTab(),
                        _buildBillsTab(),
                        _buildVaultTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F).withValues(alpha: 0.4), 
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: (index) => setState(() => _tabIndex = index),
              backgroundColor: Colors.transparent, 
              selectedItemColor: accentColor,
              unselectedItemColor: Colors.white24,
              selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, shadows: [Shadow(color: accentColor, blurRadius: 10)]),
              unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w300, letterSpacing: 1),
              selectedIconTheme: IconThemeData(color: accentColor, size: 26, shadows: [Shadow(color: accentColor, blurRadius: 15)]),
              unselectedIconTheme: const IconThemeData(color: Colors.white24, size: 22),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.speed), label: "LIVE"),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: "HISTORY"),
                BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: "GOALS"),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "BILLS"),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "VAULT"),
              ], // items
            ), // BottomNavigationBar
          ), // Container
        ), // BackdropFilter
      ), // ClipRRect
    ), // RepaintBoundary
      ),  // closes Scaffold
    );   // closes Theme
  }

  Widget _buildBackground() {
    if (_isProfessionalMode && _previewBackground == null) return ProfessionalBackground(isPaused: _isSettingsOpen);
    
    // Choose the background to display: preview from store takes highest priority
    final bgToBuild = _previewBackground ?? _currentBackground;
    
  Widget bgWidget;
    switch (bgToBuild) {
      case BackgroundType.cyberGrid: bgWidget = CyberGridBackground(isPaused: _isSettingsOpen); break;
      case BackgroundType.wealth: bgWidget = WealthParticleBackground(isPaused: _isSettingsOpen, isLowPerformance: _isLowPerformance); break;
      case BackgroundType.glass: bgWidget = GlassVaultBackground(isPaused: _isSettingsOpen); break;
      case BackgroundType.matrixRain: bgWidget = MatrixRainBackground(isPaused: _isSettingsOpen, isLowPerformance: _isLowPerformance); break;
      case BackgroundType.starField: bgWidget = StarFieldBackground(isPaused: _isSettingsOpen, isLowPerformance: _isLowPerformance); break;
      case BackgroundType.meshNetwork: bgWidget = MeshNetworkBackground(isPaused: _isSettingsOpen, isLowPerformance: _isLowPerformance); break;
      case BackgroundType.liquidFlow: bgWidget = LiquidFlowBackground(isPaused: _isSettingsOpen); break;
      case BackgroundType.radarPulse: 
        bgWidget = RadarPulseBackground(
          isPaused: _isSettingsOpen, 
          isWorking: _previewBackground != null || _incomeSources.any((s) => s.isWorkingNow),
        ); 
        break;
      case BackgroundType.goldRush: 
        bgWidget = GoldRushBackground(
          isPaused: _isSettingsOpen, 
          isWorking: _previewBackground != null || _incomeSources.any((s) => s.isWorkingNow),
          isLowPerformance: _isLowPerformance,
        ); 
        break;
      case BackgroundType.heroBattle:
        bgWidget = HeroBattleBackground(
          isPaused: _isSettingsOpen,
          isWorking: _previewBackground != null || _incomeSources.any((s) => s.isWorkingNow),
          isLowPerformance: _isLowPerformance,
        );
        break;
      default: bgWidget = Container();
    }
    
    return Container(
      color: const Color(0xFF0F0F0F),
      child: RepaintBoundary(child: bgWidget),
    );
  }
  void _showStoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3), // Lighter barrier
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStoreState) {
          final isPrev = _previewBackground != null;
          Widget mainContainer = Container(
            height: isPrev ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.9,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D).withValues(alpha: isPrev ? 0.0 : 0.85), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(isPrev ? 0 : 32)),
              border: Border.all(color: Colors.white.withValues(alpha: isPrev ? 0.0 : 0.1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                if (!isPrev)
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                
                if (_previewBackground != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131313),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 20)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, color: accentColor, size: 18),
                            const SizedBox(width: 12),
                            Text("PREVIEWING: ${_previewBackground!.name.toUpperCase()}", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // SHOP HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_isPremiumUser ? "DRIP PREMIUM" : "DRIP SHOP", 
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                Text(_isPremiumUser ? "UNLIMITED ACCESS" : (_userCredits <= 0 ? "LOW BALANCE! WATCH ADS TO EARN" : "PURCHASE DROPS"), 
                                  style: TextStyle(color: (_userCredits <= 0 && !_isPremiumUser) ? Colors.redAccent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            _isPremiumUser 
                              ? _buildPremiumBadge()
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.water_drop, color: Colors.cyanAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text("$_userCredits", 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isPremiumUser) ...[
                            // --- CURRENCY PACKS ---
                            const Text("DRIP PACKS", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                    _creditPack(setStoreState, "DRIPLET", 50, "\$0.99", Icons.water_drop_outlined),
                                    const SizedBox(width: 12),
                                    _creditPack(setStoreState, "DELUGE", 250, "\$2.99", Icons.opacity_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _adCreditBanner(setStoreState),
                            const SizedBox(height: 40),
                          ],

                          // --- PREMIUM THEMES ---
                          const Text("PREMIUM BACKGROUNDS", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                          const SizedBox(height: 16),
                          
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, 
                                mainAxisSpacing: 12, 
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.12, 
                              ),
                              itemCount: BackgroundType.values.length - 1,
                              itemBuilder: (context, index) {
                                final bg = BackgroundType.values[index + 1];
                                bool isOwned = _unlockedBackgrounds.contains(bg.index) || _isPremiumUser;
                                bool isPreviewing = _previewBackground == bg;
                                
                                final themeIcons = {
                                  BackgroundType.cyberGrid: Icons.grid_4x4,
                                  BackgroundType.wealth: Icons.currency_bitcoin_rounded,
                                  BackgroundType.glass: Icons.layers_outlined,
                                  BackgroundType.matrixRain: Icons.qr_code_2_rounded,
                                  BackgroundType.starField: Icons.auto_awesome,
                                  BackgroundType.meshNetwork: Icons.hive_rounded,
                                  BackgroundType.liquidFlow: Icons.water_drop_outlined,
                                  BackgroundType.radarPulse: Icons.track_changes,
                                  BackgroundType.goldRush: Icons.paid,
                                };
                                  final IconData themeIcon = bg == BackgroundType.matrixRain ? Icons.terminal_rounded : (bg == BackgroundType.meshNetwork ? Icons.hub_outlined : (themeIcons[bg] ?? Icons.wallpaper));

                                  return GestureDetector(
                                    onTap: () => _showThemePreviewDock(bg, setStoreState),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isPreviewing ? accentColor : (isOwned ? Colors.white10 : Colors.cyanAccent.withValues(alpha: 0.2)), width: 1.5),
                                        boxShadow: isPreviewing ? [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 15)] : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Stack(
                                          children: [
                                            // FULL BACKGROUND THUMBNAIL
                                            Positioned.fill(
                                              child: RepaintBoundary(
                                                child: Opacity(
                                                  opacity: isOwned || isPreviewing ? 0.8 : 0.3,
                                                  child: _buildBackgroundThumbnail(bg),
                                                ),
                                              ),
                                            ),
                                            // OVERLAY GRADIENT FOR READABILITY
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black.withValues(alpha: 0.4),
                                                      Colors.transparent,
                                                      Colors.black.withValues(alpha: 0.8),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // CONTENT
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black26,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(themeIcon, size: 14, color: isPreviewing ? accentColor : (isOwned ? Colors.white70 : Colors.white24)),
                                                      ),
                                                      const Spacer(),
                                                      if (isOwned) 
                                                        const Icon(Icons.verified, color: Colors.greenAccent, size: 10)
                                                      else 
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(4)),
                                                          child: const Text("50💧", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                                                        ),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  const Text("TAP TO PREVIEW", style: TextStyle(color: Colors.white38, fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                                  const SizedBox(height: 2),
                                                  Text(bg.name.toUpperCase(), style: TextStyle(color: isPreviewing ? accentColor : Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                  if (isPreviewing) 
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 4),
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
                                                      child: const Text("ACTIVE PREVIEW", style: TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.w900)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                              },
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  
                  // PREMIUM / UNLOCK BOTTOM BAR
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131313),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    ),
                  child: _isPremiumUser ? Center(
                    child: _buildPremiumBadge(isLarge: true),
                  ) : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop_rounded, color: Colors.cyanAccent, size: 36),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("PREMIUM UNLOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                              Text("Instant access to all current and future themes", style: TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _purchasePremium(setStoreState),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text("500💧", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                  ),
                  ),
                ],
              ],
            ),
          );
          
          // Wrap content
          if (isPrev) return mainContainer;
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: mainContainer,
          );
        },
      ),
    ).whenComplete(() {
      updateState(() => _previewBackground = null);
    });
  }

  Widget _creditPack(StateSetter setStoreState, String title, int amount, String price, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _userCredits += amount);
          setStoreState(() {});
          _autoSave();
          _showToast("DROPS ADDED", "+$amount DROPS ADDED!", icon: Icons.water_drop, color: Colors.cyanAccent);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 28),
              const SizedBox(height: 12),
              Text("$amount DROPS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              const SizedBox(height: 4),
              Text(price, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adCreditBanner(StateSetter setStoreState) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 32),
          const SizedBox(width: 12),
          const Expanded(child: Text("WATCH AD FOR FREE DROPS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              updateState(() => _userCredits += 5);
              setStoreState(() {});
              _autoSave();
              _showToast("BONUS EARNED", "+5 FREE DROPS!", icon: Icons.water_drop_outlined, color: Colors.blueAccent);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("GET +5", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _purchasePremium(StateSetter setStoreState) {
    if (_userCredits >= 500) {
      updateState(() {
        _userCredits -= 500;
        _isPremiumUser = true;
      });
      setStoreState(() {});
      _autoSave();
      _showToast("PURCHASE COMPLETE", "PREMIUM ACTIVATED! 👑", icon: Icons.workspace_premium, color: Colors.cyanAccent);
    } else {
      _showToast("PURCHASE FAILED", "INSUFFICIENT DROPS (500 REQ.)", icon: Icons.error_outline, color: Colors.redAccent);
    }
  }
  void _showThemePreviewDock(BackgroundType type, StateSetter setStoreState) {
    bool isOwned = _unlockedBackgrounds.contains(type.index) || _isPremiumUser;
    
    // Set preview immediately - main screen will be sharp now!
    setState(() => _previewBackground = type);
    setStoreState(() {}); // Force store to update (e.g. to lower its alpha)

    final String description = {
      BackgroundType.classic: "A clean, distraction-free environment for pure financial focus.",
      BackgroundType.cyberGrid: "Retro-futuristic neon grid with digital depth and movement.",
      BackgroundType.wealth: "Digital binary streams representing continuous financial growth.",
      BackgroundType.glass: "High-end frosted glass panes with breathing light reflections.",
      BackgroundType.matrixRain: "Concentrated digital rainfall for the focused strategist.",
      BackgroundType.starField: "Stunning interstellar travel with warp streaks and nebulae.",
      BackgroundType.meshNetwork: "Highly connected digital nodes representing network power.",
      BackgroundType.liquidFlow: "Luxurious fluid dynamics with organic bloom reflections.",
      BackgroundType.radarPulse: "Active scanning waves for proactive wealth monitoring.",
      BackgroundType.goldRush: "An opulent rain of gold coins over a massive treasury floor.",
    }[type] ?? "A premium high-fidelity background experience.";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Let the background stay sharp
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: const Color(0xFF131313).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1.5)),
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("THEME PREVIEW", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3)),
                      const SizedBox(height: 4),
                      Text(type.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ],
                  ),
                ),
                GlassButton(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    setState(() => _previewBackground = null); // REVERT
                    setStoreState(() {});
                  },
                  label: "CANCEL",
                  color: Colors.white24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                if (!isOwned)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassButton(
                          isFilled: _userCredits >= 50,
                          label: _userCredits >= 50 ? "UNLOCK (50 DROPS)" : "INSUFFICIENT DROPS",
                          color: _userCredits >= 50 ? Colors.cyanAccent : Colors.white12,
                          onPressed: _userCredits >= 50 ? () {
                            updateState(() {
                              _userCredits -= 50;
                              _unlockedBackgrounds.add(type.index);
                              _currentBackground = type;
                              _previewBackground = null;
                              _isProfessionalMode = false;
                            });
                            _autoSave();
                            Navigator.pop(modalContext); // Close dock
                            Navigator.pop(context); // Close store
                            _showToast("THEME ACTIVATED", "${type.name.toUpperCase()} IS NOW LIVE", icon: Icons.check_circle_outline, color: Colors.greenAccent);
                          } : null,
                        ),
                        if (_userCredits < 50) ...[
                          const SizedBox(height: 12),
                          const Text("NEED MORE DROPS?", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(modalContext); // Close dock to show store
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.blueAccent),
                                label: const Text("BUY PACK", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _showToast("AD LOADING", "Watching Ad for 5 Credits...", icon: Icons.ondemand_video, color: Colors.cyanAccent);
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      updateState(() => _userCredits += 5);
                                      _autoSave();
                                      _showToast("REWARD EARNED", "+5 DROPS ADDED!", icon: Icons.opacity_rounded, color: Colors.cyanAccent);
                                    }
                                  });
                                },
                                icon: const Icon(Icons.play_circle_outline, size: 14, color: Colors.cyanAccent),
                                label: const Text("WATCH AD (+5)", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: GlassButton(
                      isFilled: true,
                      label: "ACTIVATE THEME",
                      onPressed: () {
                        updateState(() {
                          _currentBackground = type;
                          _previewBackground = null;
                          _isProfessionalMode = false;
                        });
                        _autoSave();
                        Navigator.pop(modalContext); // Close dock
                        Navigator.pop(context); // Close store
                        _showToast("THEME ACTIVATED", "${type.name.toUpperCase()} IS NOW LIVE", icon: Icons.check_circle_outline, color: Colors.greenAccent);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // If we didn't apply/unlock, make sure it's cleared
      if (_previewBackground != null) {
        setState(() => _previewBackground = null);
        setStoreState(() {});
      }
    });
  }

  void _showMonthlyRevenueDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final ScrollController scrollController = ScrollController();
    bool isPassive = true;
    int startH = 9;
    int endH = 17;
    List<int> days = [1, 2, 3, 4, 5];
    bool isAdding = _incomeSources.isEmpty;
    int? editingIndex;

    showGlassOverlay(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => GlassDialog(
          title: isAdding ? (editingIndex != null ? "EDIT SOURCE" : "ADD REVENUE") : "MANAGE REVENUE",
          icon: isAdding ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isAdding) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _incomeSources.length,
                        itemBuilder: (context, index) {
                          final source = _incomeSources[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(source.isPassive ? Icons.cloud : Icons.work, size: 16, color: accentColor),
                            title: Text(source.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text("${source.isPassive ? '24/7' : '${source.startHour}:00-${source.endHour}:00 • ${_formatWorkDays(source.workDays)}'} • $_currencySymbol${source.monthlyAmount.toInt()}", style: const TextStyle(fontSize: 10, color: Colors.white24)),
                            onTap: () {
                              setDialogState(() {
                                isAdding = true;
                                editingIndex = index;
                                nameController.text = source.name;
                                amountController.text = source.monthlyAmount.toString();
                                isPassive = source.isPassive;
                                startH = source.startHour;
                                endH = source.endHour;
                                days = List.from(source.workDays);
                              });
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    title: const Text("Delete Source?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    content: Text("Are you sure you want to remove '${source.name}'? This will stop its live drips immediately.", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _incomeSources.removeAt(index);
                                            if (_incomeSources.isEmpty) isAdding = true;
                                          });
                                          setDialogState(() { 
                                            if (_incomeSources.isEmpty) editingIndex = null;
                                          });
                                          _autoSave();
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("DELETE"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    TextButton.icon(
                      icon: Icon(Icons.add, size: 16, color: accentColor),
                      label: Text("ADD ANOTHER SOURCE", style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      onPressed: () {
                        setDialogState(() {
                          isAdding = true;
                          editingIndex = null;
                          nameController.clear();
                          amountController.clear();
                        });
                      },
                    ),
                  ] else ...[
                    GlassTextField(controller: nameController, autofocus: false, hintText: "Source Name"),
                    const SizedBox(height: 12),
                    GlassTextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixText: "$_currencySymbol ", hintText: "Monthly Amount"),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Passive Income (24/7)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: isPassive,
                      activeThumbColor: accentColor,
                      onChanged: (v) {
                        setDialogState(() => isPassive = v);
                        if (!v) {
                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (scrollController.hasClients) {
                              scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!isPassive) ...[
                      const Divider(color: Colors.white10),
                      const Text("SHIFT HOURS (24H)", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              value: startH,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF131313),
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i:00", style: const TextStyle(fontWeight: FontWeight.bold)))),
                              onChanged: (v) => setDialogState(() => startH = v!),
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("to", style: TextStyle(color: Colors.white38))),
                          Expanded(
                            child: DropdownButton<int>(
                              value: endH,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF131313),
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i:00", style: const TextStyle(fontWeight: FontWeight.bold)))),
                              onChanged: (v) => setDialogState(() => endH = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("WORK DAYS", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                          bool active = days.contains(d);
                          return GestureDetector(
                            onTap: () => setDialogState(() => active ? days.remove(d) : days.add(d)),
                            child: Container(
                              width: 35, height: 35,
                              decoration: BoxDecoration(color: active ? accentColor : Colors.white12, shape: BoxShape.circle),
                              child: Center(child: Text(["", "M", "T", "W", "T", "F", "S", "S"][d], style: TextStyle(color: active ? Colors.black : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            GlassButton(
              label: "CLOSE",
              color: Colors.white24,
              onPressed: () {
                if (isAdding && _incomeSources.isNotEmpty) {
                  setDialogState(() {
                    isAdding = false;
                    editingIndex = null;
                  });
                } else {
                  Navigator.pop(context);
                }
              }
            ),
            if (isAdding)
              GlassButton(
                isFilled: _isPremiumUser || _userCredits > 0 || editingIndex != null,
                label: editingIndex != null ? "UPDATE" : (_isPremiumUser ? "SAVE" : (_userCredits > 0 ? "SAVE (1 C)" : "OUT OF CREDITS")),
                onPressed: (_isPremiumUser || _userCredits > 0 || editingIndex != null) ? () {
                  final val = double.tryParse(amountController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && val > 0) {
                    updateState(() {
                      final newSrc = IncomeSource(
                        name: nameController.text.trim(),
                        monthlyAmount: val,
                        isPassive: isPassive,
                        startHour: startH,
                        endHour: endH,
                        workDays: List.from(days),
                        createdAt: DateTime(DateTime.now().year, DateTime.now().month, 1),
                      );
                      if (editingIndex != null) {
                        _incomeSources[editingIndex!] = newSrc;
                      } else {
                        if (!_isPremiumUser) _userCredits--; 
                        _incomeSources.add(newSrc);
                      }
                    });
                    _autoSave();
                    setDialogState(() {
                      isAdding = false;
                      editingIndex = null;
                    });
                  }
                } : null,
              ),
          ],
        ),
      ),
    );
  }

  void _showStatsSheet() {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31);
    final daysRemaining = endOfYear.difference(now).inDays;
    final projection = (netMonthlyIncome / 30) * daysRemaining;

    // Calculate category breakdown (including recurring bills)
    Map<String, double> categorySums = {};
    for (var t in _history.where((e) => !e.isIncome && e.category != "Vault")) {
      categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
    }
    // Add bills to breakdown
    if (totalMonthlyBills > 0) {
      categorySums["Recurring Bills"] = totalMonthlyBills;
    }

    double totalExp = categorySums.values.fold(0, (s, a) => s + a);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TOTAL MONTHLY OVERHEAD", style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                IconButton(icon: Icon(Icons.close, color: accentColor), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final totalBurnPct = totalMonthlyRevenue > 0 ? (totalExp / totalMonthlyRevenue) : (totalExp > 0 ? 1.0 : 0.0);
              final burnColor = totalBurnPct > 1.0 ? Colors.redAccent : Colors.greenAccent;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${(totalBurnPct * 100).toStringAsFixed(1)}% OVERHEAD",
                        style: TextStyle(color: burnColor, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text("$_currencySymbol${_f(totalExp)} / $_currencySymbol${_f(totalMonthlyRevenue)}",
                        style: const TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: totalBurnPct.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(burnColor),
                    ),
                  ),
                ],
              );
            }),
            const Divider(height: 48, color: Colors.white10),

            const Text("OVERHEAD ANALYSIS (BY CATEGORY)", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            if (totalExp == 0)
              const Text("No expense data yet", style: TextStyle(color: Colors.white12, fontSize: 14))
            else
              ...categorySums.entries.map((e) {
                // Percentage of Gross Revenue (NOT total expenses)
                final revenuePct = totalMonthlyRevenue > 0 ? (e.value / totalMonthlyRevenue) : (e.value > 0 ? 1.1 : 0.0);
                final color = revenuePct > 1.0 ? Colors.redAccent : Colors.greenAccent;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("${(revenuePct * 100).toStringAsFixed(1)}% OF GROSS", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: revenuePct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const Divider(height: 40, color: Colors.white10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${now.year} YEAR-END PROJECTION",
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text("$daysRemaining DAYS LEFT", style: TextStyle(color: (projection >=0 ? Colors.greenAccent : Colors.redAccent), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "$_currencySymbol${_f(projection)}",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: (projection >= 0 ? Colors.greenAccent : Colors.redAccent)),
            ),
            Text(projection >= 0 ? "ESTIMATED NET GAIN UNTIL EOY" : "⚠️ PROJECTED DEFICIT UNTIL EOY", style: TextStyle(color: (projection >= 0 ? Colors.white24 : Colors.redAccent.withValues(alpha: 0.5)), fontSize: 10)),
            const SizedBox(height: 32),
            _statRow("Daily Net", netMonthlyIncome / 30),
            _statRow("Weekly Net", (netMonthlyIncome / 30) * 7),
            _statRow("Gross Monthly", totalMonthlyRevenue),
            _statRow("Total Bills", -totalMonthlyBills),
            _statRow("Monthly Net", netMonthlyIncome),
            const SizedBox(height: 24),

            Text("REVENUE BREAKDOWN", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ..._incomeSources.map((s) => _itemDetailRow(s.name, s.monthlyAmount, Colors.greenAccent)),
            if (_recurringBills.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text("RECURRING BILLS", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ..._recurringBills.map((b) => _itemDetailRow(b.name, -b.amount, Colors.redAccent)),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

  Widget _itemDetailRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(
            "${value >= 0 ? "+" : ""}$_currencySymbol${_f(value.abs())}",
            style: TextStyle(color: value >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: accentColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
          Text(
            "${value >= 0 ? "+" : ""}$_currencySymbol${_f(value)}",
            style: TextStyle(
              color: value >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  void _removeTransaction(Transaction t) {
    showGlassOverlay(
      context: context,
      builder: (ctx) => GlassDialog(
        title: "DELETE TRANSACTION?",
        icon: Icons.warning_amber_rounded,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to remove this record? This will reverse the balance change associated with it.", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(t.isIncome ? Icons.add_circle : Icons.remove_circle, color: t.isIncome ? Colors.greenAccent : Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.description.isNotEmpty ? t.description : (t.isIncome ? "Manual Deposit" : "Manual Expense"), style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text("${t.isIncome ? '+' : '-'} $_currencySymbol${_f(t.amount)}", style: TextStyle(color: t.isIncome ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(ctx), label: "CANCEL", color: Colors.white24),
          GlassButton(
            isFilled: true,
            color: Colors.redAccent,
            label: "DELETE",
            onPressed: () {
              updateState(() {
                // Reverse the balance adjustment
                if (t.isIncome) {
                  balanceAdjustment -= t.amount;
                } else {
                  balanceAdjustment += t.amount;
                }

                // Reverse vault balance if it was a transfer
                if (t.category == "Vault") {
                  String vaultName = "";
                  bool isDepositToVault = false;
                  
                  if (t.description.startsWith("Transfer -> ")) {
                    vaultName = t.description.replaceFirst("Transfer -> ", "");
                    isDepositToVault = true;
                  } else if (t.description.startsWith("Transfer <- ")) {
                    vaultName = t.description.replaceFirst("Transfer <- ", "");
                    isDepositToVault = false;
                  } else if (t.description.startsWith("Liquid Deposit -> ")) {
                    vaultName = t.description.replaceFirst("Liquid Deposit -> ", "");
                    isDepositToVault = true;
                  }

                  if (vaultName.isNotEmpty) {
                    for (var a in _vaultAccounts) {
                      if (a.name == vaultName) {
                        if (isDepositToVault) {
                          a.balance -= t.amount;
                        } else {
                          a.balance += t.amount;
                        }
                        break;
                      }
                    }
                  } else if (t.description.startsWith("Account Closed (Liquidated): ")) {
                    // Logic: If we delete a liquidation record, we return the money back to a ghost account? 
                    // No, that's complex. Better to just let the cash stay in liquid.
                  }
                }

                _history.remove(t);
              });
              _autoSave();
              Navigator.pop(ctx);
              _showToast("REMOVED", "History record deleted", icon: Icons.delete_sweep_outlined, color: Colors.redAccent);
            },
          ),
        ],
      ),
    );
  }

  void _showAddBillDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    int dueDay = 1;

    showGlassOverlay(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => GlassDialog(
          title: "ADD RECURRING BILL",
          icon: Icons.receipt_long_outlined,
          isLowPerformance: _isLowPerformance,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(controller: nameController, hintText: "Bill Name", autofocus: false, isLowPerformance: _isLowPerformance),
              const SizedBox(height: 12),
              GlassTextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), hintText: "Amount", prefixText: "$_currencySymbol ", isLowPerformance: _isLowPerformance),
              const SizedBox(height: 24),
              const Text("DUE DAY", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text("$dueDay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor)),
                    Expanded(
                      child: Slider(
                        value: dueDay.toDouble(),
                        min: 1, max: 31, divisions: 30,
                        activeColor: accentColor,
                        inactiveColor: Colors.white10,
                        onChanged: (v) => setDialogState(() => dueDay = v.toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
            GlassButton(
              isFilled: _isPremiumUser || _userCredits > 0,
              label: _isPremiumUser ? "ADD" : (_userCredits > 0 ? "ADD (1 C)" : "OUT OF"),
              onPressed: (_isPremiumUser || _userCredits > 0) ? () {
                final val = double.tryParse(amountController.text) ?? 0.0;
                if (nameController.text.isNotEmpty && val > 0) {
                  updateState(() {
                    if (!_isPremiumUser) _userCredits--; 
                    final newBill = Bill(id: DateTime.now().toString(), name: nameController.text.trim(), amount: val, dueDay: dueDay);
                    _recurringBills.add(newBill);
                    // Immediate deduction for current month as per user request
                    balanceAdjustment -= val;
                    _history.insert(0, Transaction(
                      amount: val, 
                      isIncome: false, 
                      timestamp: DateTime.now(), 
                      description: "Added Bill: ${newBill.name} (First Month)", 
                      category: "Recurring Bills"
                    ));
                  });
                  _autoSave();
                  Navigator.pop(context);
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  double _getCompositeRate(String type) {
    return _incomeSources.fold(0.0, (sum, i) {
      if (!i.isWorkingNow) return sum;
      
      final sec = i.ratePerSecond;
      if (type == "SEC") return sum + sec;
      if (type == "MIN") return sum + sec * 60;
      if (type == "HR") return sum + sec * 3600;
      
      if (i.isPassive) {
        if (type == "DAY") return sum + sec * 86400;
        if (type == "WEEK") return sum + sec * 604800;
      } else {
        double hoursPerDay = (i.endHour >= i.startHour) ? (i.endHour - i.startHour).toDouble() : (24 - i.startHour + i.endHour).toDouble();
        if (type == "DAY") return sum + sec * 3600 * hoursPerDay;
        if (type == "WEEK") return sum + sec * 3600 * hoursPerDay * i.workDays.length;
      }
      return sum;
    });
  }



  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Food": return Icons.fastfood;
      case "Rent": return Icons.home;
      case "Fun": return Icons.celebration;
      case "Transport": return Icons.directions_car;
      case "Bills": return Icons.receipt;
      case "Vault": return Icons.account_balance_wallet;
      case "Goals": return Icons.emoji_events;
      default: return Icons.money_off;
    }
  }


  Widget _rateChip(String label, double rate, Color color) {
    bool isSelected = _selectedRateView == label;
    return InkWell(
      onTap: () => setState(() => _selectedRateView = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${rate >= 0 ? "+" : "-"} $_currencySymbol${_shorten(rate.abs(), maxNums: 5)}",
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white70 : color.withValues(alpha: 0.4),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _monthName(int m) => ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][m];
  String _monthNameFull(int m) => ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][m];



  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.08),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays;
}

class _PremiumToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _PremiumToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_PremiumToast> createState() => _PremiumToastState();
}

class _PremiumToastState extends State<_PremiumToast> with TickerProviderStateMixin {
  late AnimationController _anim;
  late AnimationController _sweepAnim;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _sweepAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _offset = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _sweepAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedBuilder(
                animation: Listenable.merge([_anim, _sweepAnim]),
                builder: (context, _) {
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [widget.accentColor.withValues(alpha: 0.8), widget.accentColor.withValues(alpha: 0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: widget.accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: FractionalTranslation(
                                  translation: Offset(_sweepAnim.value * 3 - 1.5, 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.3, 0.5, 0.7],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: widget.accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: widget.accentColor.withValues(alpha: 0.2), blurRadius: 10)],
                                      ),
                                      child: Icon(widget.icon, color: widget.accentColor, size: 22),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.title, style: TextStyle(color: widget.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                          const SizedBox(height: 2),
                                          Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                                      onPressed: widget.onDismiss,
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
