import 'package:cloud_firestore/cloud_firestore.dart';
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

  Stream<List<DishModel>> watchDishesByProvinceKeys(
    Iterable<String> provinceKeys,
  ) {
    final keys = provinceKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList();
    if (keys.isEmpty) {
      return Stream.value(const <DishModel>[]);
    }

    Query<Map<String, dynamic>> query = _db.collection('dishes');
    if (keys.length == 1) {
      query = query.where('province_code', isEqualTo: keys.first);
    } else {
      final limitedKeys = keys.length > 10 ? keys.sublist(0, 10) : keys;
      query = query.where('province_code', whereIn: limitedKeys);
    }

    return query
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (d) => DishModel.fromDoc(d),
              )
              .toList(),
        );
  }
}
