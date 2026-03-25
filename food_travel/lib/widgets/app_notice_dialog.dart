import 'package:flutter/material.dart';

Future<bool?> showAppNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String? cancelText,
  Widget? icon,
  Color accentColor = const Color(0xFFFF7A00),
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return AppNoticeDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel:
            cancelText == null ? null : () => Navigator.pop(dialogContext, false),
        icon: icon,
        accentColor: accentColor,
      );
    },
  );
}

class AppNoticeDialog extends StatelessWidget {
  const AppNoticeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.accentColor = const Color(0xFFFF7A00),
  });

  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B1F28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor =
        isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(
                  accentColor: accentColor,
                  icon: icon,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (cancelText != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      cancelText!,
                      style: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: -22,
            left: 24,
            right: 24,
            child: _Ribbon(title: title, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.accentColor,
    this.icon,
  });

  final Color accentColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child:
            icon ??
            Icon(
              Icons.notifications_active_rounded,
              color: accentColor,
              size: 32,
            ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _RibbonTail(color: color, isLeft: true),
          ),
          Positioned(
            right: 0,
            child: _RibbonTail(color: color, isLeft: false),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonTail extends StatelessWidget {
  const _RibbonTail({required this.color, required this.isLeft});

  final Color color;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 24),
      painter: _RibbonTailPainter(color: color, isLeft: isLeft),
    );
  }
}

class _RibbonTailPainter extends CustomPainter {
  _RibbonTailPainter({required this.color, required this.isLeft});

  final Color color;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.9);
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
