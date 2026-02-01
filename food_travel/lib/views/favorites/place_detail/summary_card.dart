import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          _QuickActions(phone: phone, placeName: name),
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

class _QuickActions extends StatefulWidget {
  const _QuickActions({required this.phone, required this.placeName});

  final String phone;
  final String placeName;

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  int _selected = 0;

  void _onSelect(int index) {
    setState(() {
      _selected = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.call,
          label: 'Goi dien',
          isActive: _selected == 0,
          onTap: () {
            _onSelect(0);
            _showCallSheet(context, widget.placeName, widget.phone);
          },
        ),
        _QuickAction(
          icon: Icons.navigation,
          label: 'Chi duong',
          isActive: _selected == 1,
          onTap: () => _onSelect(1),
        ),
        _QuickAction(
          icon: Icons.event,
          label: 'Dat ban',
          isActive: _selected == 2,
          onTap: () => _onSelect(2),
        ),
        _QuickAction(
          icon: Icons.group,
          label: 'Moi ban',
          isActive: _selected == 3,
          onTap: () => _onSelect(3),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFFF6A00);
    final bg = isActive ? const Color(0xFFFFF3E6) : const Color(0xFF1B2028);
    final border = isActive ? activeColor : const Color(0xFF2B3442);
    final textColor = isActive ? activeColor : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }
}

// ham mo bottom sheet goi dien
void _showCallSheet(BuildContext context, String placeName, String phone) {
  if (phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quan chua co so dien')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF15181E) : Colors.white;
      final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
      final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text(
              placeName,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(phone, style: TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Huy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Goi ngay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
