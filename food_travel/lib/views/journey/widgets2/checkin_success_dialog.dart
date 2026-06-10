import 'package:flutter/material.dart';

import '../../../models/journey/checkin_result.dart';

Future<void> showCheckinSuccessDialog(
  BuildContext context, {
  required JourneyCheckinResult result,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (_) {
      return CheckinSuccessDialog(
        result: result,
      );
    },
  );
}

class CheckinSuccessDialog extends StatelessWidget {
  const CheckinSuccessDialog({
    super.key,
    required this.result,
  });

  final JourneyCheckinResult result;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const _ConfettiLayer(),

          Container(
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.fromLTRB(18, 46, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Check-in thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF66A832),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Bạn đã ăn tại',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  result.placeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  result.placeAddress,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 14),

                Image.asset(
                  'assets/journey/checkin_success_mascot.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.ramen_dining_rounded,
                      size: 88,
                      color: Color(0xFFFF8A00),
                    );
                  },
                ),

                const SizedBox(height: 14),

                _RewardCard(result: result),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF9A1F),
                          Color(0xFFFF6A00),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x45FF7A00),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Tuyệt vời! Tiếp tục hành trình',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF76C043),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF76C043).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.result,
  });

  final JourneyCheckinResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF3E1CA),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB000),
                size: 26,
              ),

              const SizedBox(width: 6),

              Text(
                '+${result.pointsEarned} điểm',
                style: const TextStyle(
                  color: Color(0xFFFF7A00),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _MiniRewardItem(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak',
                  value: '${result.currentStreak} ngày',
                ),
              ),

              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1E1D0),
              ),

              Expanded(
                child: _MiniRewardItem(
                  icon: Icons.emoji_events_rounded,
                  title: result.isNewPlace ? 'Quán mới' : 'Check-in',
                  value: result.isNewPlace ? '+20 điểm' : '+10 điểm',
                ),
              ),
            ],
          ),

          if (result.isNewProvince) ...[
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFE0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: Color(0xFFFF7A00),
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Khám phá tỉnh/thành mới +50 điểm',
                    style: TextStyle(
                      color: Color(0xFFFF7A00),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRewardItem extends StatelessWidget {
  const _MiniRewardItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF8A00),
          size: 19,
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF8A4300),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            _ConfettiDot(left: 18, top: 42, color: Color(0xFFFF6B6B)),
            _ConfettiDot(left: 42, top: 120, color: Color(0xFF4FC3F7)),
            _ConfettiDot(left: 260, top: 62, color: Color(0xFFFFC107)),
            _ConfettiDot(left: 278, top: 150, color: Color(0xFF8BC34A)),
            _ConfettiDot(left: 18, top: 240, color: Color(0xFFFFA726)),
            _ConfettiDot(left: 250, top: 250, color: Color(0xFFE57373)),
          ],
        ),
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({
    required this.left,
    required this.top,
    required this.color,
  });

  final double left;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: 0.7,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}