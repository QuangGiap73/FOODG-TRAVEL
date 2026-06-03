import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/l10n/locale_controller.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = LocaleController().locale?.languageCode ?? 'vi';
  }

  Future<void> _setLang(String code) async {
    setState(() => _selected = code);
    await LocaleController().setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final controller = LocaleController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0E1218) : const Color(0xFFF7F4EF);
    final cardBg = isDark ? const Color(0xFF171B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A303A) : const Color(0xFFE8E0D4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final accent = const Color(0xFFF97316);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentCode = LocaleController().locale?.languageCode ?? _selected;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _TopBar(
                  title: t.language,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
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
                        t.languageAppSection,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LanguageTile(
                        flag: '🇻🇳',
                        title: t.vietnamese,
                        subtitle: t.languageDefault,
                        selected: currentCode == 'vi',
                        accent: accent,
                        onTap: () => _setLang('vi'),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _LanguageTile(
                        flag: '🇺🇸',
                        title: t.english,
                        subtitle: t.languageEnglishSubtitle,
                        selected: currentCode == 'en',
                        accent: accent,
                        onTap: () => _setLang('en'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.languageInfo,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.languageSupportedNote,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
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

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.isDark,
  });

  final String flag;
  final String title;
  final String subtitle;
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A202A) : const Color(0xFFF7F8FA),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 22),
                ),
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
                        height: 1.2,
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
