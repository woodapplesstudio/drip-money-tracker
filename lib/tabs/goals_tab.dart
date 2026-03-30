part of '../main.dart';

extension _GoalsTabExtension on _TickerScreenState {
  Widget _buildGoalsTab() {
    if (_tabIndex != 2) return const SizedBox.shrink();

    final activeGoals = _goals.where((g) => !g.isAccomplished).toList();
    final accomplishedGoals = _goals.where((g) => g.isAccomplished).toList();

    return StreamBuilder<double>(
      stream: moneyStream(),
      builder: (context, snapshot) {
        final liquid = snapshot.data ?? 0.0;
        final vaultTotal = _vaultAccounts.fold(0.0, (sum, item) => sum + item.balance);
        final consolidatedBalance = liquid + vaultTotal;
        
        return Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("SAVINGS GOALS",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: accentColor),
                    onPressed: () => _showAddGoalDialog(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  if (activeGoals.isEmpty && accomplishedGoals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_outlined, color: Colors.white.withValues(alpha: 0.05), size: 64),
                            const SizedBox(height: 16),
                            Text("NO GOALS SET", 
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.1), 
                                letterSpacing: 4, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w600
                              )
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (activeGoals.isNotEmpty) ...[
                      ...activeGoals.map((g) => _buildGoalCard(g, false, consolidatedBalance)),
                    ],
                    if (accomplishedGoals.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text("ACCOMPLISHED", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 8)])),
                      const SizedBox(height: 16),
                      ...accomplishedGoals.map((g) => _buildGoalCard(g, true, consolidatedBalance)),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildGoalCard(SavingsGoal g, bool isAccomplished, double balance) {
    final progress = isAccomplished ? 1.0 : (balance / g.targetAmount).clamp(0.0, 1.0);
    final remaining = g.targetAmount - balance;
    final netRate = _getRatePerSecond(netMonthlyIncome);
    final etaSeconds = (remaining > 0 && netRate > 0) ? (remaining / netRate).toInt() : -1;

    final days = etaSeconds >= 0 ? etaSeconds ~/ 86400 : 0;
    final hours = etaSeconds >= 0 ? (etaSeconds % 86400) ~/ 3600 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAccomplished ? Colors.white.withValues(alpha: 0.05) : accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAccomplished ? Colors.white10 : accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isAccomplished ? Icons.verified : Icons.emoji_events, color: isAccomplished ? Colors.white24 : accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(g.name.toUpperCase(), style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isAccomplished ? Colors.white24 : Colors.white,
                    decoration: isAccomplished ? TextDecoration.lineThrough : null,
                  )),
                ],
              ),
              Expanded(
                child: Text("$_currencySymbol${_f(g.targetAmount)} • ${(progress * 100).toStringAsFixed(1)}%", 
                  textAlign: TextAlign.end,
                  style: TextStyle(color: isAccomplished ? Colors.white24 : accentColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(isAccomplished ? Colors.white24 : accentColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          if (!isAccomplished) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (remaining > 0)
                  Expanded(child: Text("Remaining: $_currencySymbol${_f(remaining)}", style: const TextStyle(color: Colors.white38, fontSize: 11))),
                const SizedBox(width: 8),
                Text(remaining > 0 ? (etaSeconds < 0 ? "ETA: ∞ (No Income)" : "ETA: $days d $hours h") : "GOAL REACHED! 🎉",
                  style: TextStyle(color: remaining > 0 && etaSeconds >= 0 ? Colors.white38 : accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            if (remaining <= 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                  onPressed: () {
                    updateState(() {
                      balanceAdjustment -= g.targetAmount;
                      _history.insert(0, Transaction(
                        amount: g.targetAmount,
                        isIncome: false,
                        timestamp: DateTime.now(),
                        description: "Goal Purchased: ${g.name}",
                        category: "Goals"
                      ));
                      g.isAccomplished = true;
                    });
                    _autoSave();
                  },
                  child: const Text("PURCHASE / CLAIM GOAL", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ] else ...[
            const Text("Purchased & Accomplished", style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "NEW SAVINGS GOAL",
        icon: Icons.emoji_events,
        isLowPerformance: _isLowPerformance,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassTextField(controller: nameController, autofocus: false, hintText: "Goal name", isLowPerformance: _isLowPerformance),
            const SizedBox(height: 12),
            GlassTextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), hintText: "Target Amount", prefixText: "$_currencySymbol ", isLowPerformance: _isLowPerformance),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white24),
            GlassButton(
              isFilled: _isPremiumUser || _userCredits > 0,
              label: _isPremiumUser ? "CREATE" : "CREATE (1)",
              icon: _isPremiumUser ? null : Icons.water_drop_rounded,
              onPressed: (_isPremiumUser || _userCredits > 0) ? () {
                final val = double.tryParse(amountController.text) ?? 0.0;
                if (val > 0 && nameController.text.isNotEmpty) {
                  updateState(() {
                    if (!_isPremiumUser) _userCredits--; 
                    _goals.add(SavingsGoal(name: nameController.text.trim(), targetAmount: val, createdAt: DateTime.now()));
                  });
                  _autoSave();
                  Navigator.pop(context);
                }
              } : null,
            ),
        ],
      ),
    );
  }
}
