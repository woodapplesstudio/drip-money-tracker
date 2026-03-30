part of '../main.dart';

extension _HistoryTabExtension on _TickerScreenState {
  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text("TRANSACTION HISTORY",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                ),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          title: const Text("Clear History?", style: TextStyle(color: Colors.white)),
                          content: const Text("Are you sure you want to completely erase your transaction history? This cannot be undone.", style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              onPressed: () {
                                updateState(() => _history.clear());
                                _autoSave();
                                Navigator.pop(ctx);
                              },
                              child: const Text("CLEAR"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("CLEAR", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white54),
                  onPressed: () => updateState(() => _selectedHistoryMonth = DateTime(_selectedHistoryMonth.year, _selectedHistoryMonth.month - 1, 1)),
                ),
                TextButton(
                  onPressed: _showHistoryMonthPicker,
                  child: Text("${_monthNameFull(_selectedHistoryMonth.month).toUpperCase()} ${_selectedHistoryMonth.year}", 
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white54),
                  onPressed: () => updateState(() => _selectedHistoryMonth = DateTime(_selectedHistoryMonth.year, _selectedHistoryMonth.month + 1, 1)),
                ),
              ]
            ),
          ),
          const SizedBox(height: 12),
          _buildMonthAnalyticsSnapshot(),
          const SizedBox(height: 12),
          TabBar(
            indicatorColor: accentColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelColor: Colors.white24,
            tabs: [
              Tab(icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.redAccent), child: const Text("EXPENSE", style: TextStyle(color: Colors.redAccent))),
              Tab(icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.greenAccent), child: const Text("INCOME", style: TextStyle(color: Colors.greenAccent))),
              Tab(icon: const Icon(Icons.account_balance, size: 16, color: Colors.blueAccent), child: const Text("VAULT", style: TextStyle(color: Colors.blueAccent))),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryList(false, false),
                _buildHistoryList(true, false),
                _buildHistoryList(false, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthAnalyticsSnapshot() {
    final monthList = _history.where((t) => t.timestamp.year == _selectedHistoryMonth.year && t.timestamp.month == _selectedHistoryMonth.month).toList();
    final income = monthList.where((t) => t.isIncome && t.category != "Vault").fold(0.0, (s, t) => s + t.amount);
    final expense = monthList.where((t) => !t.isIncome && t.category != "Vault").fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MONTHLY PERFORMANCE", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 30, // Fixed height to maintain layout while scaling
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text("$_currencySymbol ${_f(net)}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: net >= 0 ? Colors.greenAccent : Colors.redAccent)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (net >= 0 ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (net >= 0 ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2)),
                ),
                child: Text(
                  net >= 0 ? "NET GAIN" : "NET LOSS",
                  style: TextStyle(color: net >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat("MONTHLY INCOME", income, Colors.greenAccent)),
              const SizedBox(width: 16),
              Expanded(child: _miniStat("MONTHLY SPENDING", expense, Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text("$_currencySymbol ${_f(amount)}", style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  void _showHistoryMonthPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white54), onPressed: () => updateState(() { _selectedHistoryMonth = DateTime(_selectedHistoryMonth.year - 1, _selectedHistoryMonth.month, 1); Navigator.pop(ctx); _showHistoryMonthPicker(); })),
            Text(_selectedHistoryMonth.year.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white54), onPressed: () => updateState(() { _selectedHistoryMonth = DateTime(_selectedHistoryMonth.year + 1, _selectedHistoryMonth.month, 1); Navigator.pop(ctx); _showHistoryMonthPicker(); })),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 12,
            itemBuilder: (ctx, index) {
              final month = index + 1;
              final isSelected = _selectedHistoryMonth.month == month;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  updateState(() => _selectedHistoryMonth = DateTime(_selectedHistoryMonth.year, month, 1));
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? accentColor : Colors.transparent),
                  ),
                  alignment: Alignment.center,
                  child: Text(_monthName(month).toUpperCase(), style: TextStyle(color: isSelected ? accentColor : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(bool isIncome, bool isVault) {
    final list = _history.where((t) {
      if (t.timestamp.year != _selectedHistoryMonth.year || t.timestamp.month != _selectedHistoryMonth.month) return false;
      if (isVault) {
        return t.category == "Vault";
      } else {
        return t.isIncome == isIncome && t.category != "Vault";
      }
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              Text("THE CHRONICLE", 
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1), 
                  letterSpacing: 4, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w600
                )
              ),
              const SizedBox(height: 8),
              const Text("No transactions recorded for this period", style: TextStyle(color: Colors.white10, fontSize: 9)),
            ],
          ),
        ),
      );
    }
    
    // Group by Date
    Map<String, List<Transaction>> grouped = {};
    for (var t in list) {
      String dateStr = "${t.timestamp.day} ${_monthName(t.timestamp.month)} ${t.timestamp.year}";
      grouped.putIfAbsent(dateStr, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        String dateKey = grouped.keys.elementAt(index);
        List<Transaction> dayTransactions = grouped[dateKey]!;
        double dayTotal = dayTransactions.fold(0, (sum, t) => sum + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 12)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${isVault ? (dayTransactions.first.isIncome ? "+" : (dayTransactions.first.description.contains("Deposit") ? "+" : "-")) : (isIncome ? "+" : "-")} $_currencySymbol ${_f(dayTotal)}", 
                        style: TextStyle(color: isVault ? (dayTransactions.first.isIncome || dayTransactions.first.description.contains("Deposit") ? Colors.greenAccent : Colors.redAccent) : (isIncome ? Colors.greenAccent : Colors.redAccent), fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...dayTransactions.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isVault ? (t.isIncome || t.description.contains("Deposit") ? Icons.account_balance : Icons.account_balance_wallet) : (t.isIncome ? Icons.add_circle : _getCategoryIcon(t.category)),
                            color: isVault ? (t.isIncome || t.description.contains("Deposit") ? Colors.greenAccent : Colors.redAccent) : (t.isIncome ? Colors.greenAccent : Colors.redAccent),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.description.isNotEmpty ? t.description.toUpperCase() : (isVault ? "VAULT TRANSFER" : (t.isIncome ? "MANUAL INCOME" : "MANUAL EXPENSE")),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1.2, color: Colors.white54),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, color: Colors.white12, size: 14),
                        onPressed: () => _removeTransaction(t),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${(isVault ? (t.isIncome || t.description.contains("Deposit") ? '+' : '-') : (t.isIncome ? "+" : "-"))} $_currencySymbol ${_f(t.amount)}",
                        style: TextStyle(
                          color: isVault ? (t.isIncome || t.description.contains("Deposit") ? Colors.greenAccent : Colors.redAccent) : (t.isIncome ? Colors.greenAccent : Colors.redAccent),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 8, color: Colors.white24),
                            const SizedBox(width: 3),
                            Text("${t.timestamp.hour}:${t.timestamp.minute.toString().padLeft(2, '0')}", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isVault ? (t.isIncome || t.description.contains("Deposit") ? Colors.greenAccent : Colors.redAccent) : (t.isIncome ? Colors.greenAccent : Colors.redAccent)).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(t.category.toUpperCase(), style: TextStyle(color: isVault ? (t.isIncome || t.description.contains("Deposit") ? Colors.greenAccent : Colors.redAccent) : (t.isIncome ? Colors.greenAccent : Colors.redAccent), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}
