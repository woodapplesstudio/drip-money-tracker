part of '../main.dart';

extension _BillsTabExtension on _TickerScreenState {
  Widget _buildBillsTab() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("RECURRING MONTHLY BILLS",
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                onPressed: _showAddBillDialog,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text("TOTAL MONTHLY OVERHEAD", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 2, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)]))),
              const SizedBox(width: 8),
              Text("-$_currencySymbol${_f(totalMonthlyBills)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
        Expanded(
          child: _recurringBills.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
                      const SizedBox(height: 16),
                      Text("CLEAN SHEET", 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.1), 
                          letterSpacing: 4, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                      const SizedBox(height: 8),
                      const Text("No recurring bills detected", style: TextStyle(color: Colors.white10, fontSize: 9)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                itemCount: _recurringBills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = _recurringBills[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Due on Day ${b.dueDay}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                        ),
                        Text("-$_currencySymbol${_f(b.amount)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white24, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                title: const Text("Delete Bill?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                content: Text("Are you sure you want to remove '${b.name}'? This will recalculate your monthly net overhead.", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                    onPressed: () {
                                      updateState(() => _recurringBills.removeAt(index));
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
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
