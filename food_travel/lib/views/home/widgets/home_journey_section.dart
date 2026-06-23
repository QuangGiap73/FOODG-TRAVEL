import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/journey/badge_model.dart';
import '../../../models/journey/journey_stats.dart';
import '../../../models/journey/mission_model.dart';
import '../../journey/pages/food_journey_page.dart';
import '../../journey/pages/mission_detail_page.dart';

class HomeJourneySection extends StatelessWidget {
  const HomeJourneySection({
    super.key,
    required this.userId,
  });

  final String? userId;

  @override
  Widget build(BuildContext context) {
    final uid = userId?.trim();
    if (uid == null || uid.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Expanded(
                child: _JourneyOverviewCard(
                  userId: uid,
                  onTap: () => _openJourneyPage(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeMissionCard(
                  userId: uid,
                  onTapAll: () => _openJourneyPage(context),
                  onTapMission: (mission) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MissionDetailPage(mission: mission),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HomeBadgesRow(
          userId: uid,
          onTapAll: () => _openJourneyPage(context),
        ),
      ],
    );
  }

  void _openJourneyPage(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodJourneyPage()));
  }
}

class _JourneyOverviewCard extends StatelessWidget {
  const _JourneyOverviewCard({
    required this.userId,
    required this.onTap,
  });

  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JourneyStats>(
      stream: _statsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const JourneyStats();
        final level = stats.level <= 0 ? 1 : stats.level;
        final totalPoints = stats.totalPoints < 0 ? 0 : stats.totalPoints;
        final nextTarget = level * 100;
        final currentProgress = (totalPoints % 100).clamp(0, 100);
        final remain = (nextTarget - totalPoints).clamp(0, nextTarget);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9B24), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A1A).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Hanh trinh am thuc',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/provinces/journey/avatars/ha_noi_avatar.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explorer Lv.$level',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalPoints diem',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Streak',
                          value: '${stats.currentStreak} ngay',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Diem',
                          value: '$totalPoints',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: currentProgress / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.28),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Can $remain diem de len Lv.${level + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<JourneyStats> _statsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .snapshots()
        .map((snap) => JourneyStats.fromMap(snap.data()));
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMissionCard extends StatelessWidget {
  const _HomeMissionCard({
    required this.userId,
    required this.onTapAll,
    required this.onTapMission,
  });

  final String userId;
  final VoidCallback onTapAll;
  final ValueChanged<JourneyMission> onTapMission;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JourneyMission>>(
      stream: _missionStream(),
      builder: (context, snapshot) {
        final todayKey = _todayKey();
        final missions = snapshot.data ?? _fallbackMissions(todayKey);
        final visible = missions.take(2).toList();

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF2E4D3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 14,
                    color: Color(0xFFFF8A00),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Nhiem vu hom nay',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...visible.map((mission) {
                final isLast = mission.id == visible.last.id;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: _MissionRow(
                    mission: mission,
                    onTap: () => onTapMission(mission),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onTapAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tat ca nhiem vu',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B6D62),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF7B6D62),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<List<JourneyMission>> _missionStream() {
    final todayKey = _todayKey();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .collection('daily_missions')
        .doc(todayKey)
        .collection('missions')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return _fallbackMissions(todayKey);
          final list = snapshot.docs.map(JourneyMission.fromDoc).toList();
          list.sort((a, b) => b.rewardPoints.compareTo(a.rewardPoints));
          return list;
        });
  }

  List<JourneyMission> _fallbackMissions(String dateKey) {
    return [
      JourneyMission(
        id: 'checkin_new_place',
        title: 'Check-in 1 quan moi',
        description: '',
        type: 'checkin_new_place',
        targetCount: 1,
        currentCount: 0,
        rewardPoints: 30,
        iconKey: 'checkin',
        date: dateKey,
      ),
      JourneyMission(
        id: 'try_vietnamese_food',
        title: 'Thu mot mon Viet',
        description: '',
        type: 'try_vietnamese_food',
        targetCount: 1,
        currentCount: 0,
        rewardPoints: 20,
        iconKey: 'food',
        date: dateKey,
      ),
    ];
  }

  String _todayKey() {
    final vietnamDate = DateTime.now().toUtc().add(const Duration(hours: 7));
    final y = vietnamDate.year.toString();
    final m = vietnamDate.month.toString().padLeft(2, '0');
    final d = vietnamDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.onTap,
  });

  final JourneyMission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconOf(mission.iconKey),
              color: const Color(0xFFFF7A1A),
              size: 17,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mission.currentCount}/${mission.targetCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C7C7C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              '+${mission.rewardPoints}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF7A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconOf(String key) {
    switch (key) {
      case 'food':
        return Icons.ramen_dining_rounded;
      case 'checkin':
        return Icons.storefront_rounded;
      case 'save':
        return Icons.bookmark_rounded;
      case 'review':
        return Icons.star_rounded;
      default:
        return Icons.flag_rounded;
    }
  }
}

