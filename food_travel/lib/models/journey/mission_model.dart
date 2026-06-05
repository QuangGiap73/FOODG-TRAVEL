import 'package:cloud_firestore/cloud_firestore.dart';

import 'journey_schema.dart';

class JourneyMission {
  const JourneyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    required this.rewardPoints,
    this.iconKey = 'mission',
    this.date,
    this.isCompleted = false,
    this.isClaimed = false,
    this.createdAt,
    this.completedAt,
    this.claimedAt,
    this.dueAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;

  /// Ví dụ:
  /// checkin_new_place, checkin_any_place, upload_photo, write_review, save_place
  final String type;

  final int targetCount;
  final int currentCount;
  final int rewardPoints;

  /// Dùng để UI chọn icon phù hợp.
  /// Ví dụ: checkin, camera, review, save, map
  final String iconKey;

  /// Dạng yyyy-MM-dd, ví dụ: 2026-06-04
  final String? date;

  final bool isCompleted;

  /// Đã nhận thưởng hay chưa.
  final bool isClaimed;

  final Timestamp? createdAt;
  final Timestamp? completedAt;
  final Timestamp? claimedAt;
  final Timestamp? dueAt;
  final Timestamp? updatedAt;

  double get progress {
    if (targetCount <= 0) return 0;
    final value = currentCount / targetCount;
    return value.clamp(0, 1).toDouble();
  }

  bool get canClaim => isCompleted && !isClaimed;

  factory JourneyMission.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return JourneyMission.fromMap(doc.data(), id: doc.id);
  }

  factory JourneyMission.fromMap(
    Map<String, dynamic>? map, {
    String? id,
  }) {
    final data = map ?? const <String, dynamic>{};

    final targetCount = _toInt(data[JourneyMissionFields.targetCount]);
    final currentCount = _toInt(data[JourneyMissionFields.currentCount]);
    final isCompletedFromData = data[JourneyMissionFields.isCompleted] == true;

    return JourneyMission(
      id: id ?? (data[JourneyMissionFields.id] ?? '').toString(),
      title: (data[JourneyMissionFields.title] ?? '').toString(),
      description: (data[JourneyMissionFields.description] ?? '').toString(),
      type: (data[JourneyMissionFields.type] ?? '').toString(),
      targetCount: targetCount,
      currentCount: currentCount,
      rewardPoints: _toInt(data[JourneyMissionFields.rewardPoints]),
      iconKey: (data[JourneyMissionFields.iconKey] ?? 'mission').toString(),
      date: _toNullableString(data[JourneyMissionFields.date]),
      isCompleted: isCompletedFromData || (targetCount > 0 && currentCount >= targetCount),
      isClaimed: data[JourneyMissionFields.isClaimed] == true,
      createdAt: _toTimestamp(data[JourneyMissionFields.createdAt]),
      completedAt: _toTimestamp(data[JourneyMissionFields.completedAt]),
      claimedAt: _toTimestamp(data[JourneyMissionFields.claimedAt]),
      dueAt: _toTimestamp(data[JourneyMissionFields.dueAt]),
      updatedAt: _toTimestamp(data[JourneyMissionFields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      JourneyMissionFields.id: id,
      JourneyMissionFields.title: title,
      JourneyMissionFields.description: description,
      JourneyMissionFields.type: type,
      JourneyMissionFields.targetCount: targetCount,
      JourneyMissionFields.currentCount: currentCount,
      JourneyMissionFields.rewardPoints: rewardPoints,
      JourneyMissionFields.iconKey: iconKey,
      JourneyMissionFields.date: date,
      JourneyMissionFields.isCompleted: isCompleted,
      JourneyMissionFields.isClaimed: isClaimed,
      JourneyMissionFields.createdAt: createdAt,
      JourneyMissionFields.completedAt: completedAt,
      JourneyMissionFields.claimedAt: claimedAt,
      JourneyMissionFields.dueAt: dueAt,
      JourneyMissionFields.updatedAt: updatedAt,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  JourneyMission copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? targetCount,
    int? currentCount,
    int? rewardPoints,
    String? iconKey,
    String? date,
    bool? isCompleted,
    bool? isClaimed,
    Timestamp? createdAt,
    Timestamp? completedAt,
    Timestamp? claimedAt,
    Timestamp? dueAt,
    Timestamp? updatedAt,
  }) {
    return JourneyMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      iconKey: iconKey ?? this.iconKey,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      dueAt: dueAt ?? this.dueAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Timestamp? _toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return text;
  }
}
