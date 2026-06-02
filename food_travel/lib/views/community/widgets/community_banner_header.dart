import 'package:flutter/material.dart';

class CommunityBannerHeader extends StatelessWidget {
  const CommunityBannerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onSearchTap,
    required this.bellAction,
  });

  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onSearchTap;
  final Widget bellAction;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      color: isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF7),
      child: SizedBox(
        height: 138 + topInset,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                color:
                    isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFF1E2),
                child: Image.asset(
                  'assets/community/community_banner_bg.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) {
                    return const _CommunityHeaderFallbackBg();
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark ? Colors.black : Colors.white).withOpacity(
                        isDark ? 0.18 : 0.02,
                      ),
                      Colors.transparent,
                      (isDark ? Colors.black : Colors.white).withOpacity(
                        isDark ? 0.06 : 0.10,
                      ),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: topInset + 12,
              right: 126,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(top: topInset + 8, right: 52, child: bellAction),
            Positioned(
              top: topInset + 8,
              right: 12,
              child: CommunityHeaderActionIcon(
                icon: Icons.search_rounded,
                onTap: onSearchTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeaderFallbackBg extends StatelessWidget {
  const _CommunityHeaderFallbackBg();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CommunityHeaderFallbackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CommunityHeaderFallbackPainter extends CustomPainter {
  const _CommunityHeaderFallbackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    final bgPaint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFD8AD), Color(0xFFFFEAD2), Color(0xFFFFFBF7)],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    final wavePaint =
        Paint()
          ..color = const Color(0xFFFFB15C).withOpacity(0.45)
          ..style = PaintingStyle.fill;

    final wave =
        Path()
          ..moveTo(0, size.height * 0.70)
          ..cubicTo(
            size.width * 0.25,
            size.height * 0.58,
            size.width * 0.42,
            size.height * 0.84,
            size.width * 0.66,
            size.height * 0.66,
          )
          ..cubicTo(
            size.width * 0.83,
            size.height * 0.55,
            size.width * 0.94,
            size.height * 0.66,
            size.width,
            size.height * 0.60,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(wave, wavePaint);

    final frontWavePaint =
        Paint()
          ..color = const Color(0xFFFFD9AE).withOpacity(0.65)
          ..style = PaintingStyle.fill;

    final frontWave =
        Path()
          ..moveTo(0, size.height * 0.82)
          ..cubicTo(
            size.width * 0.26,
            size.height * 0.72,
            size.width * 0.45,
            size.height * 0.90,
            size.width * 0.70,
            size.height * 0.76,
          )
          ..cubicTo(
            size.width * 0.86,
            size.height * 0.68,
            size.width * 0.94,
            size.height * 0.76,
            size.width,
            size.height * 0.72,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(frontWave, frontWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CommunityHeaderActionIcon extends StatelessWidget {
  const CommunityHeaderActionIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0F172A)),
            if (hasDot)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
