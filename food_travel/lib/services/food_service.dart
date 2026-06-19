import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/dish_model.dart';
import '../models/province_model.dart';

/// Service truy cap du lieu mon an/tinh thanh.
class FoodService {
  FoodService._internal();
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;

  final _db = FirebaseFirestore.instance;
  static const _canonicalProvinceCollection = 'provinces_v2';
  static const _legacyProvinceCollection = 'provinces';
  static const _provinceDishQueryLimit = 120;
  static const _provinceDishDisplayLimit = 60;

  /// Lang nghe danh sach tinh (sap xep theo ten).
  Stream<List<ProvinceModel>> watchProvinces() {
    return _db
        .collection(_canonicalProvinceCollection)
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.map(ProvinceModel.fromDoc).toList();
          }
          final legacy = await _db
              .collection(_legacyProvinceCollection)
              .orderBy('name')
              .get();
          return legacy.docs.map(ProvinceModel.fromDoc).toList();
        });
  }

  Stream<ProvinceModel?> watchProvinceById(String id) {
    return _db
        .collection(_canonicalProvinceCollection)
        .doc(id)
        .snapshots()
        .asyncMap((doc) async {
          if (doc.exists) return ProvinceModel.fromDoc(doc);
          final legacy = await _db.collection(_legacyProvinceCollection).doc(id).get();
          return legacy.exists ? ProvinceModel.fromDoc(legacy) : null;
        });
  }

  /// Lay mon an theo ma tinh.
  /// Ho tro ca schema cu (province_code: String) va moi (province_code: {vi,en}).
  Stream<List<DishModel>> watchDishesByProvince(String provinceCode) {
    final normalizedTarget = _normalize(provinceCode);
    if (normalizedTarget.isEmpty) return Stream.value(const <DishModel>[]);

    return _db
        .collection('dishes')
        .limit(_provinceDishQueryLimit)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map(DishModel.fromDoc).toList();
      final filtered = all
          .where((dish) => _matchesProvinceTarget(dish, normalizedTarget))
          .toList()
        ..sort((a, b) => _provinceMatchScore(b, normalizedTarget)
            .compareTo(_provinceMatchScore(a, normalizedTarget)));
      return filtered.take(_provinceDishDisplayLimit).toList();
    });
  }

  /// Lay mot mon an theo id.
  Stream<DishModel?> watchDishById(String id) {
    return _db
        .collection('dishes')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? DishModel.fromDoc(doc) : null);
  }

  /// Lay mon theo nhieu bien the ma tinh (code/id/name/slug...).
  Stream<List<DishModel>> watchDishesByProvinceKeys(
    Iterable<String> provinceKeys,
  ) {
    final keys = provinceKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .map((key) {
          final lower = key.toLowerCase();
          final noDiacritics = _normalize(lower);
          final slug = noDiacritics.replaceAll(RegExp(r'\s+'), '_');
          return {key, lower, noDiacritics, slug};
        })
        .expand((set) => set)
        .toSet()
        .toList();

    debugPrint('[FoodService] query province keys=$keys');
    if (keys.isEmpty) return Stream.value(const <DishModel>[]);

    final keySet = keys.map(_normalize).where((e) => e.isNotEmpty).toSet();

    return _db.collection('dishes').limit(_provinceDishQueryLimit).snapshots().map((snap) {
      final all = snap.docs.map(DishModel.fromDoc).toList();
      final filtered = all.where((dish) {
        final candidates = _provinceCandidates(dish);
        return candidates.any(keySet.contains);
      }).toList()
        ..sort((a, b) => _provinceKeysMatchScore(b, keySet)
            .compareTo(_provinceKeysMatchScore(a, keySet)));
      return filtered.take(_provinceDishDisplayLimit).toList();
    });
  }

  /// Tim kiem mon an theo text (khong dau), uu tien tinh neu co.
  Future<List<DishModel>> searchDishes({
    required String query,
    String? provinceCode,
    int limit = 50,
  }) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];

    final normalizedProvince = _normalize(provinceCode ?? '');

    // Lay rong hon roi loc client vi Firestore chua full-text.
    final snap = await _db.collection('dishes').limit(limit * 6).get();
    return snap.docs
        .map(DishModel.fromDoc)
        .where((d) {
          if (normalizedProvince.isEmpty) return true;
          final canonicalCode = _normalize(d.provinceCode34);
          final canonicalName = _normalize(d.provinceName34);
          final legacy = _normalize(d.legacyProvinceCode);
          final vi = _normalize(d.provinceI18n['vi'] ?? d.provinceCode);
          final en = _normalize(d.provinceI18n['en'] ?? '');
          final raw = _normalize(d.provinceCode);
          return canonicalCode == normalizedProvince ||
              canonicalName == normalizedProvince ||
              legacy == normalizedProvince ||
              vi == normalizedProvince ||
              en == normalizedProvince ||
              raw == normalizedProvince;
        })
        .where((d) {
          final name = d.name.toLowerCase();
          final nameEn = d.getName('en').toLowerCase();
          final tag = d.tag.toLowerCase();
          final categoryEn = d.getCategory('en').toLowerCase();
          final slug = d.slug.toLowerCase();
          final normName = _normalize(d.name);
          final normNameEn = _normalize(d.getName('en'));
          return name.contains(normalized) ||
              nameEn.contains(normalized) ||
              tag.contains(normalized) ||
              categoryEn.contains(normalized) ||
              slug.contains(normalized) ||
              normName.contains(normalized) ||
              normNameEn.contains(normalized);
        })
        .take(limit)
        .toList();
  }

  String _normalize(String input) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = input.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i == -1 ? ch : to[i]);
    }
    return buf.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Set<String> _provinceCandidates(DishModel dish) {
    return <String>{
      _normalize(dish.provinceCode34),
      _normalize(dish.provinceName34),
      _normalize(dish.legacyProvinceCode),
      _normalize(dish.provinceCode),
      _normalize(dish.provinceI18n['vi'] ?? ''),
      _normalize(dish.provinceI18n['en'] ?? ''),
    }.where((value) => value.isNotEmpty).toSet();
  }

  bool _matchesProvinceTarget(DishModel dish, String normalizedTarget) {
    return _provinceCandidates(dish).contains(normalizedTarget);
  }

  int _provinceMatchScore(DishModel dish, String normalizedTarget) {
    var score = 0;
    if (_normalize(dish.provinceCode34) == normalizedTarget) score += 10;
    if (_normalize(dish.provinceName34) == normalizedTarget) score += 8;
    if (_normalize(dish.legacyProvinceCode) == normalizedTarget) score += 6;
    if (_normalize(dish.provinceCode) == normalizedTarget) score += 4;
    if (_normalize(dish.provinceI18n['vi'] ?? '') == normalizedTarget) score += 3;
    if (_normalize(dish.provinceI18n['en'] ?? '') == normalizedTarget) score += 2;
    return score;
  }

  int _provinceKeysMatchScore(DishModel dish, Set<String> normalizedKeys) {
    var score = 0;
    if (normalizedKeys.contains(_normalize(dish.provinceCode34))) score += 10;
    if (normalizedKeys.contains(_normalize(dish.provinceName34))) score += 8;
    if (normalizedKeys.contains(_normalize(dish.legacyProvinceCode))) score += 6;
    if (normalizedKeys.contains(_normalize(dish.provinceCode))) score += 4;
    if (normalizedKeys.contains(_normalize(dish.provinceI18n['vi'] ?? ''))) {
      score += 3;
    }
    if (normalizedKeys.contains(_normalize(dish.provinceI18n['en'] ?? ''))) {
      score += 2;
    }
    return score;
  }
}
