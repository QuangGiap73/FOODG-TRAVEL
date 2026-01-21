import 'package:flutter/material.dart';

class DishDetailHeroGallery extends StatelessWidget {
  const DishDetailHeroGallery({required this.images, required this.onPageChanged});
  final List<String> images;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      );
    }

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, i) {
        return Image.network(
          images[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 40),
            ),
          ),
        );
      },
    );
  }
}

class DishDetailDotsIndicator extends StatelessWidget {
  const DishDetailDotsIndicator({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class DishDetailGlassIconButton extends StatelessWidget {
  const DishDetailGlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class DishDetailFavoriteButton extends StatelessWidget {
  const DishDetailFavoriteButton({
    required this.onTap,
    required this.isFavorite,
  });
  final VoidCallback onTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    // Hiện tại demo icon. Nếu gắn FavoriteController thì đổi theo isFavorite.
    final icon = isFavorite ? Icons.favorite : Icons.favorite_border;
    return DishDetailGlassIconButton(
      icon: icon,
      iconColor: isFavorite ? Colors.redAccent : Colors.white,
      onTap: onTap,
    );
  }
}

