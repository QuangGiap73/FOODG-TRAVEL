import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';

class ProvinceResolution {
  const ProvinceResolution({
    required this.provinceCode,
    required this.provinceName,
    this.rawProvinceName = '',
  });

  final String provinceCode;
  final String provinceName;
  final String rawProvinceName;
}

class GeocodeService {
  ProvinceResolution? resolveProvince34FromText(Iterable<String?> values) {
    for (final raw in values) {
      final text = (raw ?? '').trim();
      if (text.isEmpty) continue;

      final normalizedText = _normalizeProvinceName(text);
      for (final entry in _provinceCodeByNormalizedName.entries) {
        if (!normalizedText.contains(entry.key)) continue;
        final canonicalName = _provinceNameByCode[entry.value] ?? text;
        return ProvinceResolution(
          provinceCode: entry.value,
          provinceName: canonicalName,
          rawProvinceName: text,
        );
      }
    }
    return null;
  }

  Future<String?> reverseProvinceName(double lat, double lng) async {
    final data = await _reverseGeocode(lat, lng);
    if (data == null) return null;

    final results = data['results'] as List? ?? [];
    for (final item in results) {
      final comps = item['address_components'] as List? ?? [];
      for (final comp in comps) {
        final types =
            (comp['types'] as List?)?.cast<String>() ?? const <String>[];
        if (types.contains('administrative_area_level_1')) {
          final name = (comp['long_name'] ?? '').toString().trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    return null;
  }

  Future<ProvinceResolution?> resolveProvince34(double lat, double lng) async {
    final rawName = await reverseProvinceName(lat, lng);
    if (rawName == null || rawName.trim().isEmpty) return null;

    final normalized = _normalizeProvinceName(rawName);
    final resolvedCode = _provinceCodeByNormalizedName[normalized];
    if (resolvedCode == null || resolvedCode.isEmpty) return null;

    final canonicalName = _provinceNameByCode[resolvedCode] ?? rawName.trim();
    return ProvinceResolution(
      provinceCode: resolvedCode,
      provinceName: canonicalName,
      rawProvinceName: rawName.trim(),
    );
  }

  Future<ProvinceResolution?> resolveProvince34WithFallback({
    required double lat,
    required double lng,
    Iterable<String?> fallbackTexts = const [],
  }) async {
    final fromText = resolveProvince34FromText(fallbackTexts);
    if (fromText != null) return fromText;
    return resolveProvince34(lat, lng);
  }

  Future<Map<String, dynamic>?> _reverseGeocode(double lat, double lng) async {
    final uri = Uri.https('rsapi.goong.io', '/Geocode', {
      'latlng': '$lat,$lng',
      'api_key': goongPlacesApiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    return data;
  }

  static String _normalizeProvinceName(String input) {
    final lower = input
        .trim()
        .toLowerCase()
        .replaceAll('tỉnh', '')
        .replaceAll('thành phố', '')
        .replaceAll('tp.', '')
        .replaceAll('tp ', '')
        .replaceAll('city', '')
        .trim();

    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i == -1 ? ch : to[i]);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

const Map<String, String> _provinceNameByCode = {
  'an_giang': 'An Giang',
  'bac_ninh': 'Bắc Ninh',
  'can_tho': 'Cần Thơ',
  'cao_bang': 'Cao Bằng',
  'ca_mau': 'Cà Mau',
  'da_nang': 'Đà Nẵng',
  'dak_lak': 'Đắk Lắk',
  'dien_bien': 'Điện Biên',
  'dong_nai': 'Đồng Nai',
  'dong_thap': 'Đồng Tháp',
  'gia_lai': 'Gia Lai',
  'ha_noi': 'Hà Nội',
  'ha_tinh': 'Hà Tĩnh',
  'hai_phong': 'Hải Phòng',
  'hung_yen': 'Hưng Yên',
  'hue': 'Huế',
  'khanh_hoa': 'Khánh Hòa',
  'lai_chau': 'Lai Châu',
  'lam_dong': 'Lâm Đồng',
  'lang_son': 'Lạng Sơn',
  'lao_cai': 'Lào Cai',
  'nghe_an': 'Nghệ An',
  'ninh_binh': 'Ninh Bình',
  'phu_tho': 'Phú Thọ',
  'quang_ngai': 'Quảng Ngãi',
  'quang_ninh': 'Quảng Ninh',
  'quang_tri': 'Quảng Trị',
  'son_la': 'Sơn La',
  'tay_ninh': 'Tây Ninh',
  'thai_nguyen': 'Thái Nguyên',
  'thanh_hoa': 'Thanh Hóa',
  'thanh_pho_ho_chi_minh': 'Thành phố Hồ Chí Minh',
  'tuyen_quang': 'Tuyên Quang',
  'vinh_long': 'Vĩnh Long',
};

final Map<String, String> _provinceCodeByNormalizedName = {
  'an giang': 'an_giang',
  'bac ninh': 'bac_ninh',
  'can tho': 'can_tho',
  'cao bang': 'cao_bang',
  'ca mau': 'ca_mau',
  'da nang': 'da_nang',
  'dak lak': 'dak_lak',
  'daklak': 'dak_lak',
  'dien bien': 'dien_bien',
  'dong nai': 'dong_nai',
  'dong thap': 'dong_thap',
  'gia lai': 'gia_lai',
  'ha noi': 'ha_noi',
  'ha tinh': 'ha_tinh',
  'hai phong': 'hai_phong',
  'hung yen': 'hung_yen',
  'hue': 'hue',
  'thua thien hue': 'hue',
  'khanh hoa': 'khanh_hoa',
  'lai chau': 'lai_chau',
  'lam dong': 'lam_dong',
  'lang son': 'lang_son',
  'lao cai': 'lao_cai',
  'nghe an': 'nghe_an',
  'ninh binh': 'ninh_binh',
  'phu tho': 'phu_tho',
  'quang ngai': 'quang_ngai',
  'quang ninh': 'quang_ninh',
  'quang tri': 'quang_tri',
  'son la': 'son_la',
  'tay ninh': 'tay_ninh',
  'thai nguyen': 'thai_nguyen',
  'thanh hoa': 'thanh_hoa',
  'ho chi minh': 'thanh_pho_ho_chi_minh',
  'tp ho chi minh': 'thanh_pho_ho_chi_minh',
  'sai gon': 'thanh_pho_ho_chi_minh',
  'thanh pho ho chi minh': 'thanh_pho_ho_chi_minh',
  'tuyen quang': 'tuyen_quang',
  'vinh long': 'vinh_long',
};
