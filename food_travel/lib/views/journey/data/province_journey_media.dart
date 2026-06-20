const String _bannerBasePath = 'assets/provinces/journey/banners';
const String _avatarBasePath = 'assets/provinces/journey/avatars';

const Map<String, String> provinceJourneyBannerAssets = {
  'an_giang': '$_bannerBasePath/an_giang_banner.png',
  'bac_ninh': '$_bannerBasePath/bac_ninh_banner.png',
  'can_tho': '$_bannerBasePath/can_tho_banner.png',
  'cao_bang': '$_bannerBasePath/cao_bang_banner.png',
  'ca_mau': '$_bannerBasePath/ca_mau_banner.png',
  'da_nang': '$_bannerBasePath/da_nang_banner.png',
  'dak_lak': '$_bannerBasePath/dak_lak_banner.png',
  'dien_bien': '$_bannerBasePath/dien_bien_banner.png',
  'dong_nai': '$_bannerBasePath/dong_nai_banner.png',
  'dong_thap': '$_bannerBasePath/dong_thap_banner.png',
  'gia_lai': '$_bannerBasePath/gia_lai_banner.png',
  'ha_noi': '$_bannerBasePath/ha_noi_banner.png',
  'ha_tinh': '$_bannerBasePath/ha_tinh_banner.png',
  'hai_phong': '$_bannerBasePath/hai_phong_banner.png',
  'hung_yen': '$_bannerBasePath/hung_yen_banner.png',
  'hue': '$_bannerBasePath/hue_avatar.png',
  'khanh_hoa': '$_bannerBasePath/khanh_hoa_banner.png',
  'lai_chau': '$_bannerBasePath/lai_chau_banner.png',
  'lam_dong': '$_bannerBasePath/lam_dong_banner.png',
  'lang_son': '$_bannerBasePath/lang_son_banner.png',
  'lao_cai': '$_bannerBasePath/lao_cai_banner.png',
  'nghe_an': '$_bannerBasePath/nghe_an_banner.png',
  'ninh_binh': '$_bannerBasePath/ninh_binh_banner.png',
  'phu_tho': '$_bannerBasePath/phu_tho_banner.png',
  'quang_ngai': '$_bannerBasePath/quang_ngai_banner.png',
  'quang_ninh': '$_bannerBasePath/quang_ninh_banner.png',
  'quang_tri': '$_bannerBasePath/quang_tri_banner.png',
  'son_la': '$_bannerBasePath/son_la_banner.png',
  'tay_ninh': '$_bannerBasePath/tay_ninh_banner.png',
  'thai_nguyen': '$_bannerBasePath/thai_nguyen_banner.png',
  'thanh_hoa': '$_bannerBasePath/thanh_hoa_banner.png',
  'thanh_pho_ho_chi_minh':
      '$_bannerBasePath/thanh_pho_ho_chi_minh_banner.png',
  'tuyen_quang': '$_bannerBasePath/tuyen_quang_banner.png',
  'vinh_long': '$_bannerBasePath/vinh_long_banner.png',
};

const Map<String, String> provinceJourneyAvatarAssets = {
  'an_giang': '$_avatarBasePath/an_giang_avatar.png',
  'bac_ninh': '$_avatarBasePath/bac_ninh_avatar.png',
  'can_tho': '$_avatarBasePath/can_tho_avatar.png',
  'cao_bang': '$_avatarBasePath/cao_bang_avatar.png',
  'ca_mau': '$_avatarBasePath/ca_mau_avatar.png',
  'da_nang': '$_avatarBasePath/da_nang_avatar.png',
  'dak_lak': '$_avatarBasePath/dak_lak_avatar.png',
  'dien_bien': '$_avatarBasePath/dien_bien_avatar.png',
  'dong_nai': '$_avatarBasePath/dong_nai_avatar.png',
  'dong_thap': '$_avatarBasePath/dong_thap_avatar.png',
  'gia_lai': '$_avatarBasePath/gia_lai_avatar.png',
  'ha_noi': '$_avatarBasePath/ha_noi_avatar.png',
  'ha_tinh': '$_avatarBasePath/ha_tinh_avatar.png',
  'hai_phong': '$_avatarBasePath/hai_phong_avatar.png',
  'hung_yen': '$_avatarBasePath/hung_yen_avatar.png',
  'hue': '$_avatarBasePath/hue_avatar.png',
  'khanh_hoa': '$_avatarBasePath/khanh_hoa_avatar.png',
  'lai_chau': '$_avatarBasePath/lai_chau_avatar.png',
  'lam_dong': '$_avatarBasePath/lam_dong_avatar.png',
  'lang_son': '$_avatarBasePath/lang_son_avatar.png',
  'lao_cai': '$_avatarBasePath/lao_cai_avatar.png',
  'nghe_an': '$_avatarBasePath/nghe_an_avatar.png',
  'ninh_binh': '$_avatarBasePath/ninh_binh_avatar.png',
  'phu_tho': '$_avatarBasePath/phu_tho_avatar.png',
  'quang_ngai': '$_avatarBasePath/quang_ngai_avatar.png',
  'quang_ninh': '$_avatarBasePath/quang_ninh_avatar.png',
  'quang_tri': '$_avatarBasePath/quang_tri_avatar.png',
  'son_la': '$_avatarBasePath/son_la_avatar.png',
  'tay_ninh': '$_avatarBasePath/tay_ninh_avatar.png',
  'thai_nguyen': '$_avatarBasePath/thai_nguyen_avatar.png',
  'thanh_hoa': '$_avatarBasePath/thanh_hoa_avatar.png',
  'thanh_pho_ho_chi_minh':
      '$_avatarBasePath/thanh_pho_ho_chi_minh_avatar.png',
  'tuyen_quang': '$_avatarBasePath/tuyen_quang_avatar.png',
  'vinh_long': '$_avatarBasePath/vinh_long_avatar.png',
};

String? provinceJourneyBannerAssetOf(String provinceCode) {
  return provinceJourneyBannerAssets[provinceCode.trim().toLowerCase()];
}

String? provinceJourneyAvatarAssetOf(String provinceCode) {
  return provinceJourneyAvatarAssets[provinceCode.trim().toLowerCase()];
}
