part of '../main.dart';

extension _VaultTabExtension on _TickerScreenState {
  Widget _buildVaultTab() {
    if (_tabIndex != 4) return const SizedBox.shrink(); // Prevent background rebuilds

    double totalVaultBalance = _vaultAccounts.fold(0, (s, a) => s + a.balance);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      children: [
        StreamBuilder<double>(
          stream: moneyStream(),
          builder: (context, snapshot) {
            final liquid = snapshot.data ?? 0.0;
            final netWorth = totalVaultBalance + liquid;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.2), Colors.transparent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CONSOLIDATED NET WORTH", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text("$_currencySymbol ${_f(netWorth)}", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: netWorth < 0 ? Colors.redAccent : Colors.greenAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _miniVaultStat("VAULT", totalVaultBalance, Colors.white38)),
                      const SizedBox(width: 16),
                      Expanded(child: _miniVaultStat("LIQUID", liquid, liquid < 0 ? Colors.redAccent : Colors.greenAccent)),
                    ],
                  ),
                ],
              ),
            );
          }
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ACCOUNTS & ASSETS", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
            TextButton.icon(
              onPressed: _showAddVaultAccountDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("ADD NEW", style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        if (_vaultAccounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_outlined, size: 56, color: Colors.white.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text("NO VAULTS FOUND", 
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1), 
                      letterSpacing: 3, 
                      fontSize: 9, 
                      fontWeight: FontWeight.w600
                    )
                  ),
                  const SizedBox(height: 4),
                  const Text("Create an account to secure your earnings", style: TextStyle(color: Colors.white10, fontSize: 8)),
                ],
              ),
            ),
          )
        else
          ..._vaultAccounts.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 10, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a.icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showVaultRenameDialog(a),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_outlined, size: 12, color: accentColor.withValues(alpha: 0.8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: accentColor.withValues(alpha: 0.3), size: 18),
                          onPressed: () => _showVaultDeleteDialog(a),
                          tooltip: "DELETE",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text("$_currencySymbol ${_f(a.balance)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: a.balance < 0 ? Colors.redAccent : Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("STATUS", style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  Text(a.balance >= 0 ? "SECURE" : "OVERDRAWN", style: TextStyle(color: a.balance >= 0 ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              _SleekTransactButton(
                                label: "TRANSACT",
                                icon: Icons.sync_alt,
                                onPressed: () => _showVaultAdjustDialog(a),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _miniVaultStat(String label, double amount, Color color) {
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
            child: Text("$_currencySymbol ${_f(amount)}", style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _SleekTransactButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  void _showVaultAdjustDialog(VaultAccount account) {
    final TextEditingController amountController = TextEditingController();
    bool isDeposit = true;

    showGlassOverlay(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => StreamBuilder<double>(
          stream: moneyStream(),
          builder: (context, snapshot) {
            final liquid = (snapshot.data ?? 0.0) < 0 ? 0.0 : (snapshot.data ?? 0.0);
            return GlassDialog(
              title: "VAULT TRANSACTION: ${account.name.toUpperCase()}",
              icon: Icons.account_balance,
              isLowPerformance: _isLowPerformance,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text("DEPOSIT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDeposit ? Colors.black : Colors.white70)), 
                        selected: isDeposit, 
                        onSelected: (v) => setDialogState(() => isDeposit = true), 
                        selectedColor: Colors.greenAccent,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: isDeposit ? Colors.greenAccent : Colors.white10),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text("WITHDRAW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: !isDeposit ? Colors.black : Colors.white70)), 
                        selected: !isDeposit, 
                        onSelected: (v) => setDialogState(() => isDeposit = false), 
                        selectedColor: Colors.redAccent,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: !isDeposit ? Colors.redAccent : Colors.white10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: amountController,
                    isLowPerformance: _isLowPerformance,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: "Amount", 
                    prefixText: "$_currencySymbol ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDeposit ? Colors.greenAccent : Colors.redAccent),
                    suffixIcon: TextButton(
                      onPressed: () {
                        amountController.text = isDeposit ? liquid.toStringAsFixed(2) : account.balance.toStringAsFixed(2);
                      },
                      child: Text("MAX", style: TextStyle(color: isDeposit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              actions: [
                GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
                GlassButton(
                  isFilled: _isPremiumUser || _userCredits > 0,
                  color: isDeposit ? accentColor : Colors.redAccent,
                  label: _isPremiumUser ? "CONFIRM" : "CONFIRM (1)",
                  icon: _isPremiumUser ? null : Icons.water_drop_rounded,
                  onPressed: (_isPremiumUser || _userCredits > 0) ? () {
                    final val = double.tryParse(amountController.text) ?? 0.0;
                    if (val > 0) {
                      if (!isDeposit && val > account.balance) {
                        _showToast("LIMIT EXCEEDED", "Insufficient Vault Balance", icon: Icons.warning, color: Colors.orangeAccent);
                        return;
                      }
                      updateState(() {
                        if (!_isPremiumUser) _userCredits--; 
                        if (isDeposit) {
                          account.balance += val;
                          balanceAdjustment -= val;
                          _history.insert(0, Transaction(amount: val, isIncome: false, timestamp: DateTime.now(), description: "Transfer -> ${account.name}", category: "Vault"));
                        } else {
                          account.balance -= val;
                          balanceAdjustment += val;
                          _history.insert(0, Transaction(amount: val, isIncome: true, timestamp: DateTime.now(), description: "Transfer <- ${account.name}", category: "Vault"));
                        }
                      });
                      _autoSave();
                      Navigator.pop(context);
                    }
                  } : null,
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  void _showAddVaultAccountDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "NEW VAULT ACCOUNT",
        icon: Icons.account_balance,
        isLowPerformance: _isLowPerformance,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassTextField(controller: nameController, autofocus: false, hintText: "Account Name (e.g. Bank)", isLowPerformance: _isLowPerformance),
            const SizedBox(height: 12),
            GlassTextField(controller: balanceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), hintText: "Starting Balance", prefixText: "$_currencySymbol ", isLowPerformance: _isLowPerformance),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white24),
          GlassButton(
            isFilled: _isPremiumUser || _userCredits >= 10,
            label: _isPremiumUser ? "CREATE" : "CREATE (10)",
            icon: _isPremiumUser ? null : Icons.water_drop_rounded,
            onPressed: (_isPremiumUser || _userCredits >= 10) ? () {
              final bal = double.tryParse(balanceController.text) ?? 0.0;
              if (nameController.text.isNotEmpty) {
                updateState(() {
                  if (!_isPremiumUser) _userCredits -= 10; 
                  _vaultAccounts.add(VaultAccount(id: DateTime.now().toString(), name: nameController.text.trim(), balance: bal));
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

  void _showVaultDepositBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StreamBuilder<double>(
          stream: moneyStream(),
          builder: (context, snapshot) {
            final rawLiquid = snapshot.data ?? 0.0;
            final liquid = rawLiquid < 0 ? 0.0 : rawLiquid;
            return Container(
              padding: EdgeInsets.only(top: 32, left: 32, right: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("DEPOSIT LIQUID TO VAULT", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                    const SizedBox(height: 20),
                    Text("$_currencySymbol${_f(rawLiquid)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: rawLiquid < 0 ? Colors.redAccent : Colors.white)),
                    const Text("CURRENT UNCLAIMED TOTAL", style: TextStyle(color: Colors.white24, fontSize: 10)),
                    const SizedBox(height: 32),
                    Text("SELECT DESTINATION ACCOUNT", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 8)])),
                    const SizedBox(height: 16),
                    if (_vaultAccounts.isEmpty)
                      const Text("No vault accounts found. Create one first.")
                    else
                      ..._vaultAccounts.map((a) => ListTile(
                        leading: Icon(a.icon, color: Colors.greenAccent),
                        title: Text(a.name),
                        subtitle: Text("Current: $_currencySymbol${_f(a.balance)}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white10),
                        onTap: () {
                          Navigator.pop(context);
                          _showDepositAmountDialog(a, liquid);
                        },
                      )),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showDepositAmountDialog(VaultAccount account, double maxLiquid) {
    final TextEditingController amountController = TextEditingController();
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "DEPOSIT TO ${account.name.toUpperCase()}",
        icon: Icons.upload_rounded,
        isLowPerformance: _isLowPerformance,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Available Liquid: $_currencySymbol${_f(maxLiquid)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            GlassTextField(
              controller: amountController,
              autofocus: false,
              isLowPerformance: _isLowPerformance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: "0.00",
              prefixText: "$_currencySymbol ",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              suffixIcon: maxLiquid > 0 ? TextButton(
                onPressed: () { 
                  amountController.text = maxLiquid.toStringAsFixed(2);
                },
                child: const Text("MAX", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ) : null,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: amountController,
              builder: (context, val, child) {
                final amount = double.tryParse(val.text) ?? 0.0;
                if (maxLiquid <= 0) {
                  return const Text("⚠️ Negative liquid balance. Deposit locked.", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold));
                }
                if (amount > maxLiquid) {
                  return Text("⚠️ Insufficient funds. (Short $_currencySymbol${_f(amount - maxLiquid)})", style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold));
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: amountController,
            builder: (context, val, child) {
              final amount = double.tryParse(val.text) ?? 0.0;
              final hasCred = _isPremiumUser || _userCredits > 0;
              final canConfirm = amount > 0 && amount <= maxLiquid && hasCred;
              return GlassButton(
                isFilled: canConfirm,
                color: Colors.greenAccent,
                label: _isPremiumUser ? "CONFIRM" : "CONFIRM (1)",
                icon: _isPremiumUser ? null : Icons.water_drop_rounded,
                onPressed: canConfirm ? () {
                  updateState(() {
                    if (!_isPremiumUser) _userCredits--; 
                    account.balance += amount;
                    balanceAdjustment -= amount;
                    _history.insert(0, Transaction(amount: amount, isIncome: false, timestamp: DateTime.now(), description: "Liquid Deposit -> ${account.name}", category: "Vault"));
                  });
                  _autoSave();
                  Navigator.pop(context);
                } : null,
              );
            },
          ),
        ],
      )
    );
  }

  void _showVaultRenameDialog(VaultAccount account) {
    final TextEditingController nameController = TextEditingController(text: account.name);
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "RENAME ACCOUNT",
        icon: Icons.edit_note,
        isLowPerformance: _isLowPerformance,
        content: GlassTextField(
          controller: nameController,
          autofocus: false,
          hintText: "New Name",
          isLowPerformance: _isLowPerformance,
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
          GlassButton(
            isFilled: true,
            label: "SAVE",
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                updateState(() => account.name = nameController.text.trim());
                _autoSave();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVaultDeleteDialog(VaultAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("DELETE ACCOUNT?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove '${account.name}'? All funds in this account will be permanently deleted from the ledger.", style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              updateState(() {
                if (account.balance != 0) {
                  // REFUND logic to prevent "Wealth Void" loophole
                  balanceAdjustment += account.balance;
                  _history.insert(0, Transaction(
                    amount: account.balance.abs(),
                    isIncome: account.balance > 0,
                    timestamp: DateTime.now(),
                    description: "Account Closed (Liquidated): ${account.name}",
                    category: "Vault"
                  ));
                }
                _vaultAccounts.remove(account);
              });
              _autoSave();
              Navigator.pop(ctx);
              _showToast("VAULT CLOSED", "Balance returned to liquid cash", icon: Icons.account_balance_wallet, color: Colors.greenAccent);
            },
            child: const Text("CLOSE & REFUND"),
          ),
        ],
      ),
    );
  }
}
