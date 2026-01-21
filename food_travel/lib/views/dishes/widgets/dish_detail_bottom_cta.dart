import 'package:flutter/material.dart';

class DishDetailBottomCtaBar extends StatelessWidget {
  const DishDetailBottomCtaBar({
    required this.onFavTap,
    required this.onFindNearbyTap,
    required this.isFavorite,
  });

  final VoidCallback onFavTap;
  final VoidCallback onFindNearbyTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favColor = isFavorite
        ? Colors.redAccent
        : theme.colorScheme.onSurface.withOpacity(0.55);

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
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: onFavTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: favColor,
              ),
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

