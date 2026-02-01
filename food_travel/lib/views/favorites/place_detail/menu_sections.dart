import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/places_model.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.actionText});

  final String title;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Text(actionText, style: const TextStyle(fontSize: 12, color: Color(0xFFFF6A00))),
        ],
      ),
    );
  }
}

class MustTrySection extends StatelessWidget {
  const MustTrySection({super.key, required this.items});

  final List<PlaceMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mon nen thu', actionText: 'Menu full'),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final item = items[i];
              return MenuCard(item: item);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class MenuHighlightsSection extends StatelessWidget {
  const MenuHighlightsSection({
    super.key,
    required this.placeKey,
    required this.textSecondary,
  });

  final String placeKey;
  final Color textSecondary;

  Future<List<PlaceMenuItem>> _fetchMenuItems() async {
    if (placeKey.isEmpty) return const [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('place_menus')
          .doc(placeKey)
          .collection('items')
          .limit(12)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return PlaceMenuItem(
          name: (data['name'] ?? '').toString(),
          price: (data['price'] ?? '').toString(),
          photoUrl: (data['photoUrl'] ?? '').toString(),
          badge: (data['badge'] ?? '').toString(),
        );
      }).where((e) => e.name.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaceMenuItem>>(
      future: _fetchMenuItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <PlaceMenuItem>[];
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Mon nen thu', actionText: 'Menu full'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Dang cap nhat mon nen thu.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ],
          );
        }
        return MustTrySection(items: items);
      },
    );
  }
}

class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.item});

  final PlaceMenuItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(item.photoUrl, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF1F242C)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item.price,
            style: const TextStyle(color: Color(0xFFFF6A00), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
