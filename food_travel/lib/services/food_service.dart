import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/dish_model.dart';
import '../models/province_model.dart';

/// Service truy cập dữ liệu món ăn/tỉnh thành.
class FoodService {
  FoodService._internal();
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;

  final _db = FirebaseFirestore.instance;

  /// Lắng nghe danh sách tỉnh (sắp xếp theo tên).
  Stream<List<ProvinceModel>> watchProvinces() {
    return _db
        .collection('provinces')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ProvinceModel.fromDoc).toList(),
        );
  }

  Stream<ProvinceModel?> watchProvinceById(String id) {
    return _db
        .collection('provinces')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? ProvinceModel.fromDoc(doc) : null);
  }

  /// Lấy món ăn theo mã tỉnh.
  Stream<List<DishModel>> watchDishesByProvince(String provinceCode) {
    return _db
        .collection('dishes')
        .where('province_code', isEqualTo: provinceCode)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DishModel.fromDoc).toList());
  }

  /// Lấy một món ăn theo id.
  Stream<DishModel?> watchDishById(String id) {
    return _db
        .collection('dishes')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? DishModel.fromDoc(doc) : null);
  }

  /// Lấy món theo nhiều biến thể mã tỉnh (code/id/name/slug...).
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

    debugPrint('[FoodService] query province_code keys=$keys');
    if (keys.isEmpty) return Stream.value(const <DishModel>[]);

    final limitedKeys = keys.length > 10 ? keys.sublist(0, 10) : keys;

    return _db
        .collection('dishes')
        .where('province_code', whereIn: limitedKeys)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(DishModel.fromDoc).toList())
        .asyncExpand((first) {
          if (first.isNotEmpty || keys.length <= 10) {
            return Stream.value(first);
          }
          final remaining =
              keys.sublist(10, keys.length > 20 ? 20 : keys.length);
          return _db
              .collection('dishes')
              .where('province_code', whereIn: remaining)
              .limit(20)
              .snapshots()
              .map((snap) => snap.docs.map(DishModel.fromDoc).toList())
              .map((second) => first.isNotEmpty ? first : second);
        });
  }

  /// Tìm kiếm món ăn theo text (không dấu), ưu tiên tỉnh nếu có.
  Future<List<DishModel>> searchDishes({
    required String query,
    String? provinceCode,
    int limit = 50,
  }) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];

    Query ref = _db.collection('dishes');
    if (provinceCode != null && provinceCode.trim().isNotEmpty) {
      ref = ref.where('province_code', isEqualTo: provinceCode.trim());
    }

    // Lấy rộng hơn rồi lọc client vì Firestore chưa full-text.
    final snap = await ref.limit(limit * 2).get();
    return snap.docs
        .map(DishModel.fromDoc)
        .where((d) {
          final name = d.name.toLowerCase();
          final tag = d.tag.toLowerCase();
          final slug = d.slug.toLowerCase();
          final normName = _normalize(d.name);
          return name.contains(normalized) ||
              tag.contains(normalized) ||
              slug.contains(normalized) ||
              normName.contains(normalized);
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
}
