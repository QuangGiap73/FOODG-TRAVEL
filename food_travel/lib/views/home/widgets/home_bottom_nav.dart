import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

// Thanh dieu huong duoi (Home, Explore, Map, Saved, Profile)
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  Color get activeColor => const Color(0xFFFF6D00);
  Color get inactiveColor => Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    // Lay chu theo da ngon ngu (neu thieu key thi fallback bang text co san).
    final t = AppLocalizations.of(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    // Mau sac theo che do sang/toi.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F131A) : Colors.white.withOpacity(0.95);
    final shadowColor = isDark ? Colors.black.withOpacity(0.6) : Colors.black12;
    final borderColor = isDark ? const Color(0xFF0F131A) : Colors.white;
    final inactive = isDark ? const Color(0xFF9AA3AF) : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: Offset(0, -8),
            color: shadowColor,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(0, Icons.home_outlined, t?.personalHome ?? (isVi ? "Home" : "Home"), inactive),
          _buildItem(1, Icons.explore_outlined, isVi ? "Kham pha" : "Explore", inactive),
          _buildCenterMapButton(2, inactive, borderColor),
          _buildItem(3, Icons.favorite_border, t?.save ?? (isVi ? "Luu" : "Saved"), inactive),
          _buildItem(4, Icons.person_outline, isVi ? "Toi" : "Profile", inactive),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label, Color inactive) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          Icon(
            icon,
            size: 26,
            color: isActive ? activeColor : inactive,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? activeColor : inactive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterMapButton(int index, Color inactive, Color borderColor) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A50), Color(0xFFFF6D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Text(
            "Map",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? activeColor : inactive,
            ),
          ),
        ],
      ),
    );
  }
}
