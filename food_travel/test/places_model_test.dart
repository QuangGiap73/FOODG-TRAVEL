import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/models/places_model.dart';

void main() {
  GoongNearbyPlace parse(String state, {Map<String, String>? schedule}) {
    return GoongNearbyPlace.fromSerpApi({
      'data_id': 'place-1',
      'title': 'Quán thử nghiệm',
      'address': 'TP. Hồ Chí Minh',
      'gps_coordinates': {'latitude': 10.77, 'longitude': 106.7},
      'open_state': state,
      'hours': state,
      if (schedule != null) 'operating_hours': schedule,
    });
  }

  test('parses Vietnamese open states returned by SerpAPI', () {
    expect(parse('Đang mở cửa · Đóng cửa vào 20:30').isOpen, isTrue);
    expect(parse('Mở cả ngày').isOpen, isTrue);
    expect(parse('Sắp đóng cửa · 22:00').isOpen, isTrue);
  });

  test('parses Vietnamese closed states returned by SerpAPI', () {
    expect(parse('Đã đóng cửa · Mở cửa lúc 7:00 Thứ 7').isOpen, isFalse);
    expect(parse('Sắp mở cửa · 15:00').isOpen, isFalse);
    expect(parse('Tạm thời đóng cửa').isOpen, isFalse);
  });

  test('keeps unknown state nullable instead of marking it closed', () {
    expect(parse('Không có thông tin').isOpen, isNull);
  });

  test('extracts closing time and weekly operating hours', () {
    final place = parse(
      'Đang mở cửa · Đóng cửa vào 20:30',
      schedule: {'thứ sáu': '08:30–20:30', 'thứ bảy': '08:30–20:30'},
    );

    expect(place.closingTime, '20:30');
    expect(place.openingHours, [
      'thứ sáu: 08:30–20:30',
      'thứ bảy: 08:30–20:30',
    ]);
  });
}
