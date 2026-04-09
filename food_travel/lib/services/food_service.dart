import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/province_model.dart';
import '../models/dish_model.dart';

// lay dữ liệu từ firebase
class FoodService {
  FoodService._internal();
  static final FoodService _instance = FoodService._internal(); // tạo duy nhất 1 instance
  factory FoodService() => _instance;
  // lấy instance Firestore dùng chung cho toàn app
  final _db = FirebaseFirestore.instance;
  // lắng nghe từ danh sách tỉnh để trả UI món ăn đúng
  Stream<List<ProvinceModel>> watchProvinces(){
    return _db
      .collection('provinces')
      .orderBy('name') // sắp xếp tỉnh theo tên
      .snapshots() // lứng nghe dữ liệu realtime
      // chuyển query sang list
      .map(
        (snapshot) => 
            snapshot.docs
                .map(
                  (d) => ProvinceModel.fromDoc(d),
                )
                .toList(),
      );
  }
  Stream<ProvinceModel?> watchProvinceById(String id){
    return _db 
        .collection('provinces')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? ProvinceModel.fromDoc(doc) : null);
  }
  // lang nghe mon ăn theo tỉnh
  Stream<List<DishModel>> watchDishesByProvince(String provinceCode){
    return _db
      .collection('dishes')
      // lọc món theo mã tỉnh
      .where(
        'province_code',
        isEqualTo: provinceCode,
      )
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => 
            snapshot.docs
              .map(
                (d) => DishModel.fromDoc(d),
              )
              .toList(),
      );
  }
  // lắng nghe realtime từ firebase
  Stream<DishModel?> watchDishById(String id) {
    return _db  
        .collection('dishes')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? DishModel.fromDoc(doc) : null);
  }

  Stream<List<DishModel>> watchDishesByProvinceKeys(
    Iterable<String> provinceKeys,
  ) {
    final keys = provinceKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .map((key) {
          final lower = key.toLowerCase();
          // Firestore lưu province_code dạng "Lang Son" => thử thêm biến thể không dấu.
          final noDiacritics = lower
              .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
              .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
              .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
              .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
              .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
              .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
              .replaceAll(RegExp(r'[đ]'), 'd')
              .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
              .trim();
          final slug = noDiacritics.replaceAll(RegExp(r'\s+'), '_');
          return {key, lower, noDiacritics, slug};
        })
        .expand((set) => set)
        .toSet()
        .toList();
    debugPrint('[FoodService] query province_code keys=$keys');
    if (keys.isEmpty) {
      return Stream.value(const <DishModel>[]);
    }

    // Nếu nhiều khóa, thử whereIn trước; nếu Firestore giới hạn, fallback dùng array-contains any theo batches.
    final limitedKeys = keys.length > 10 ? keys.sublist(0, 10) : keys;

    return _db
        .collection('dishes')
        .where('province_code', whereIn: limitedKeys)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs.map((d) => DishModel.fromDoc(d)).toList();
            debugPrint('[FoodService] fetched ${list.length} dishes for keys=$limitedKeys');
            return list;
          },
        )
        // Nếu rỗng, thử lần hai với những key còn lại (nếu có).
        .asyncExpand((first) {
          if (first.isNotEmpty || keys.length <= 10) {
            return Stream.value(first);
          }
          final remaining = keys.sublist(10, keys.length > 20 ? 20 : keys.length);
          return _db
              .collection('dishes')
              .where('province_code', whereIn: remaining)
              .limit(20)
              .snapshots()
              .map((snap) => snap.docs.map(DishModel.fromDoc).toList())
              .map((second) => first.isNotEmpty ? first : second);
        });
  }
}
