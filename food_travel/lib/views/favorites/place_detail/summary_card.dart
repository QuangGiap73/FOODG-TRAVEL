import 'package:flutter/material.dart';

class PlaceSummaryCard extends StatelessWidget {
  const PlaceSummaryCard({
    super.key,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.district,
    required this.address,
    required this.phone,
  });

  final String name;
  final String category;
  final String price;
  final String rating;
  final int? reviewCount;
  final String district;
  final String address;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262B33) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          category,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0C2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFF6A00)),
                        const SizedBox(width: 4),
                        Text(
                          rating.isEmpty ? 'N/A' : rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6A00),
                          ),
                        ),
                      ],
                    ),
                    if (reviewCount != null)
                      Text(
                        '(${reviewCount!})',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (price.isNotEmpty)
                Text(price, style: TextStyle(color: textPrimary, fontSize: 13)),
              if (price.isNotEmpty) _Dot(textSecondary: textSecondary),
              if (district.isNotEmpty)
                Text(district, style: TextStyle(color: textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          _AddressRow(address: address, textSecondary: textSecondary),
          const SizedBox(height: 14),
          _QuickActions(phone: phone),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.textSecondary});

  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: textSecondary, shape: BoxShape.circle),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.textSecondary});

  final String address;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.place, size: 18, color: Color(0xFFFF6A00)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary),
          ),
        ),
        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _QuickAction(icon: Icons.call, label: 'Goi dien'),
        _QuickAction(icon: Icons.navigation, label: 'Chi duong'),
        _QuickAction(icon: Icons.event, label: 'Dat ban', highlight: true),
        _QuickAction(icon: Icons.group, label: 'Moi ban'),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? const Color(0xFFFFF3E6) : const Color(0xFFF8FAFC);
    final border = highlight ? const Color(0xFFFFE0C2) : const Color(0xFFE2E8F0);
    final color = highlight ? const Color(0xFFFF6A00) : const Color(0xFF64748B);
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
