import 'package:flutter/material.dart';

import 'place_detail_typography.dart';

class PlaceInfoSection extends StatelessWidget {
  const PlaceInfoSection({
    super.key,
    required this.hours,
    required this.amenities,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<String> hours;
  final List<String> amenities;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
              const SizedBox(width: 8),
              Text('Thong tin quan', style: PlaceDetailTypography.sectionTitle(textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          HoursRow(
            hours: hours,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.isEmpty
                ? const [
                    AmenityChip(text: 'May lanh'),
                    AmenityChip(text: 'Chuyen khoan'),
                    AmenityChip(text: 'Gui xe mien phi'),
                  ]
                : amenities.map((e) => AmenityChip(text: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class HoursRow extends StatefulWidget {
  const HoursRow({
    super.key,
    required this.hours,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<String> hours;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<HoursRow> createState() => _HoursRowState();
}

class _HoursRowState extends State<HoursRow> {
  bool _expanded = false;

  // Lam sach text gio mo cua de bo {} [] va dau phay du.
  String _cleanHourText(String raw) {
    return raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(' ,', ',')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours.map(_cleanHourText).where((e) => e.isNotEmpty).toList();
    final compact = hours.isEmpty ? 'Dang cap nhat gio mo cua' : hours.first;
    final canExpand = hours.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Gio mo cua', style: PlaceDetailTypography.caption(widget.textSecondary)),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: widget.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        Text(compact, style: PlaceDetailTypography.bodyStrong(widget.textPrimary)),
        if (_expanded && canExpand) ...[
          const SizedBox(height: 6),
          ...hours.skip(1).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(e, style: PlaceDetailTypography.body(widget.textSecondary)),
                ),
              ),
        ],
      ],
    );
  }
}

class AmenityChip extends StatelessWidget {
  const AmenityChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1B2028) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF2A323D) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(text, style: PlaceDetailTypography.chip(textColor)),
    );
  }
}
