import 'package:flutter/material.dart';

class PlaceStickyActionBar extends StatelessWidget {
  const PlaceStickyActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F131A) : Colors.white;
    final border = isDark ? const Color(0xFF1F2530) : const Color(0xFFE2E8F0);
    final shadow = isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08);
    final outlineColor = isDark ? const Color(0xFF2B3442) : const Color(0xFFE2E8F0);
    final outlineText = isDark ? Colors.white70 : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: const Text('Luu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: outlineText,
                side: BorderSide(color: outlineColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Lên lịch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
