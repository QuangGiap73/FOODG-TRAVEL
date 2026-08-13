import 'package:flutter/material.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF3A1D22) : const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5484D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE5484D)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color:
                      dark ? const Color(0xFFFFC7C7) : const Color(0xFF8C1D24),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
          ],
        ),
      ),
    );
  }
}
