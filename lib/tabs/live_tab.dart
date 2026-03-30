part of '../main.dart';

extension _LiveTabExtension on _TickerScreenState {
  Widget _buildLiveTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // --- TOP SECTION: Revenue Summary Card ---
          InkWell(
            onTap: _showMonthlyRevenueDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: netMonthlyIncome >= 0
                  ? accentColor.withValues(alpha: 0.05)
                  : Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: netMonthlyIncome >= 0
                  ? accentColor.withValues(alpha: 0.2)
                  : Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: StreamBuilder<dynamic>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (context, _) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("NET MONTHLY STREAM",
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 3, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _incomeSources.any((s) => !s.isPassive && s.isWorkingNow) ? accentColor.withValues(alpha: 0.1) : Colors.white10,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.work, size: 12, color: _incomeSources.any((s) => !s.isPassive && s.isWorkingNow) ? accentColor : Colors.white24),
                                    const SizedBox(width: 6),
                                    Text(_incomeSources.any((s) => !s.isPassive && s.isWorkingNow) ? "WORKING" : "OFF-CLOCK",
                                      style: TextStyle(color: _incomeSources.any((s) => !s.isPassive && s.isWorkingNow) ? accentColor : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text("$_currencySymbol${_f(netMonthlyIncome)}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: netMonthlyIncome >= 0 ? Colors.greenAccent : Colors.redAccent,
                            )),
                        ),
                      ),
                      const Divider(color: Colors.white10),
                      Text("${_incomeSources.length} SOURCES ACTIVE",
                        style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w400, letterSpacing: 2, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                    ],
                  );
                }
              ),
            ),
          ),

          const Spacer(),

          // --- CENTER SECTION: The Live Ticker ---
          Column(
            children: [
              GestureDetector(
                onTap: _showStatsSheet,
                child: Builder(builder: (context) {
                  final trajectoryColor = liveRatePerSecond < 0 ? Colors.redAccent : accentColor;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: trajectoryColor.withValues(alpha: 0.05),
                      border: Border.all(color: trajectoryColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: trajectoryColor.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_outlined, color: trajectoryColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "LIVE ANALYTICS",
                          style: TextStyle(
                            color: trajectoryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            letterSpacing: 3,
                            shadows: [Shadow(color: trajectoryColor, blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              StreamBuilder<double>(
                stream: _moneyStream,
                builder: (context, snapshot) {
                  final balance = snapshot.data ?? 0.0;
                  final tickerColor = balance < 0 ? Colors.redAccent : Colors.greenAccent;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$_currencySymbol${_fFast(balance, _tickerPrecision)}",
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        color: tickerColor,
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        // Thermal Optimization: No shadows on high-frequency text
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final grossIncome = _incomeSources.fold(0.0, (s, i) => s + (i.isWorkingNow ? i.ratePerSecond : 0));
                final trajectoryColor = liveRatePerSecond < 0 ? Colors.redAccent : accentColor;
                final val = _getCompositeRate(_selectedRateView.replaceAll("/", ""));
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text("CURRENT STREAM RATE: ${val >= 0 ? '+' : '-'} $_currencySymbol${_shorten(val.abs(), maxNums: 8)}${_selectedRateView.toLowerCase()}",
                              style: TextStyle(color: grossIncome > 0 ? Colors.greenAccent : Colors.white, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 3, shadows: [Shadow(color: grossIncome > 0 ? Colors.greenAccent : Colors.white70, blurRadius: 10)])),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_showSec) _rateChip("/SEC", _getCompositeRate("SEC"), trajectoryColor),
                        if (_showMin) _rateChip("/MIN", _getCompositeRate("MIN"), trajectoryColor),
                        if (_showHr) _rateChip("/HR", _getCompositeRate("HR"), trajectoryColor),
                        if (_showDay) _rateChip("/DAY", _getCompositeRate("DAY"), trajectoryColor),
                        if (_showWeek) _rateChip("/WEEK", _getCompositeRate("WEEK"), trajectoryColor),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),

          const Spacer(),

          // --- BOTTOM SECTION: Dynamic Action Buttons ---
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _actionButton("EXPENSE", Colors.redAccent, () => _showTransactionDialog(false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton("INCOME", Colors.greenAccent, () => _showTransactionDialog(true)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _actionButton("DEPOSIT TO VAULT", Colors.greenAccent, () => _showVaultDepositBottomSheet()),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
