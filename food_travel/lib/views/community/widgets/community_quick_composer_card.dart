import 'package:flutter/material.dart';

class CommunityQuickComposerCard extends StatefulWidget {
  const CommunityQuickComposerCard({
    super.key,
    required this.avatarUrl,
    required this.onImageTap,
    required this.onCheckInTap,
    required this.onReviewTap,
  });

  final String? avatarUrl;
  final VoidCallback onImageTap;
  final VoidCallback onCheckInTap;
  final VoidCallback onReviewTap;

  @override
  State<CommunityQuickComposerCard> createState() =>
      _CommunityQuickComposerCardState();
}

class _CommunityQuickComposerCardState extends State<CommunityQuickComposerCard> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1E26) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF101318) : const Color(0xFFF5F6F9);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white54 : const Color(0xFF9AA3AF);
    final pillTextColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final pillIconColor = const Color(0xFFFF8A00);
    final pillBackground = isDark
        ? Colors.white.withOpacity(0.04)
        : const Color(0xFFF8FAFC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.35),
                backgroundImage: widget.avatarUrl == null
                    ? null
                    : NetworkImage(widget.avatarUrl!),
                child: widget.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 1,
                  minLines: 1,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Bạn vừa ăn món gì ngon?',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.image_outlined,
                  label: 'Đăng ảnh',
                  iconColor: pillIconColor,
                  textColor: pillTextColor,
                  background: pillBackground,
                  onTap: widget.onImageTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  icon: Icons.place_outlined,
                  label: 'Check-in',
                  iconColor: pillIconColor,
                  textColor: pillTextColor,
                  background: pillBackground,
                  onTap: widget.onCheckInTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  icon: Icons.rate_review_outlined,
                  label: 'Review',
                  iconColor: pillIconColor,
                  textColor: pillTextColor,
                  background: pillBackground,
                  onTap: widget.onReviewTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
