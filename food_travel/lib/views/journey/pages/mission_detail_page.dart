import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/journey/mission_model.dart';

class MissionDetailPage extends StatefulWidget {
  const MissionDetailPage({
    super.key,
    required this.mission,
  });
  final JourneyMission mission;
  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}
class _MissionDetailPageState extends State<MissionDetailPage>{
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState(){
    super.initState();
    _updateRemainingTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }
  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }
  void _updateRemainingTime(){
    const vietnamOffset = Duration(hours: 7);
    final nowUtc = DateTime.now().toUtc();
    final vietnamNow = nowUtc.add(vietnamOffset);
    final vietnamEndOfDay = DateTime.utc(
      vietnamNow.year,
      vietnamNow.month,
      vietnamNow.day,
      23,
      59,
      59,
    );
    final remaining = vietnamEndOfDay.difference(vietnamNow);
    if(!mounted) return;

    setState(() {
      // xac dinh xe gio ngay co sai co am hay khong
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }
  @override
  Widget build(BuildContext context){
    final mission = widget.mission;
    final completed = mission.isCompleted || mission.progress >=1.0;

    final mainColor = completed 
      ? const Color(0xFF70B62C)
      : const Color(0xFFFF8A00);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      body: SafeArea(
        child: Column(
          children: [
            _MissionDetailAppBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  children: [
                    _MissionIconLarge(
                      iconKey: mission.iconKey,
                      color:mainColor,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      mission.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _ProgressSection(
                      mission: mission,
                      color: mainColor,
                    ),
                    const SizedBox(height: 20),

                    _RewardSection(
                      rewardPoints: mission.rewardPoints,
                    ),

                    const SizedBox(height: 20),

                    _TimeRemainingSection(
                      remaining: _remaining,
                    ),
                    const SizedBox(height: 34),

                    _ActionButton(
                      mission: mission,
                      completed: completed,
                      onPressed: () => _handleAction(context,mission),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  void _handleAction(BuildContext context, JourneyMission mission) {
    if (mission.isCompleted || mission.progress >= 1.0) {
      Navigator.of(context).pop();
      return;
    }

    switch (mission.type) {
      case 'checkin_new_place':
      case 'checkin_any_place':
        Navigator.of(context).pop();
        break;

      case 'save_wishlist_place':
        Navigator.of(context).pop();
        break;

      default:
        Navigator.of(context).pop();
        break;
    }
  }
}
// thanh appbar 
class _MissionDetailAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
              ),
              color: const Color(0xFF111111),
            ),
          ),

          const Text(
            'Chi tiết nhiệm vụ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
class _MissionIconLarge extends StatelessWidget {
  const _MissionIconLarge({
    required this.iconKey,
    required this.color,
  });

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.85),
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        _getIcon(iconKey),
        color: Colors.white,
        size: 42,
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'checkin':
        return Icons.location_on_rounded;

      case 'food':
        return Icons.ramen_dining_rounded;

      case 'save':
        return Icons.bookmark_rounded;

      case 'review':
        return Icons.star_rounded;

      case 'photo':
        return Icons.image_rounded;

      case 'map':
        return Icons.map_rounded;

      default:
        return Icons.flag_rounded;
    }
  }
}
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.mission,
    required this.color,
  });

  final JourneyMission mission;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1EEE9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '${mission.currentCount}/${mission.targetCount}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _RewardSection extends StatelessWidget {
  const _RewardSection({
    required this.rewardPoints,
  });

  final int rewardPoints;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phần thưởng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB000),
                size: 28,
              ),

              const SizedBox(width: 8),

              Text(
                '+$rewardPoints điểm',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF8A00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _TimeRemainingSection extends StatelessWidget {
  const _TimeRemainingSection({
    required this.remaining,
  });

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return _DetailCard(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thời gian còn lại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeBox(
                value: hours,
                label: 'giờ',
              ),
              const _TimeColon(),
              _TimeBox(
                value: minutes,
                label: 'phút',
              ),
              const _TimeColon(),
              _TimeBox(
                value: seconds,
                label: 'giây',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
class _TimeColon extends StatelessWidget {
  const _TimeColon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.mission,
    required this.completed,
    required this.onPressed,
  });

  final JourneyMission mission;
  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: completed
                ? const [
                    Color(0xFF70B62C),
                    Color(0xFF5BA51D),
                  ]
                : const [
                    Color(0xFFFF9A1F),
                    Color(0xFFFF6A00),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00).withOpacity(0.26),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            completed ? 'Đã hoàn thành' : _buttonText(mission.type),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  String _buttonText(String type) {
    switch (type) {
      case 'checkin_new_place':
      case 'checkin_any_place':
        return 'Đi khám phá ngay';

      case 'save_wishlist_place':
        return 'Tìm quán để lưu';

      case 'try_vietnamese_food':
        return 'Tìm món Việt ngay';

      default:
        return 'Bắt đầu nhiệm vụ';
    }
  }
}
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF4E5D6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}
