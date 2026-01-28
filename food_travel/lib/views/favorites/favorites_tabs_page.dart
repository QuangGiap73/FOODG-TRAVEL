import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'tabs/favorite_dishes_tab.dart';
import 'tabs/favorite_places_tab.dart';

// Trang yeu thich tong: co 2 tab (Mon an / Quan an)
class FavoritesTabsPage extends StatefulWidget {
  const FavoritesTabsPage({super.key});

  @override
  State<FavoritesTabsPage> createState() => _FavoritesTabsPageState();
}

class _FavoritesTabsPageState extends State<FavoritesTabsPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui long dang nhap')),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header sticky
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              backgroundColor: bgColor,
              surfaceTintColor: bgColor,
              // Giu header sticky nhung khong hien AppBar mac dinh
              toolbarHeight: 0,
              collapsedHeight: 0,
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                // Tang chieu cao de khong bi overflow
                preferredSize: const Size.fromHeight(176),
                child: Padding(
                  // Giam padding top de UI sat len tren
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title + action icon
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Da luu',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your favorites in one place',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CircleIconButton(
                            icon: Icons.search,
                            showDot: false,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _CircleIconButton(
                            icon: Icons.tune,
                            showDot: true,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TabSwitcher(
                        index: _tabIndex,
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                      const SizedBox(height: 10),
                      // Filter chips (demo UI)
                      SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            _FilterChipFilled(label: 'Central Vietnam'),
                            SizedBox(width: 8),
                            _FilterChipOutline(label: 'Spicy'),
                            SizedBox(width: 8),
                            _FilterChipOutline(label: 'Under 50k'),
                            SizedBox(width: 8),
                            _FilterChipOutline(label: 'Breakfast'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tabIndex == 0
                      ? FavoriteDishesTab(uid: user.uid)
                      : FavoritePlacesTab(uid: user.uid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------- TAB SWITCHER -----------------------
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1D22) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Dishes',
              icon: Icons.restaurant_menu,
              active: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Restaurants',
              icon: Icons.storefront,
              active: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = active
        ? (isDark ? const Color(0xFF22262C) : Colors.white)
        : Colors.transparent;
    final textColor = active
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (isDark ? Colors.white70 : const Color(0xFF64748B));

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------- SMALL WIDGETS -----------------------
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.showDot,
    required this.onTap,
  });

  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 22, color: iconColor),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? const Color(0xFF0F1115) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChipFilled extends StatelessWidget {
  const _FilterChipFilled({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111827) : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChipOutline extends StatelessWidget {
  const _FilterChipOutline({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F36) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
