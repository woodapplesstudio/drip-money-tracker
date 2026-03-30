import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium, glassmorphic text input field perfect for the futuristic theme.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? prefixText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool autofocus;
  final bool enabled;
  final bool isLowPerformance;
  final TextStyle? style;
  final TextCapitalization textCapitalization;

  const GlassTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixText,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.enabled = true,
    this.style,
    this.isLowPerformance = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isLowPerformance ? 0 : 3, sigmaY: isLowPerformance ? 0 : 3),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixText: prefixText,
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sleek, outline-styled button representing premium "Glass" aesthetics.
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final bool isFilled;
  final IconData? icon;

  const GlassButton({
    super.key,
    this.onPressed,
    required this.label,
    this.color,
    this.isFilled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    final textColor = activeColor == Colors.white24 ? Colors.white70 : activeColor;

    if (isFilled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.black, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.black),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: activeColor.withValues(alpha: 0.5), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: activeColor.withValues(alpha: 0.05),
      ),
      onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
        ),
    );
  }
}

/// A premium overlay transition that spring-pops into view.
Future<T?> showGlassOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    barrierColor: Colors.black.withValues(alpha: 0.4), 
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return builder(context); 
    },
    transitionBuilder: (context, anim1, anim2, child) {
       final curvedValue = Curves.easeOutBack.transform(anim1.value);
       final scale = 0.85 + (curvedValue * 0.15);

      return FadeTransition(
        opacity: anim1,
        child: Transform.scale(
          scale: scale,
          child: Center(
            child: Material(
               color: Colors.transparent,
               child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// A high-fidelity, custom glassmorphic dialog.
class GlassDialog extends StatefulWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color? iconColor;
  final bool isLowPerformance;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconColor,
    this.isLowPerformance = false,
  });

  @override
  State<GlassDialog> createState() => _GlassDialogState();
}

class _GlassDialogState extends State<GlassDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            margin: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: widget.isLowPerformance ? 0 : 6, sigmaY: widget.isLowPerformance ? 0 : 6),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131313).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05 + (0.1 * _pulseController.value)), 
                          width: 1.5
                        ),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.1 * _pulseController.value), blurRadius: 30, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: widget.iconColor ?? primaryColor, size: 32),
                              const SizedBox(height: 16),
                            ],
                            Text(widget.title.toUpperCase(), 
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18, color: Colors.white)),
                            const SizedBox(height: 10),
                            Container(height: 2, width: 40, color: primaryColor.withValues(alpha: 0.4)),
                            const SizedBox(height: 24),
                            widget.content,
                            const SizedBox(height: 32),
                            Row(
                              children: widget.actions.map((a) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: widget.actions.indexOf(a) == 0 ? 0 : 6,
                                    right: widget.actions.indexOf(a) == widget.actions.length - 1 ? 0 : 6,
                                  ),
                                  child: a,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
