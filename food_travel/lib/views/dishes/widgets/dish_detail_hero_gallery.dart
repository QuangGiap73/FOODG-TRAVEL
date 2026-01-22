import 'dart:async';
import 'package:flutter/material.dart';
class DishDetailHeroGallery extends StatefulWidget {
  const DishDetailHeroGallery({
    super.key,
    required this.images,
    required this.onPageChanged,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
  });
  final List<String> images;
  final ValueChanged<int> onPageChanged;
  final bool autoPlay;
  final Duration autoPlayInterval;
  @override
  State<DishDetailHeroGallery> createState() => _DishDetailHeroGalleryState();
}
class _DishDetailHeroGalleryState extends State<DishDetailHeroGallery> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAuto();
  }
  @override
  void didUpdateWidget(covariant DishDetailHeroGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.isEmpty) {
      _timer?.cancel();
      return;
    }
    if (_index >= widget.images.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(_index);
      }
    }
    if (oldWidget.images.length != widget.images.length ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.autoPlayInterval != widget.autoPlayInterval) {
      _restartAuto();
    }
  }
  void _restartAuto() {
    _timer?.cancel();
    _startAuto();
  }
  void _startAuto() {
    if (!widget.autoPlay || widget.images.length < 2) return;
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.images.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }
  void _handlePageChanged(int index) {
    _index = index;
    widget.onPageChanged(index);
  }
  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      );
    }
    return PageView.builder(
      controller: _controller,
      itemCount: widget.images.length,
      onPageChanged: _handlePageChanged,
      itemBuilder: (context, i) {
        return Image.network(
          widget.images[i],
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
    final icon = isFavorite ? Icons.favorite : Icons.favorite_border;
    return DishDetailGlassIconButton(
      icon: icon,
      iconColor: isFavorite ? Colors.redAccent : Colors.white,
      onTap: onTap,
    );
  }
}
