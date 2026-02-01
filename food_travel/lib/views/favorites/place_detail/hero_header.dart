import 'package:flutter/material.dart';

class PlaceHeroHeader extends StatelessWidget {
  const PlaceHeroHeader({
    super.key,
    required this.photoUrls,
    required this.isOpen,
    required this.closingTime,
    required this.controller,
    required this.onIndexChanged,
    required this.onTapImage,
  });

  final List<String> photoUrls;
  final bool? isOpen;
  final String closingTime;
  final PageController controller;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<int> onTapImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrls.isEmpty)
            Container(color: const Color(0xFF2A2E33))
          else
            PageView.builder(
              controller: controller,
              itemCount: photoUrls.length,
              onPageChanged: onIndexChanged,
              itemBuilder: (context, index) {
                final url = photoUrls[index];
                return GestureDetector(
                  onTap: () => onTapImage(index),
                  child: url.isEmpty
                      ? Container(color: const Color(0xFF2A2E33))
                      : Image.network(url, fit: BoxFit.cover),
                );
              },
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIcon(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _CircleIcon(icon: Icons.share_outlined, onTap: () {}),
                    const SizedBox(width: 10),
                    _CircleIcon(icon: Icons.favorite_border, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: _StatusChip(isOpen: isOpen, closingTime: closingTime),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen, required this.closingTime});

  final bool? isOpen;
  final String closingTime;

  @override
  Widget build(BuildContext context) {
    final openText = isOpen == null
        ? 'DANG CAP NHAT'
        : (isOpen! ? 'MO CUA' : 'DONG CUA');
    final extra = closingTime.isNotEmpty ? ' - Dong luc $closingTime' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A00).withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$openText$extra',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
