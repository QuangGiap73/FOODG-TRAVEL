import 'package:flutter/material.dart';

class DishDetailBottomCtaBar extends StatelessWidget {
  const DishDetailBottomCtaBar({
    required this.onFavTap,
    required this.onFindNearbyTap,
  });

  final VoidCallback onFavTap;
  final VoidCallback onFindNearbyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.90),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 48,
            child: OutlinedButton(
              onPressed: onFavTap,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Icon(Icons.favorite_border,
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onFindNearbyTap,
                icon: const Icon(Icons.place_outlined),
                label: const Text(
                  'Tìm quán gần đây',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

