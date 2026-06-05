import 'package:cloud_functions/cloud_functions.dart';

import '../../models/journey/checkin_result.dart';

class CheckinService {
  CheckinService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Goi Cloud Function createCheckin.
  ///
  /// App chi gui:
  /// - placeId
  /// - userLat
  /// - userLng
  /// - verificationType (optional)
  /// - source (optional)
  /// - photoUrl (optional)
  ///
  /// Server se tu:
  /// - lay quan tu Firestore
  /// - tinh khoang cach
  /// - kiem tra cooldown
  /// - cong diem
  /// - cap nhat streak
  /// - cap nhat badge
  Future<JourneyCheckinResult> createCheckin({
    required String placeId,
    required String placeName,
    required String placeAddress,
    required double placeLat,
    required double placeLng,
    required double userLat,
    required double userLng,
    String verificationType = 'gps',
    String source = 'gps',
    String? photoUrl,
    String? districtName,
    String? placeType,
    String? provinceCode,
    String? provinceName,
  }) async {
    try {
      // Ten function phai trung voi ten export trong functions/src/index.ts
      final callable = _functions.httpsCallable('createCheckin');

      final result = await callable.call(<String, dynamic>{
        'placeId': placeId,
        'placeName': placeName,
        'placeAddress': placeAddress,
        'placeLat': placeLat,
        'placeLng': placeLng,
        'userLat': userLat,
        'userLng': userLng,
        'verificationType': verificationType,
        'source': source,
        'photoUrl': photoUrl,
        'districtName': districtName,
        'placeType': placeType,
        'provinceCode': provinceCode,
        'provinceName': provinceName,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      return JourneyCheckinResult.fromMap(data);
    } on FirebaseFunctionsException catch (_) {
      // Giu nguyen ma loi cua Firebase de controller/UI map chinh xac hon.
      rethrow;
    } catch (_) {
      // Loi khac: network, parse data, app context ...
      throw Exception('Create checkin failed.');
    }
  }
}
