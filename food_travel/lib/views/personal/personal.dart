import 'package:flutter/material.dart';

import '../../controller/personal_controller.dart';
import '../../router/route_names.dart';
import 'edit_personal.dart';
import 'package:food_travel/l10n/app_localizations.dart';


class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  late final PersonalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersonalController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    bool? result;
    try {
      result = await Navigator.of(context, rootNavigator: true)
          .pushNamed<bool>(RouteNames.editPersonal);
    } catch (_) {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const EditPersonalPage()),
      );
    }
    if (result == true) {
      _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.authUser == null) {
          return const _SignedOutView();
        }

        return _PersonalScaffold(
          viewData: _controller.viewData,
          isLoading: _controller.isLoading,
          onEditProfile: _openEdit,
        );
      },
    );
  }
}

class _PersonalScaffold extends StatelessWidget {
  const _PersonalScaffold({
    required this.viewData,
    required this.isLoading,
    required this.onEditProfile,
  });

  final PersonalViewData viewData;
  final bool isLoading;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(photoUrl: viewData.photoUrl),
              if (isLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  color: theme.colorScheme.primary,
                ),
              Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProfileCard(
                    name: viewData.name,
                    subtitle: viewData.subtitle,
                    photoUrl: viewData.photoUrl,
                    onTap: onEditProfile,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.verified_rounded,
                      color: Color(0xFFFFC857),
                      label: t.personalMembership,
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.storefront_rounded,
                      color: Color(0xFFFF7BA5),
                      label: t.personalStore,
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.home_rounded,
                      color: Color(0xFFFF8D6E),
                      label: t.personalHome,
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.people_alt_rounded,
                      color: Color(0xFF74C0FC),
                      label: t.personalGuests,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionItem(
                icon: Icons.favorite_border,
                title: t.personalStatus,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.themeSettings);
                },
              ),

              _SectionItem(
                icon: Icons.emoji_events_outlined,
                title: t.personalChangePassword,
                onTap: (){
                  Navigator.pushNamed(context, RouteNames.changePassword);
                },
              ),
              _SectionItem(
                icon: Icons.backpack_outlined,
                title: t.personalLanguage,
                onTap: (){
                  Navigator.pushNamed(context,RouteNames.languageSettings);
                },
              ),
              _SectionItem(
                icon: Icons.assignment_outlined,
                title: t.personalSurvey,
                onTap: (){
                  Navigator.pushNamed(context, RouteNames.survey);
                },
              ),
              
              _SectionItem(
                icon: Icons.my_location_outlined,
                title: 'Vi tri',
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.locationSettings);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Text(t.signInToViewProfile),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // xac dinh app dang o che do nao
    final isDark = theme.brightness == Brightness.dark;
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF2A2F3A), Color(0xFF171A20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF9FB1E5), Color(0xFFB9C7F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    return Container(
      height: 260,
      decoration:  BoxDecoration(
        gradient: gradient
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            left: -20,
            child: _GlowCircle(size: 140, color: Colors.white12),
          ),
          const Positioned(
            bottom: -30,
            right: -10,
            child: _GlowCircle(size: 120, color: Colors.white24),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    t.personalFreeWithdraw,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF6B6F80),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 34),
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.35),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.85),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 54,
                          color: colorScheme.onSurface.withOpacity(0.65),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final radius = BorderRadius.circular(20);
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.06);
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(color: subtitleColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.iconTheme.color?.withOpacity(0.6) ??
                      theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.06);
    final labelColor = theme.colorScheme.onSurface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: labelColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionItem extends StatelessWidget {
  const _SectionItem({
    required this.icon,
    required this.title,
    this.showDot = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.04);
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showDot)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: theme.iconTheme.color?.withOpacity(0.6) ??
                      theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
