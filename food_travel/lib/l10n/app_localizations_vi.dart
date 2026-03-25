// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'FoodG Travel';

  @override
  String get language => 'Ngon ngu';

  @override
  String get chooseLanguage => 'Chon ngon ngu';

  @override
  String get vietnamese => 'Tieng Viet';

  @override
  String get english => 'Tieng Anh';

  @override
  String get save => 'Luu';

  @override
  String get personalMembership => 'Bai viet';

  @override
  String get personalStore => 'Cua hang';

  @override
  String get personalHome => 'To am';

  @override
  String get personalGuests => 'Khach';

  @override
  String get personalStatus => 'Trang thai cua toi';

  @override
  String get personalChangePassword => 'Thay doi mat khau';

  @override
  String get personalLanguage => 'Da ngon ngu';

  @override
  String get personalFreeWithdraw => 'Rut mien phi';

  @override
  String get signInToViewProfile => 'Vui long dang nhap de xem trang ca nhan.';

  @override
  String get personalSurvey => 'Phieu khao sat';

  @override
  String get surveyTitle => 'Phieu khao sat';

  @override
  String get surveyProvinceLabel => 'Tinh/Thanh pho';

  @override
  String get surveyProvinceRequired => 'Vui long nhap tinh/thanh';

  @override
  String get surveySpicyLevel => 'Muc do cay';

  @override
  String get surveyFavoritesLabel => 'Mon yeu thich (phan tach bang dau phay)';

  @override
  String get surveyDislikesLabel =>
      'Nguyen lieu khong thich (phan tach bang dau phay)';

  @override
  String get surveySaveFailed => 'Luu that bai';

  @override
  String get notificationsTitle => 'Thong bao';

  @override
  String get notificationsMarkAllRead => 'Doc het';

  @override
  String get notificationsEmpty => 'Chua co thong bao nao.';

  @override
  String get notificationsLoadError => 'Khong the tai thong bao.';

  @override
  String get notificationsSignInRequired =>
      'Vui long dang nhap de xem thong bao.';

  @override
  String get notificationsSummaryNone => 'Ban da xem het thong bao.';

  @override
  String notificationsSummaryUnread(Object count) {
    return 'Ban co $count thong bao chua doc.';
  }

  @override
  String get notificationsTodayLabel => 'Hom nay';

  @override
  String get notificationTypeLike => 'Thich';

  @override
  String get notificationTypeComment => 'Binh luan';

  @override
  String notificationLikeTitle(Object name) {
    return '$name da thich bai viet cua ban';
  }

  @override
  String notificationCommentTitle(Object name) {
    return '$name da binh luan bai viet cua ban';
  }

  @override
  String get notificationMissingPost => 'Khong tim thay bai viet.';

  @override
  String get postDetailTitle => 'Bai viet';

  @override
  String get postDetailLoadError => 'Khong the tai bai viet.';

  @override
  String get postDetailNotFound => 'Bai viet khong con ton tai.';

  @override
  String get actionLike => 'Thich';

  @override
  String get actionComment => 'Binh luan';

  @override
  String get commonUserFallback => 'FoodG User';

  @override
  String get timeJustNow => 'vua xong';

  @override
  String timeMinutesAgo(Object count) {
    return '$count phut truoc';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count gio truoc';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count ngay truoc';
  }

  @override
  String timeOnDate(Object date) {
    return '$date';
  }

  @override
  String get homeProvinceUnknown => 'Ban o dau?';

  @override
  String get homeLocationLabel => 'Dang o';

  @override
  String get homeLocationPrompt => 'Ban dang o dau?';

  @override
  String get homeProvincePickerTitle => 'Chon tinh thanh';

  @override
  String get homeProvincePickerSearchHint =>
      'Tim tinh... (VD: Ha Noi, DN, ...)';

  @override
  String get homeProvinceNotFound => 'Khong tim thay tinh phu hop.';

  @override
  String get homeProvinceSelected => 'Dang chon';

  @override
  String homeMonthlyDestinationTitle(Object month) {
    return 'Diem den thang $month';
  }

  @override
  String get homeTodaySuggestionError => 'Khong the tai mon goi y hom nay.';

  @override
  String get homeProvinceLoadError => 'Khong the tai danh sach tinh.';

  @override
  String get homeProvinceEmpty => 'Chua co tinh thanh.';

  @override
  String get homeProvinceNoImage => 'Tinh nay chua co anh.';

  @override
  String get homeSearchHint => 'Tim mon an, nguyen lieu...';

  @override
  String get homeSelectProvinceToSeeDishes => 'Chon tinh de xem mon an.';

  @override
  String get homeDishListLoadError => 'Khong the tai danh sach mon.';

  @override
  String get homeDishNotFound => 'Khong tim thay mon an phu hop.';

  @override
  String get homeSpecialtiesTitle => 'Dac san phai thu';

  @override
  String get homeSpecialtiesCollapse => 'Thu gon';

  @override
  String get homeSpecialtiesSeeAll => 'Xem tat ca';

  @override
  String get homeNearbyQuery => 'quan an';

  @override
  String get homeNearbyTitle => 'Quan ngon gan ban';

  @override
  String get homeNearbyViewMap => 'Xem ban do >>';

  @override
  String get homeNearbyEnableLocation => 'Hay bat vi tri de xem quan gan ban.';

  @override
  String get homeNearbyLoadError => 'Khong tai duoc du lieu.';

  @override
  String get homeNearbyEmpty => 'Chua tim thay quan phu hop.';

  @override
  String get homeOpenNow => 'Dang mo';

  @override
  String get homeClosed => 'Dang dong';

  @override
  String get homeTodayEatTitle => 'Hom nay an gi?';

  @override
  String get homeTodayRefresh => 'Doi goi y';

  @override
  String get homeDishFallback => 'Mon';

  @override
  String get navHome => 'Trang chu';

  @override
  String get navExplore => 'Kham pha';

  @override
  String get navMap => 'Ban do';

  @override
  String get navSaved => 'Luu';

  @override
  String get navProfile => 'Toi';

  @override
  String get commonCancel => 'Huy';

  @override
  String get commonConfirm => 'Xac nhan';

  @override
  String get commonDelete => 'Xoa';

  @override
  String get commonEdit => 'Sua';

  @override
  String get commonSeeMore => 'Xem them';

  @override
  String get commonCollapse => 'Thu gon';

  @override
  String get commonSend => 'Gui';

  @override
  String get commonNo => 'Khong';

  @override
  String get commonClose => 'Dong';

  @override
  String get commonUpdating => 'Dang cap nhat';

  @override
  String get noticeSuccessTitle => 'Thanh cong';

  @override
  String get noticePostCreated => 'Dang bai viet thanh cong.';

  @override
  String get noticePostUpdated => 'Chinh sua bai viet thanh cong.';

  @override
  String get noticePostDeleted => 'Da xoa bai viet.';

  @override
  String get commentTitle => 'Binh luan';

  @override
  String get commentEmpty => 'Chua co binh luan nao.';

  @override
  String get commentLoginRequired => 'Vui long dang nhap de binh luan.';

  @override
  String get commentHint => 'Viet binh luan...';

  @override
  String get communityTitle => 'Cong dong';

  @override
  String get communityTabNewest => 'Moi nhat';

  @override
  String get communityTabTrending => 'Noi bat';

  @override
  String get communityTabNear => 'Gan ban';

  @override
  String get communityTabProvince => 'Theo tinh';

  @override
  String get communityPostButton => 'Tao bai viet';

  @override
  String get communityLoadError => 'Khong the tai bai viet.';

  @override
  String get communityEmptyNewest => 'Chua co bai viet nao.';

  @override
  String get communityEmptyTrending => 'Chua co bai viet noi bat.';

  @override
  String get communityEnableGps => 'Hay bat GPS de xem bai viet gan ban.';

  @override
  String get communityGpsLoading => 'Dang lay vi tri...';

  @override
  String get communityEnableGpsButton => 'Bat GPS';

  @override
  String get communityEmptyNear => 'Chua tim thay bai viet gan ban.';

  @override
  String get communitySelectProvince => 'Chon tinh thanh';

  @override
  String get communityChangeProvince => 'Doi';

  @override
  String get communitySelectProvinceHint => 'Tim tinh...';

  @override
  String get communityEmptyProvince => 'Chua co bai viet cho tinh nay.';

  @override
  String get communityProvinceListEmpty => 'Chua co danh sach tinh.';

  @override
  String get communityDeleteTitle => 'Xoa bai viet';

  @override
  String get communityDeleteConfirm => 'Ban chac chan muon xoa bai viet nay?';

  @override
  String get communityMyPostsTitle => 'Bai viet cua toi';

  @override
  String get communityMyPostsLoginRequired =>
      'Vui long dang nhap de xem bai viet cua ban.';

  @override
  String get communityMyPostsLoadError => 'Khong the tai bai viet cua ban.';

  @override
  String get communityMyPostsEmpty => 'Ban chua dang bai viet nao.';

  @override
  String get communityPostEmptyContent => 'Noi dung bai viet dang trong.';

  @override
  String get postPickFromGallery => 'Chon tu thu vien';

  @override
  String get postPickFromCamera => 'Chup anh';

  @override
  String get postCreateTitle => 'Tao bai viet';

  @override
  String get postEditTitle => 'Sua bai viet';

  @override
  String get postPublish => 'Dang';

  @override
  String get postTextHint => 'Chia se trai nghiem cua ban...';

  @override
  String get postUploading => 'Dang tai...';

  @override
  String get postAddPlace => 'Them dia diem';

  @override
  String get postPlaceSearchHint => 'Tim dia diem...';

  @override
  String get postPlaceSearchPrompt => 'Nhap ten de tim kiem.';

  @override
  String get postPlaceSearchEmpty => 'Khong tim thay dia diem.';

  @override
  String get postPlaceSearchError => 'Tim kiem that bai. Thu lai.';

  @override
  String get postPlaceFallbackTitle => 'Dia diem gan day';

  @override
  String get postPlaceFallbackAddress => 'Dia chi dang cap nhat';

  @override
  String postSubmitFailed(Object error) {
    return 'Dang bai that bai: $error';
  }

  @override
  String reviewSectionTitle(Object count) {
    return 'Danh gia ($count)';
  }

  @override
  String get reviewWriteTitle => 'Viet danh gia';

  @override
  String get reviewEmpty => 'Chua co bai danh gia.';

  @override
  String get reviewDeleteTitle => 'Xoa danh gia';

  @override
  String get reviewDeleteConfirm => 'Ban chac chan muon xoa danh gia nay?';

  @override
  String get reviewDinedHere => 'Da an o quan nay';

  @override
  String reviewDinedHereWithDate(Object date) {
    return '$date - Da an o quan nay';
  }

  @override
  String reviewFromUserWithDate(Object date) {
    return '$date - Danh gia tu nguoi dung';
  }

  @override
  String get favoritesLoginRequired => 'Vui long dang nhap de xem muc da luu.';

  @override
  String get favoritesTitle => 'Luu';

  @override
  String get favoritesSubtitle => 'Tat ca muc da luu';

  @override
  String get favoritesTabDishes => 'Mon an';

  @override
  String get favoritesTabPlaces => 'Quan an';

  @override
  String get favoritesFilterCentral => 'Mien Trung';

  @override
  String get favoritesFilterSpicy => 'Cay';

  @override
  String get favoritesFilterBudget => 'Gia re';

  @override
  String get favoritesFilterBreakfast => 'Bua sang';

  @override
  String get favoritesLoadError => 'Khong the tai danh sach yeu thich.';

  @override
  String get favoritePlacesLoadError => 'Khong the tai danh sach quan da luu.';

  @override
  String get favoritePlacesEmpty => 'Chua co quan da luu.';

  @override
  String get favoritePlaceCategoryFallback => 'Am thuc dia phuong';

  @override
  String get favoritePlaceNoRating => 'Chua co danh gia';

  @override
  String get favoritePlaceAddressFallback => 'Dia chi dang cap nhat';

  @override
  String get favoriteDishesLoadError => 'Khong the tai danh sach mon da luu.';

  @override
  String get favoriteDishesEmpty => 'Chua co mon da luu.';

  @override
  String get favoriteSpicyNone => 'Khong cay';

  @override
  String favoriteSpicyLevel(Object count) {
    return 'Do cay $count';
  }

  @override
  String get favoriteProvinceUpdating => 'Dang cap nhat tinh...';

  @override
  String get regionNorth => 'Mien Bac';

  @override
  String get regionCentral => 'Mien Trung';

  @override
  String get regionSouth => 'Mien Nam';

  @override
  String get placeNameFallback => 'Quan';

  @override
  String get placeAddressUpdating => 'Dia chi dang cap nhat';

  @override
  String get placeNoPhone => 'Chua co so dien thoai';

  @override
  String get placeCallNow => 'Goi ngay';

  @override
  String get placeCallAction => 'Goi';

  @override
  String get placeReserve => 'Dat ban';

  @override
  String get placeInvite => 'Moi ban';

  @override
  String get placeSchedule => 'Len lich';

  @override
  String get placePricePerPerson => '/nguoi';

  @override
  String get placeDistanceUpdating => 'Khoang cach dang cap nhat';

  @override
  String placeDistanceAway(Object distance) {
    return 'Cach day $distance';
  }

  @override
  String get placeOpenHoursUpdating => 'Dang cap nhat gio mo cua';

  @override
  String placeClosesAt(Object time) {
    return 'Dong luc $time';
  }

  @override
  String get placeCategoryFallback => 'Am thuc dia phuong';

  @override
  String get placeNoRating => 'Chua co danh gia';

  @override
  String get placeMenuMustTry => 'Mon nen thu';

  @override
  String get placeMenuFull => 'Menu day du';

  @override
  String get placeMenuUpdating => 'Dang cap nhat mon nen thu.';

  @override
  String get placeInfoTitle => 'Thong tin quan';

  @override
  String get placeOpenHoursLabel => 'Gio mo cua';

  @override
  String get amenityAirConditioner => 'May lanh';

  @override
  String get amenityBankTransfer => 'Chuyen khoan';

  @override
  String get amenityFreeParking => 'Do xe mien phi';

  @override
  String get mapSearchHint => 'Tim dia diem...';

  @override
  String get mapCategoryRestaurants => 'Quan an';

  @override
  String get mapCategoryCafe => 'Cafe';

  @override
  String get mapCategorySnack => 'An vat';

  @override
  String get mapCategoryFastFood => 'Do an nhanh';

  @override
  String get mapCategorySeafood => 'Hai san';

  @override
  String get mapStyleNormal => 'Thuong';

  @override
  String get mapStyleHighlight => 'Noi bat';

  @override
  String get mapStyleSatellite => 'Ve tinh';

  @override
  String get mapEnableLocation => 'Vui long bat vi tri.';

  @override
  String get mapLocationUnavailable => 'Chua co vi tri.';

  @override
  String get mapPlaceNotFound => 'Khong tim thay dia diem.';

  @override
  String get mapEnableGpsToSearch => 'Hay bat GPS de tim quan.';

  @override
  String get mapPermissionDenied => 'Chua co quyen vi tri.';

  @override
  String get mapGpsInvalid => 'Vi tri GPS khong hop le.';

  @override
  String get mapNearbyNotFound => 'Khong tim thay quan gan day.';

  @override
  String get mapLocationTimeout => 'Qua thoi gian lay vi tri.';

  @override
  String mapSearchError(Object error) {
    return 'Loi tim kiem: $error';
  }

  @override
  String get mapDirectionsError => 'Khong lay duoc chi duong.';

  @override
  String get mapOpenNow => 'Dang mo';

  @override
  String get mapClosed => 'Dang dong';

  @override
  String get mapDirections => 'Chi duong';

  @override
  String mapNearbyPlacesTitle(Object count) {
    return 'Quan gan day ($count)';
  }

  @override
  String mapEtaMinutes(Object minutes) {
    return '~$minutes phut';
  }

  @override
  String get mapSortDistance => 'Khoang cach';

  @override
  String get mapOpenMap => 'Mo ban do';

  @override
  String get mapNoCoordinates => 'Khong co toa do';

  @override
  String get mapPlaceFallbackName => 'Quan gan day';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nu';

  @override
  String get genderOther => 'Khac';

  @override
  String get genderUnknown => 'Khong xac dinh';

  @override
  String get profileEditTitle => 'Chinh sua thong tin';

  @override
  String get profileNameLabel => 'Ho ten';

  @override
  String get profileNameRequired => 'Vui long nhap ten';

  @override
  String get profileGenderLabel => 'Gioi tinh';

  @override
  String get profileGenderHint => 'Chon gioi tinh';

  @override
  String get profileDobLabel => 'Ngay sinh';

  @override
  String get profilePhoneLabel => 'So dien thoai';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileAvatarTitle => 'Hinh dai dien';

  @override
  String get profileAvatarUploadFailed => 'Tai anh that bai';

  @override
  String get personalLocation => 'Vi tri';

  @override
  String get logoutTitle => 'Dang xuat';

  @override
  String get logoutConfirm => 'Ban co chac muon dang xuat khong?';

  @override
  String get logoutAction => 'Dang xuat';

  @override
  String get themeSettingsTitle => 'Giao dien';

  @override
  String get themeLight => 'Sang';

  @override
  String get themeDark => 'Toi';

  @override
  String get themeSystem => 'Tu dong';

  @override
  String get locationSettingsTitle => 'Vi tri';

  @override
  String get locationSettingsDescription =>
      'Bat/tat vi tri de hien thi tren ban do.';

  @override
  String get locationEnable => 'Bat vi tri';

  @override
  String get locationOpenSettings => 'Mo cai dat GPS';

  @override
  String get locationOpenAppSettings => 'Mo cai dat ung dung';

  @override
  String get locationError => 'Loi vi tri.';

  @override
  String get changePasswordTitle => 'Doi mat khau';

  @override
  String get changePasswordSuccess => 'Doi mat khau thanh cong.';

  @override
  String get changePasswordCurrentLabel => 'Mat khau hien tai';

  @override
  String get changePasswordNewLabel => 'Mat khau moi';

  @override
  String get changePasswordConfirmLabel => 'Nhap lai mat khau moi';

  @override
  String get changePasswordCurrentRequired => 'Vui long nhap mat khau hien tai';

  @override
  String get changePasswordNewRequired => 'Vui long nhap mat khau moi';

  @override
  String get changePasswordNewTooShort => 'Mat khau moi it nhat 6 ky tu';

  @override
  String get changePasswordConfirmRequired => 'Vui long nhap lai mat khau moi';

  @override
  String get changePasswordMismatch => 'Mat khau moi khong trung khop';

  @override
  String get changePasswordErrorMissingFields =>
      'Vui long nhap day du thong tin.';

  @override
  String get changePasswordErrorMismatch => 'Mat khau moi khong trung khop.';

  @override
  String get changePasswordErrorTooShort => 'Mat khau moi it nhat 6 ky tu.';

  @override
  String get changePasswordErrorWrongCurrent => 'Mat khau hien tai khong dung.';

  @override
  String get changePasswordErrorWeak => 'Mat khau moi qua yeu.';

  @override
  String get changePasswordErrorRequiresLogin =>
      'Vui long dang nhap lai roi thu lai.';

  @override
  String get changePasswordErrorNoUser => 'Chua dang nhap.';

  @override
  String get changePasswordErrorNoPasswordProvider =>
      'Tai khoan dang nhap bang Google, khong doi duoc mat khau.';

  @override
  String get changePasswordErrorUnknown => 'Doi mat khau that bai.';

  @override
  String get authLoginTitle => 'Chao mung tro lai!';

  @override
  String get authLoginSubtitle => 'Dang nhap tai khoan mon an';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Vui long nhap email';

  @override
  String get authEmailInvalid => 'Email khong hop le';

  @override
  String get authPasswordLabel => 'Mat khau';

  @override
  String get authPasswordRequired => 'Vui long nhap mat khau';

  @override
  String get authLoginAction => 'Dang nhap';

  @override
  String get authOr => 'hoac';

  @override
  String get authContinueGoogle => 'Tiep tuc voi Google';

  @override
  String get authNoAccount => 'Chua co tai khoan? ';

  @override
  String get authRegisterAction => 'Dang ky';

  @override
  String get authLoginFailed => 'Dang nhap that bai';

  @override
  String get authLoginUserNotFound => 'Tai khoan khong ton tai';

  @override
  String get authLoginWrongPassword => 'Mat khau khong dung';

  @override
  String get authGoogleFailed => 'Dang nhap Google that bai';

  @override
  String get authGoogleAccountExists =>
      'Tai khoan da ton tai voi cach dang nhap khac';

  @override
  String get authGoogleInvalidCredential => 'Thong tin Google khong hop le';

  @override
  String authError(Object error) {
    return 'Loi: $error';
  }

  @override
  String get authRegisterTitle => 'Tao tai khoan';

  @override
  String get authRegisterSubtitle =>
      'Tham gia va kham pha quan ngon quanh ban.';

  @override
  String get authFullNameLabel => 'Ho ten';

  @override
  String get authFullNameRequired => 'Vui long nhap ho ten';

  @override
  String get authPhoneOptionalLabel => 'So dien thoai (tuy chon)';

  @override
  String get authConfirmPasswordLabel => 'Nhap lai mat khau';

  @override
  String get authConfirmPasswordRequired => 'Vui long nhap lai mat khau';

  @override
  String get authPasswordTooShort => 'Mat khau toi thieu 6 ky tu';

  @override
  String get authPasswordMismatch => 'Mat khau khong trung khop';

  @override
  String get authPasswordTooWeak => 'Mat khau qua yeu (toi thieu 6 ky tu)';

  @override
  String get authRegisterSuccess => 'Dang ky thanh cong';

  @override
  String get authRegisterFailed => 'Dang ky that bai';

  @override
  String get authRegisterEmailInUse => 'Email da duoc su dung';

  @override
  String get authRegisterUserMissing => 'Khong lay duoc tai khoan vua tao';

  @override
  String get provinceLoadError => 'Khong the tai tinh thanh.';

  @override
  String get provinceNotFound => 'Khong tim thay tinh.';

  @override
  String get provinceIntroTitle => 'Gioi thieu';

  @override
  String get provinceNoDescription => 'Chua co mo ta.';

  @override
  String get provinceSpecialtiesTitle => 'Dac san tieu bieu';

  @override
  String get provinceDishesLoadError => 'Khong the tai mon an.';

  @override
  String get provinceNoDishes => 'Chua co mon an cho tinh nay.';

  @override
  String get dishNotFound => 'Khong tim thay mon an.';

  @override
  String get dishLoginToSave => 'Vui long dang nhap de luu.';

  @override
  String get dishShareTodo => 'Chia se sap co.';

  @override
  String get routeMissingProvinceId => 'Thieu id tinh';

  @override
  String get routeMissingDishId => 'Thieu id mon an';

  @override
  String get routeNotFound => 'Khong tim thay duong dan';

  @override
  String get commonBack => 'Quay lai';

  @override
  String get reviewAlreadyTitle => 'Ban da danh gia';

  @override
  String get reviewAlreadyMessage =>
      'Ban da danh gia dia diem nay. Sua danh gia?';

  @override
  String get reviewEditConfirm => 'Sua danh gia';

  @override
  String get reviewHint => 'Chia se cam nhan cua ban...';
}
