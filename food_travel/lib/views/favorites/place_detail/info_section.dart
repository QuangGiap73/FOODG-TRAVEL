import 'package:flutter/material.dart';

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
              Text('Thong tin quan', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
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

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
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
                Text('Gio mo cua', style: TextStyle(color: widget.textSecondary, fontSize: 12)),
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
        Text(
          compact,
          style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.w600),
        ),
        if (_expanded && canExpand) ...[
          const SizedBox(height: 6),
          ...hours.skip(1).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(e, style: TextStyle(color: widget.textSecondary)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
    );
  }
}
