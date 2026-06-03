import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/theme_controller.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  Future<void> _setMode(ThemeMode mode) async {
    await ThemeController().setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final controller = ThemeController();
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = (currentUser?.displayName?.trim().isNotEmpty ?? false)
        ? currentUser!.displayName!.trim()
        : 'Minh Anh';
    final subtitle = 'Explorer Lv.5 - FoodS';

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.themeMode;
        final isLightSelected = current == ThemeMode.light;
        final isDarkSelected = current == ThemeMode.dark;
        final isSystemSelected = controller.isAuto;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF0E1218) : const Color(0xFFF7F4EF);
        final cardBg = isDark ? const Color(0xFF171B22) : Colors.white;
        final borderColor = isDark ? const Color(0xFF2A303A) : const Color(0xFFE8E0D4);
        final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
        final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
        final accent = const Color(0xFFF97316);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _PageHeader(
                  title: t.themeSettingsTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 18),
                _HeroHeader(
                  displayName: displayName,
                  photoUrl: currentUser?.photoURL,
                  subtitle: subtitle,
                  imagePath: 'assets/setting/setting_theme.png',
                  accent: accent,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 18),
                Text(
                  t.themeAppearanceSection,
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.themeDisplayMode,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModeOptionTile(
                        title: t.themeLight,
                        subtitle: t.themeLightDesc,
                        icon: Icons.wb_sunny_rounded,
                        selected: isLightSelected,
                        accent: accent,
                        onTap: () => _setMode(ThemeMode.light),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ModeOptionTile(
                        title: t.themeDark,
                        subtitle: t.themeDarkDesc,
                        icon: Icons.nightlight_round,
                        selected: isDarkSelected,
                        accent: accent,
                        onTap: () => _setMode(ThemeMode.dark),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ModeOptionTile(
                        title: t.themeSystem,
                        subtitle: t.themeSystemDesc,
                        icon: Icons.phone_android_rounded,
                        selected: isSystemSelected,
                        accent: accent,
                        onTap: () => _setMode(ThemeMode.system),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t.themePreviewTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewCard(
                        title: t.themeLight,
                        isDarkPreview: false,
                        selected: current == ThemeMode.light,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PreviewCard(
                        title: t.themeDark,
                        isDarkPreview: true,
                        selected: current == ThemeMode.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.themePreviewNote,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.displayName,
    required this.photoUrl,
    required this.subtitle,
    required this.imagePath,
    required this.accent,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String displayName;
  final String? photoUrl;
  final String subtitle;
  final String imagePath;
  final Color accent;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF171B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A303A) : const Color(0xFFE8E0D4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1C212B), Color(0xFF10141B)]
              : const [Color(0xFFFFF5E9), Color(0xFFFFE7C6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 108),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AccountAvatar(
                  photoUrl: photoUrl,
                  displayName: displayName,
                  borderColor: Colors.white,
                  backgroundColor: surface,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Explorer',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -15,
            child: Image.asset(
              imagePath,
              width: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String? photoUrl;
  final String displayName;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final initial = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
        color: backgroundColor,
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                  initial: initial,
                  backgroundColor: backgroundColor,
                ),
              )
            : _AvatarFallback(
                initial: initial,
                backgroundColor: backgroundColor,
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initial,
    required this.backgroundColor,
  });

  final String initial;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Color(0xFFF97316),
        ),
      ),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF11161D) : Colors.white;
    final borderColor = selected ? accent : (isDark ? const Color(0xFF2A303A) : const Color(0xFFE8E0D4));
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final iconColor = selected ? accent : (isDark ? Colors.white70 : const Color(0xFF7A7F88));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1A202A) : const Color(0xFFF7F8FA)),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? accent : (isDark ? Colors.white30 : const Color(0xFFD4D9E0)),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.isDarkPreview,
    required this.selected,
  });

  final String title;
  final bool isDarkPreview;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = isDarkPreview ? const Color(0xFF1E2026) : Colors.white;
    final borderColor = selected ? const Color(0xFFF97316) : (isDarkPreview ? const Color(0xFF2A303A) : const Color(0xFFE8E0D4));
    final titleColor = isDarkPreview ? Colors.white : const Color(0xFF111827);
    final barColor = isDarkPreview ? Colors.white24 : const Color(0xFFD8DEE7);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkPreview ? 0.16 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 96,
              child: Image.asset(
                'assets/setting/setting-theme-2.jpg',
                fit: BoxFit.cover,
                alignment: isDarkPreview ? Alignment.centerRight : Alignment.centerLeft,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
