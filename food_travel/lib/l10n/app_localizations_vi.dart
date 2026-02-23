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
}
