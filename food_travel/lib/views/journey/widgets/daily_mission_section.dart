import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../models/journey/mission_model.dart';

class DailyMissionSection extends StatefulWidget {
  const DailyMissionSection({
    super.key,
    required this.userId,
    this.onViewAll,
    this.onMissionTap,
  });

  final String? userId;
  final VoidCallback? onViewAll;
  final ValueChanged<JourneyMission>? onMissionTap;

  @override
  State<DailyMissionSection> createState() => _DailyMissionSectionState();
}

class _DailyMissionSectionState extends State<DailyMissionSection> {
  static const List<String> _missionOrder = [
    'favorite_any_place',
    'first_checkin_before_9am',
    'evening_checkin_after_18h',
    'checkin_high_rating_place',
    'earn_30_points_in_day',
    'revisit_a_place',
    'unlock_new_province',
    'checkin_new_place',
  ];

  @override
  void initState() {
    super.initState();
    _ensureDailyMissions();
  }

  Future<void> _ensureDailyMissions() async {
    final uid = widget.userId?.trim();
    if (uid == null || uid.isEmpty) return;

    try {
      await FirebaseFunctions.instance
          .httpsCallable('ensureDailyMissions')
          .call(<String, dynamic>{
        'dateKey': _getVietnamDateKey(DateTime.now()),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JourneyMission>>(
      stream: _missionStream(),
      builder: (context, snapshot) {
        final todayKey = _getVietnamDateKey(DateTime.now());

        final missions = snapshot.data ??
            _defaultMissions(
              dateKey: todayKey,
            );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF4E5D6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _SectionHeader(
                onViewAll: widget.onViewAll,
              ),

              const SizedBox(height: 12),

              if (snapshot.connectionState == ConnectionState.waiting)
                const _MissionLoading()
              else
                ...missions.map(
                  (mission) {
                    final isLast = mission.id == missions.last.id;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 10,
                      ),
                      child: _MissionItemCard(
                        mission: mission,
                        onTap: () => widget.onMissionTap?.call(mission),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Stream<List<JourneyMission>> _missionStream() {
    final uid = widget.userId?.trim();

    if (uid == null || uid.isEmpty) {
      return Stream.value(
        _defaultMissions(
          dateKey: _getVietnamDateKey(DateTime.now()),
        ),
      );
    }

    final todayKey = _getVietnamDateKey(DateTime.now());

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journey')
        .doc('summary')
        .collection('daily_missions')
        .doc(todayKey)
        .collection('missions')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _defaultMissions(
          dateKey: todayKey,
        );
      }

      final missions = snapshot.docs
          .map(JourneyMission.fromDoc)
          .toList();

      missions.sort(
        (a, b) => _missionSortValue(a.id).compareTo(_missionSortValue(b.id)),
      );

      return missions;
    });
  }

  static List<JourneyMission> _defaultMissions({
    required String dateKey,
  }) {
    return [
      JourneyMission(
        id: 'checkin_new_place',
        title: 'Check-in 1 quán mới',
        description: 'Hãy check-in tại một quán bạn chưa từng ăn.',
        type: 'checkin_new_place',
        iconKey: 'checkin',
        targetCount: 1,
        currentCount: 0,
        rewardPoints: 30,
        date: dateKey,
      ),

      JourneyMission(
        id: 'try_vietnamese_food',
        title: 'Thử một món Việt',
        description: 'Khám phá một món ăn Việt Nam hôm nay.',
        type: 'try_vietnamese_food',
        iconKey: 'food',
        targetCount: 1,
        currentCount: 0,
        rewardPoints: 20,
        date: dateKey,
      ),

      JourneyMission(
        id: 'save_wishlist_place',
        title: 'Lưu 1 quán muốn ăn',
        description: 'Lưu một quán vào danh sách yêu thích.',
        type: 'save_wishlist_place',
        iconKey: 'save',
        targetCount: 1,
        currentCount: 0,
        rewardPoints: 10,
        date: dateKey,
      ),
    ];
  }

  static int _missionSortValue(String type) {
    switch (type) {
      case 'checkin_new_place':
        return 1;

      case 'try_vietnamese_food':
        return 2;

      case 'save_wishlist_place':
        return 3;

      default:
        return 99;
    }
  }

  static String _getVietnamDateKey(DateTime date) {
    final vietnamDate = date.toUtc().add(
          const Duration(hours: 7),
        );

    final year = vietnamDate.year.toString();
    final month = vietnamDate.month.toString().padLeft(2, '0');
    final day = vietnamDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    this.onViewAll,
  });

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Nhiệm vụ hôm nay',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),

        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            children: [
              Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionItemCard extends StatelessWidget {
  const _MissionItemCard({
    required this.mission,
    this.onTap,
  });

  final JourneyMission mission;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final completed = mission.isCompleted || mission.progress >= 1.0;

    final mainColor = completed
        ? const Color(0xFF70B62C)
        : const Color(0xFFFF8A00);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 74,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF1E5DA),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _MissionIcon(
              iconKey: mission.iconKey,
              color: mainColor,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: mission.progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1EEE9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              mainColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        '${mission.currentCount}/${mission.targetCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${mission.rewardPoints} điểm',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF7A00),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (completed)
                    Container(
                      width: 23,
                      height: 23,
                      decoration: const BoxDecoration(
                        color: Color(0xFF70B62C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionIcon extends StatelessWidget {
  const _MissionIcon({
    required this.iconKey,
    required this.color,
  });

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        _getIcon(iconKey),
        color: Colors.white,
        size: 27,
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

      case 'clock':
        return Icons.schedule_rounded;

      case 'night':
        return Icons.dark_mode_rounded;

      case 'points':
        return Icons.workspace_premium_rounded;

      case 'repeat':
        return Icons.replay_rounded;

      case 'province':
        return Icons.explore_rounded;

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

class _MissionLoading extends StatelessWidget {
  const _MissionLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == 2 ? 0 : 10,
            ),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFF1E5DA),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
