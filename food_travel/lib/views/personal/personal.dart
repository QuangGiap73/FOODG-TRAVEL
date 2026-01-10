import 'package:flutter/material.dart';

import '../../controller/personal_controller.dart';
import 'edit_personal.dart';

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
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditPersonalPage()),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(photoUrl: viewData.photoUrl),
              if (isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0xFFE6E9F0),
                  color: Color(0xFF8A9BD8),
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
                  children: const [
                    _QuickAction(
                      icon: Icons.verified_rounded,
                      color: Color(0xFFFFC857),
                      label: 'Hoi vien',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.storefront_rounded,
                      color: Color(0xFFFF7BA5),
                      label: 'Cua hang',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.home_rounded,
                      color: Color(0xFFFF8D6E),
                      label: 'To am',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.people_alt_rounded,
                      color: Color(0xFF74C0FC),
                      label: 'Khach',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionItem(
                icon: Icons.favorite_border,
                title: 'Trang thai cua toi',
              ),
              const _SectionItem(
                icon: Icons.emoji_events_outlined,
                title: 'Thanh tich cua toi',
              ),
              const _SectionItem(
                icon: Icons.backpack_outlined,
                title: 'Ba lo cua toi',
                showDot: true,
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
    return const Scaffold(
      body: Center(
        child: Text('Please sign in to view your profile.'),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9FB1E5), Color(0xFFB9C7F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text(
                    'Rut mien phi',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
                color: Colors.white.withOpacity(0.35),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withOpacity(0.85),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : const Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 54,
                          color: Color(0xFF6B6F80),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  backgroundColor: const Color(0xFFEFEFF6),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF6B6F80),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                              color: const Color(0xFFEFF2F8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ID',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B6F80),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(color: Color(0xFF8A8F9A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB0B3C2)),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
  });

  final IconData icon;
  final String title;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: const Color(0xFFEFF2F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF4F596A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
            const Icon(Icons.chevron_right, color: Color(0xFFB0B3C2)),
          ],
        ),
      ),
    );
  }
}