part of '../main.dart';

extension _SettingsTabExtension on _TickerScreenState {
  Widget _buildSettingsTab({ScrollController? scrollController}) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setSheetState) {
        return RepaintBoundary(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            children: [
            Text("SETTINGS",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
            const SizedBox(height: 20),
           _settingsGroup("AESTHETICS", [
            _settingsSwitch("Professional Mode", _isProfessionalMode, (val) {
              updateState(() => _isProfessionalMode = val);
              _autoSave();
              setSheetState(() {});
            }),
            _settingsSwitch("Low-Performance Mode", _isLowPerformance, (val) {
              updateState(() => _isLowPerformance = val);
              _autoSave();
              setSheetState(() {});
              _showToast("PERFORMANCE", val ? "PERFORMANCE MODE ENABLED" : "PERFORMANCE MODE DISABLED", icon: Icons.speed, color: val ? Colors.orangeAccent : Colors.blueAccent);
            }),
            if (_isProfessionalMode) ...[
              _settingsTile(
                "Background Style",
                subtitle: "Disabled (Professional Theme Enforced)",
                trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.blueAccent),
              ),
              _settingsTile(
                "App Theme",
                subtitle: "Disabled (Professional Theme Enforced)",
                trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.blueAccent),
              ),
            ] else ...[
              _settingsTile(
                "Background Style",
                subtitle: "Current: ${_currentBackground == BackgroundType.classic ? "DEFAULT" : _currentBackground.name.toUpperCase()}",
                trailing: Icon(Icons.arrow_forward_ios, size: 12, color: accentColor),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF161616),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: BackgroundType.values.where((type) {
                      // Only show Default, Unlocked, or EVERYTHING if Premium
                      return type == BackgroundType.classic || _unlockedBackgrounds.contains(type.index) || _isPremiumUser;
                    }).map((type) {
                      return ListTile(
                        title: Text(
                          type == BackgroundType.classic ? "DEFAULT" : type.name.toUpperCase(), 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: _currentBackground == type ? accentColor : Colors.white,
                          ),
                        ),
                        trailing: _currentBackground == type ? Icon(Icons.check, color: accentColor) : null,
                        onTap: () {
                          updateState(() => _currentBackground = type);
                          _autoSave();
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            _settingsTile(
              "App Theme",
              subtitle: "Current: ${_currentTheme.name[0].toUpperCase()}${_currentTheme.name.substring(1)}",
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                   _themeDot(ThemeType.matrix, const Color(0xFF00FF88), () { _autoSave(); setSheetState(() {}); }),
                   _themeDot(ThemeType.cyberpunk, const Color(0xFFFF00FF), () { _autoSave(); setSheetState(() {}); }),
                   _themeDot(ThemeType.electric, const Color(0xFF00E5FF), () { _autoSave(); setSheetState(() {}); }),
                   _themeDot(ThemeType.crimson, const Color(0xFFFF3D00), () { _autoSave(); setSheetState(() {}); }),
                   _themeDot(ThemeType.royal, const Color(0xFFD500F9), () { _autoSave(); setSheetState(() {}); }),
                   _themeDot(ThemeType.gold, const Color(0xFFFFD700), () { _autoSave(); setSheetState(() {}); }),
                ],
              ),
            ),
            ],
          ]),
            const SizedBox(height: 20),

            _settingsGroup("CURRENCY & REVENUE", [
              _settingsTile(
                "Manage Sources",
                subtitle: "${_incomeSources.length} sources active",
                trailing: Icon(Icons.arrow_forward_ios, size: 12, color: accentColor),
                onTap: _showMonthlyRevenueDialog,
              ),
              _settingsTile(
                "Currency Symbol",
                subtitle: "Current: $_currencySymbol",
                trailing: Icon(Icons.arrow_forward_ios, size: 12, color: accentColor),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF161616),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (ctx) => ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      children: ["₱", "\$", "€", "£", "¥"].map((v) => ListTile(
                        title: Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: _currencySymbol == v ? accentColor : Colors.white)),
                        trailing: _currencySymbol == v ? Icon(Icons.check, color: accentColor) : null,
                        onTap: () {
                          updateState(() => _currencySymbol = v);
                          _autoSave();
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                      )).toList(),
                    ),
                  );
                },
              ),
              _settingsTile(
                "Ticker Precision",
                subtitle: "Decimals: $_tickerPrecision",
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _tickerPrecision.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    activeColor: accentColor,
                    onChanged: (val) {
                      updateState(() => _tickerPrecision = val.toInt());
                      _autoSave();
                      setSheetState(() {});
                    },
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            _settingsGroup("VISIBLE RATES", [
              _settingsSwitch("Show /SEC", _showSec, (val) {
                updateState(() => _showSec = val);
                setSheetState(() {});
              }),
              _settingsSwitch("Show /MIN", _showMin, (val) {
                updateState(() => _showMin = val);
                setSheetState(() {});
              }),
              _settingsSwitch("Show /HR", _showHr, (val) {
                updateState(() => _showHr = val);
                setSheetState(() {});
              }),
              _settingsSwitch("Show /DAY", _showDay, (val) {
                updateState(() => _showDay = val);
                setSheetState(() {});
              }),
              _settingsSwitch("Show /WEEK", _showWeek, (val) {
                updateState(() => _showWeek = val);
                setSheetState(() {});
              }),
            ]),

            const SizedBox(height: 20),

            _settingsGroup("MIGRATION & STORAGE", [

              _settingsTile(
                "Export Account",
                subtitle: "Save your entire setup and vault",
                trailing: const Icon(Icons.copy_rounded, size: 16),
                onTap: _exportData,
              ),
              _settingsTile(
                "Import Account", 
                subtitle: "Restore or transfer your setup",
                trailing: const Icon(Icons.upload_rounded, size: 16),
                onTap: _importData,
              ),
              _settingsTile(
                "Reset Application", 
                subtitle: "Wipe all local data",
                textColor: Colors.redAccent,
                onTap: _confirmReset,
              ),
            ]),

            const SizedBox(height: 40),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- APP BRANDING ---
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/dripTextLogoMain.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Drip",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          shadows: [Shadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text("Money Tracker", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      const Text("v1.0.0", style: TextStyle(color: Colors.white12, fontSize: 8, letterSpacing: 2)),
                    ],
                  ),
                ),
                // --- DIVIDER ---
                Container(
                  width: 1,
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                // --- COMPANY BRANDING ---
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/woodApplesLogo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Wood Apples",
                        style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 2),
                      const Text("Studio", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text("\u00a9 2026 All Rights Reserved", style: TextStyle(color: Colors.white.withValues(alpha: 0.08), fontSize: 8, letterSpacing: 1)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    },
  );
}

  Widget _themeDot(ThemeType type, Color color, VoidCallback onUpdate) {
    bool isSelected = _currentTheme == type;
    return GestureDetector(
      onTap: () {
        updateState(() => _currentTheme = type);
        onUpdate();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : null,
        ),
      ),
    );
  }

  Widget _settingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 3, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingsTile(String title, {String? subtitle, Widget? trailing, VoidCallback? onTap, Color? textColor}) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor ?? Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: accentColor.withValues(alpha: 0.5), fontSize: 11)) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _settingsSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      value: value,
      onChanged: (val) {
        onChanged(val);
        _autoSave();
      },
      activeThumbColor: accentColor,
      activeTrackColor: accentColor.withValues(alpha: 0.3),
      visualDensity: VisualDensity.compact,
    );
  }



  void _exportData() {
    final Map<String, dynamic> data = {
      "iv": 6, // Upgraded version for Widget, Styles, BGs
      "mi": _incomeSources.map((i) => {
        "n": i.name, 
        "a": i.monthlyAmount, 
        "p": i.isPassive, 
        "sh": i.startHour, 
        "eh": i.endHour, 
        "wd": i.workDays
      }).toList(),
      "ba": balanceAdjustment,
      "cy": _currencySymbol,
      "pr": _tickerPrecision,
      "tm": _currentTheme.index,
      "bg": _currentBackground.index, // Save background type
      "pm": _isProfessionalMode,
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
      "uc": _userCredits,
      "ub": _unlockedBackgrounds.toList(),
      "pu": _isPremiumUser,
      "m1k": _milestone1000Reached,
      "iid": _installationId, // DEVICE LOCK SIGNATURE
    };
    
    // Add integrity signature
    data["sig"] = _generateSignature(data);

    final encoded = base64.encode(utf8.encode(jsonEncode(data)));
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "EXPORT ACCOUNT",
        icon: Icons.security_rounded,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This token contains all your settings, revenue sources, and history. Save it somewhere secure.", style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: encoded),
              readOnly: true,
              maxLines: 4,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white10),
            ),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CLOSE", color: Colors.white60),
          GlassButton(
            isFilled: true,
            label: "COPY",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: encoded));
              _showToast("ACCOUNT DATA", "ACCOUNT TOKEN COPIED!", icon: Icons.content_copy_rounded, color: Colors.greenAccent);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _importData() {
    final TextEditingController controller = TextEditingController();
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "IMPORT ACCOUNT",
        icon: Icons.cloud_download_rounded,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Paste your Pro Migration Token below. WARNING: This will completely replace your current setup, vault, and history.", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
            const SizedBox(height: 16),
            TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: "Paste token here...", filled: true, fillColor: Colors.white10)),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white60),
          GlassButton(
            isFilled: true,
            label: "RESTORE",
            onPressed: () {
              try {
                final String text = controller.text.trim();
                final decoded = utf8.decode(base64.decode(text));
                final Map<String, dynamic> data = jsonDecode(decoded);
                
                // --- SECURITY CHECK ---
                final String? sourceIid = data["iid"];
                final bool isForeign = sourceIid != _installationId;
                
                // Integrity Check
                final String? incomingSig = data["sig"];
                data.remove("sig");
                if (incomingSig != _generateSignature(data)) {
                   _showToast("INTEGRITY ERROR", "TAMPERED TOKEN DETECTED", icon: Icons.security_rounded, color: Colors.redAccent);
                   return;
                }
                
                if (isForeign && (data["pu"] == true || (data["uc"] ?? 0) > 25)) {
                  Navigator.pop(context);
                  _showForeignImportWarning(data);
                } else {
                  _applyData(data);
                  updateState(() => _tabIndex = 0); // RESET TO LIVE TAB
                  _autoSave();
                  Navigator.pop(context); // Close Import Dialog
                  Navigator.pop(context); // Close Settings Sheet
                }
              } catch (e) {
                _showToast("IMPORT ERROR", "INVALID TOKEN OR FAILED DATA", icon: Icons.error_outline, color: Colors.redAccent);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showForeignImportWarning(Map<String, dynamic> data) {
    showGlassOverlay(
      context: context,
      builder: (ctx) => GlassDialog(
        title: "SECURITY ALERT",
        icon: Icons.phonelink_lock_rounded,
        content: const Text(
          "This account token originated from a different device. \n\n"
          "To prevent unauthorized sharing, PREMIUM STATUS and DRIPS are locked to the original hardware.\n\n"
          "Importing will restore all settings, revenue streams, and history, but will EXCLUDE Premium/Drops.",
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(ctx), label: "CANCEL", color: Colors.white60),
          GlassButton(
            isFilled: true,
            color: Colors.amber,
            label: "IMPORT SECURELY",
            onPressed: () {
              // Strip locked assets
              data["pu"] = _isPremiumUser; // Keep current status
              data["uc"] = _userCredits;   // Keep current credits
              data["ub"] = _unlockedBackgrounds.toList(); // Keep current unlocks
              
              _applyData(data);
              updateState(() => _tabIndex = 0); // RESET TO LIVE TAB
              _autoSave();
              _showToast("SECURITY", "IMPORTED (ASSETS EXCLUDED)", icon: Icons.phonelink_lock_rounded, color: Colors.orangeAccent);
            },
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showGlassOverlay(
      context: context,
      builder: (context) => GlassDialog(
        title: "RESET EVERYTHING?",
        icon: Icons.warning_amber_rounded,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This will clear all your history, recurring bills, and revenue sources. This cannot be undone.", style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 16),
            Text("NOTE: Your PREMIUM status and EARNED CREDITS will NOT be deleted. They are safely tied to this device application.", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        actions: [
          GlassButton(onPressed: () => Navigator.pop(context), label: "CANCEL", color: Colors.white24),
          GlassButton(
            isFilled: true,
            color: Colors.redAccent,
            label: "RESET",
            onPressed: () {
              updateState(() {
                balanceAdjustment = 0;
                _history.clear();
                _recurringBills.clear();
                _goals.clear();
                _vaultAccounts.clear();
                _incomeSources.clear();
                _currentBackground = BackgroundType.classic;
                _currentTheme = ThemeType.matrix;
                _isProfessionalMode = false;
                _currencySymbol = "\$";
                _tickerPrecision = 4;
                _showSec = true;
                _showMin = true;
                _showHr = true;
                _showDay = true;
                _showWeek = true;
                _lastProcessedDate = DateTime.now();
                _tabIndex = 0; // RESET TO LIVE TAB
              });
              _autoSave();
              Navigator.pop(context); // Close Reset Dialog
              Navigator.pop(context); // Close Settings Sheet
            },
          ),
        ],
      ),
    );
  }
}
