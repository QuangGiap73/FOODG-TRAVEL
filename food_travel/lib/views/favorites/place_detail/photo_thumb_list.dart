import 'package:flutter/material.dart';

class PhotoThumbList extends StatelessWidget {
  const PhotoThumbList({
    super.key,
    required this.photoUrls,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> photoUrls;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final url = photoUrls[i];
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? const Color(0xFFFF6A00) : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: url.isNotEmpty
                      ? Image.network(url, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1F242C)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