class _HomeBadgesRow extends StatelessWidget {
  const _HomeBadgesRow({
    required this.userId,
    required this.onTapAll,
  });

  final String userId;
  final VoidCallback onTapAll;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JourneyBadge>>(
      stream: _badgeStream(),
      builder: (context, snapshot) {
        final badges = snapshot.data ?? _fallbackBadges();
        final visible = _buildVisibleBadges(badges);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.military_tech_rounded,
                  size: 15,
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Huy hieu cua ban',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTapAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tat ca',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF7A1A),
                          ),
                        ),
                        SizedBox(width: 1),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 13,
                          color: Color(0xFFFF7A1A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(visible.length, (index) {
                final badge = visible[index];
                return Expanded(
                  child: _BadgeItem(
                    label: badge.label,
                    assetPath: badge.assetPath,
                    dimmed: badge.dimmed,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Stream<List<JourneyBadge>> _badgeStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .collection('badges')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return _fallbackBadges();
          return snapshot.docs.map(JourneyBadge.fromDoc).toList();
        });
  }

  List<_HomeBadgeUi> _buildVisibleBadges(List<JourneyBadge> badges) {
    final mapped = <String, JourneyBadge>{
      for (final badge in badges) badge.badgeId: badge,
    };
    return _badgeCatalog.map((visual) {
      final badge = mapped[visual.badgeId];
      final unlocked = badge?.isUnlocked == true;
      return _HomeBadgeUi(
        label: visual.label,
        assetPath: unlocked ? visual.assetPath : 'assets/journey/badges/locked_badge.png',
        dimmed: !unlocked,
      );
    }).toList();
  }

  List<JourneyBadge> _fallbackBadges() {
    return _badgeCatalog
        .map(
          (item) => JourneyBadge(
            badgeId: item.badgeId,
            title: item.label,
            description: '',
            iconKey: item.badgeId,
          ),
        )
        .toList();
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.label,
    required this.assetPath,
    required this.dimmed,
  });

  final String label;
  final String assetPath;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: dimmed ? const Color(0xFFA0A0A0) : const Color(0xFF303030),
          ),
        ),
      ],
    );
  }
}

class _HomeBadgeUi {
  const _HomeBadgeUi({
    required this.label,
    required this.assetPath,
    required this.dimmed,
  });

  final String label;
  final String assetPath;
  final bool dimmed;
}

class _HomeBadgeMeta {
  const _HomeBadgeMeta({
    required this.badgeId,
    required this.label,
    required this.assetPath,
  });

  final String badgeId;
  final String label;
  final String assetPath;
}

const List<_HomeBadgeMeta> _badgeCatalog = [
  _HomeBadgeMeta(
    badgeId: 'first_bite',
    label: 'First Bite',
    assetPath: 'assets/journey/badges/first_bite.png',
  ),
  _HomeBadgeMeta(
    badgeId: 'food_explorer',
    label: 'Food Explorer',
    assetPath: 'assets/journey/badges/food_explorer.png',
  ),
  _HomeBadgeMeta(
    badgeId: 'district_hunter',
    label: 'District Hunter',
    assetPath: 'assets/journey/badges/district_hunter.png',
  ),
  _HomeBadgeMeta(
    badgeId: 'province_explorer',
    label: 'Spicy Lover',
    assetPath: 'assets/journey/badges/province_explorer.png',
  ),
  _HomeBadgeMeta(
    badgeId: 'anonymous',
    label: 'An danh',
    assetPath: 'assets/journey/badges/locked_badge.png',
  ),
];
