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
  String get language => 'Ngôn ngữ';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageAppSection => 'Ngôn ngữ ứng dụng';

  @override
  String get languageDefault => 'Ngôn ngữ mặc định';

  @override
  String get languageEnglishSubtitle => 'Tiếng Anh';

  @override
  String get languageInfo =>
      'Thay đổi ngôn ngữ sẽ áp dụng cho toàn bộ ứng dụng FoodS.';

  @override
  String get languageSupportedNote => 'Chỉ hỗ trợ Tiếng Việt và Tiếng Anh.';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get save => 'Lưu';

  @override
  String get personalMembership => 'Bài viết';

  @override
  String get personalStore => 'Cửa hàng';

  @override
  String get personalHome => 'Ưa thích';

  @override
  String get personalGuests => 'Khách';

  @override
  String get personalStatus => 'Trạng thái của tôi';

  @override
  String get personalChangePassword => 'Thay đổi mật khẩu';

  @override
  String get personalLanguage => 'Đa ngôn ngữ';

  @override
  String get personalFreeWithdraw => 'Rút miễn phí';

  @override
  String get signInToViewProfile => 'Vui lòng đăng nhập để xem trang cá nhân.';

  @override
  String get personalSurvey => 'Phiếu khảo sát';

  @override
  String get surveyTitle => 'Phiếu khảo sát';

  @override
  String get surveyProvinceLabel => 'Tỉnh/Thành phố';

  @override
  String get surveyProvinceRequired => 'Vui lòng nhập tỉnh/thành';

  @override
  String get surveySpicyLevel => 'Mức độ cay';

  @override
  String get surveyFavoritesLabel => 'Món yêu thích (phân tách bằng dấu phẩy)';

  @override
  String get surveyDislikesLabel =>
      'Nguyên liệu không thích (phân tách bằng dấu phẩy)';

  @override
  String get surveySaveFailed => 'Lưu thất bại';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsMarkAllRead => 'Đọc hết';

  @override
  String get notificationsEmpty => 'Chưa có thông báo nào.';

  @override
  String get notificationsLoadError => 'Không thể tải thông báo.';

  @override
  String get notificationsSignInRequired =>
      'Vui lòng đăng nhập để xem thông báo.';

  @override
  String get notificationsSummaryNone => 'Bạn đã xem hết thông báo.';

  @override
  String notificationsSummaryUnread(Object count) {
    return 'Bạn có $count thông báo chưa đọc.';
  }

  @override
  String get notificationsTodayLabel => 'Hôm nay';

  @override
  String get notificationTypeLike => 'Thích';

  @override
  String get notificationTypeComment => 'Bình luận';

  @override
  String notificationLikeTitle(Object name) {
    return '$name đã thích bài viết của bạn';
  }

  @override
  String notificationCommentTitle(Object name) {
    return '$name đã bình luận bài viết của bạn';
  }

  @override
  String get notificationMissingPost => 'Không tìm thấy bài viết.';

  @override
  String get postDetailTitle => 'Bài viết';

  @override
  String get postDetailLoadError => 'Không thể tải bài viết.';

  @override
  String get postDetailNotFound => 'Bài viết không còn tồn tại.';

  @override
  String get actionLike => 'Thích';

  @override
  String get actionComment => 'Bình luận';

  @override
  String get commonUserFallback => 'FoodG User';

  @override
  String get timeJustNow => 'vừa xong';

  @override
  String timeMinutesAgo(Object count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count ngày trước';
  }

  @override
  String timeOnDate(Object date) {
    return '$date';
  }

  @override
  String get homeProvinceUnknown => 'Bạn ở đâu?';

  @override
  String get homeLocationLabel => 'Đang ở';

  @override
  String get homeLocationPrompt => 'Bạn đang ở đâu?';

  @override
  String get homeProvincePickerTitle => 'Chọn tỉnh thành';

  @override
  String get homeProvincePickerSearchHint =>
      'Tìm tỉnh... (VD: Hà Nội, ĐN, ...)';

  @override
  String get homeProvinceNotFound => 'Không tìm thấy tỉnh phù hợp.';

  @override
  String get homeProvinceSelected => 'Đang chọn';

  @override
  String homeMonthlyDestinationTitle(Object month) {
    return 'Điểm đến tháng $month';
  }

  @override
  String get homeTodaySuggestionError => 'Không thể tải món gợi ý hôm nay.';

  @override
  String get homeProvinceLoadError => 'Không thể tải danh sách tỉnh.';

  @override
  String get homeProvinceEmpty => 'Chưa có tỉnh thành.';

  @override
  String get homeProvinceNoImage => 'Tỉnh này chưa có ảnh.';

  @override
  String get homeSearchHint => 'Tìm món ăn, nguyên liệu...';

  @override
  String get homeSelectProvinceToSeeDishes => 'Chọn tỉnh để xem món ăn.';

  @override
  String get homeDishListLoadError => 'Không thể tải danh sách món.';

  @override
  String get homeDishNotFound => 'Không tìm thấy món ăn phù hợp.';

  @override
  String get homeSpecialtiesTitle => 'Đặc sản phải thử';

  @override
  String get homeSpecialtiesCollapse => 'Thu gọn';

  @override
  String get homeSpecialtiesSeeAll => 'Xem tất cả';

  @override
  String get homeNearbyQuery => 'quán ăn';

  @override
  String get homeNearbyTitle => 'Quán ngon gần bạn';

  @override
  String get homeNearbyViewMap => 'Xem bản đồ >>';

  @override
  String get homeNearbyEnableLocation => 'Hãy bật vị trí để xem quán gần bạn.';

  @override
  String get homeNearbyLoadError => 'Không tải được dữ liệu.';

  @override
  String get homeNearbyEmpty => 'Chưa tìm thấy quán phù hợp.';

  @override
  String get homeCommunityEatingTitle => 'Cộng đồng đang ăn gì?';

  @override
  String get homeCommunityView => 'Xem cộng đồng';

  @override
  String get homeCommunityEatingFallback =>
      'Hôm nay cộng đồng đang chia sẻ quán này.';

  @override
  String get homeCommunitySharingFallback =>
      'Cộng đồng đang chia sẻ trải nghiệm ăn uống mới.';

  @override
  String get homeOpenNow => 'Đang mở';

  @override
  String get homeClosed => 'Đang đóng';

  @override
  String get homeTodayEatTitle => 'Hôm nay ăn gì?';

  @override
  String get homeTodayRefresh => 'Đổi gợi ý';

  @override
  String get homeDishFallback => 'Món';

  @override
  String get homeQuickNearby => 'Gần tôi';

  @override
  String get homeQuickCheckIn => 'Check-in';

  @override
  String get homeQuickSavedPlaces => 'Lưu quán';

  @override
  String get homeQuickMap => 'Bản đồ';

  @override
  String get homeNearbyMapQuery => 'Quán gần tôi';

  @override
  String get homeJourneyTitle => 'Hành trình ẩm thực';

  @override
  String homeJourneyExplorerLevel(int level) {
    return 'Explorer Lv.$level';
  }

  @override
  String homeJourneyTotalPoints(int points) {
    return '$points điểm';
  }

  @override
  String get homeJourneyStreakLabel => 'Chuỗi ngày';

  @override
  String homeJourneyStreakDays(int days) {
    return '$days ngày';
  }

  @override
  String get homeJourneyPointsLabel => 'Điểm';

  @override
  String homeJourneyNeedPoints(int points, int level) {
    return 'Cần $points điểm để lên Lv.$level';
  }

  @override
  String get commonViewAll => 'Xem tất cả';

  @override
  String get journeySubtitle => 'Khám phá Việt Nam qua từng món ăn';

  @override
  String get journeyExplorer => 'Nhà khám phá';

  @override
  String get journeyConsecutiveDays => 'ngày liên tiếp';

  @override
  String get journeyBadgesTitle => 'Huy hiệu của bạn';

  @override
  String get journeyUnlocked => 'Đã mở khóa';

  @override
  String get journeyCompleted => 'Hoàn thành';

  @override
  String journeyCurrentProgress(String progress) {
    return 'Tiến độ hiện tại: $progress';
  }

  @override
  String get journeyDailyMissionsTitle => 'Nhiệm vụ hôm nay';

  @override
  String journeyRewardPoints(int points) {
    return '+$points điểm';
  }

  @override
  String get journeyMissionDetailTitle => 'Chi tiết nhiệm vụ';

  @override
  String get journeyProgressTitle => 'Tiến độ';

  @override
  String get journeyRewardTitle => 'Phần thưởng';

  @override
  String get journeyTimeRemainingTitle => 'Thời gian còn lại';

  @override
  String get timeHoursShort => 'giờ';

  @override
  String get timeMinutesShort => 'phút';

  @override
  String get timeSecondsShort => 'giây';

  @override
  String get journeyActionExploreNow => 'Đi khám phá ngay';

  @override
  String get journeyActionFindPlaceToSave => 'Tìm quán để lưu';

  @override
  String get journeyActionFindVietnameseDish => 'Tìm món Việt ngay';

  @override
  String get journeyActionStartMission => 'Bắt đầu nhiệm vụ';

  @override
  String get journeyMissionCheckinNewPlaceTitle => 'Check-in 1 quán mới';

  @override
  String get journeyMissionCheckinNewPlaceDescription =>
      'Hãy check-in tại một quán bạn chưa từng ăn.';

  @override
  String get journeyMissionTryVietnameseFoodTitle => 'Thử một món Việt';

  @override
  String get journeyMissionTryVietnameseFoodDescription =>
      'Khám phá một món ăn Việt Nam hôm nay.';

  @override
  String get journeyMissionSaveWishlistPlaceTitle => 'Lưu 1 quán muốn ăn';

  @override
  String get journeyMissionSaveWishlistPlaceDescription =>
      'Lưu một quán vào danh sách yêu thích.';

  @override
  String get journeyMissionHighRatingPlaceTitle =>
      'Check-in quán được đánh giá cao';

  @override
  String get journeyMissionHighRatingPlaceDescription =>
      'Ghé một quán có đánh giá tốt để tích thêm điểm.';

  @override
  String get journeyMissionUnlockProvinceTitle => 'Mở khóa thêm một tỉnh thành';

  @override
  String get journeyMissionUnlockProvinceDescription =>
      'Check-in ở tỉnh mới để mở rộng bản đồ hành trình.';

  @override
  String get journeyProvinceListTitle => 'Danh sách tỉnh thành';

  @override
  String journeyDiscoveredProvinceCount(int discovered, int total) {
    return 'Đã khám phá $discovered/$total tỉnh thành.';
  }

  @override
  String journeyCheckinCount(int count) {
    return '$count check-in';
  }

  @override
  String get journeyNotDiscovered => 'Chưa khám phá';

  @override
  String get journeySignedOutTitle => 'Chưa có người dùng';

  @override
  String get journeySignedOutMessage =>
      'Đăng nhập để theo dõi hành trình ẩm thực của bạn trên bản đồ.';

  @override
  String get journeyDiscovered => 'Đã khám phá';

  @override
  String get journeyMapTitle => 'Bản đồ khám phá Việt Nam';

  @override
  String get journeyProvinceUnit => 'tỉnh thành';

  @override
  String get journeyMapLoadErrorTitle => 'Không tải được bản đồ';

  @override
  String get journeyMapAssetLoadError =>
      'Asset GeoJSON hiện tại không đọc được. Kiểm tra lại file bản đồ.';

  @override
  String journeyMapGeoJsonLoadError(String details) {
    return 'Không đọc được GeoJSON: $details';
  }

  @override
  String get journeyFeaturedDishesTitle => 'Món nổi bật';

  @override
  String get journeyVisitedPlacesTitle => 'Quán đã ăn';

  @override
  String journeyFindNewPlaceInProvince(String province) {
    return 'Tìm quán mới tại $province';
  }

  @override
  String get journeyViewCheckinHistory => 'Xem lịch sử check-in';

  @override
  String journeyProvinceCheckinSubtitle(int count) {
    return 'Bạn đã có $count lượt check-in tại tỉnh thành này';
  }

  @override
  String get journeyProvinceEmptySubtitle =>
      'Khám phá hành trình ẩm thực và những quán bạn đã ghé qua';

  @override
  String get journeyCheckinStatLabel => 'lượt check-in';

  @override
  String get journeyVisitedPlaceStatLabel => 'quán đã ăn';

  @override
  String get journeyVisitedDistrictStatLabel => 'quận đã đi qua';

  @override
  String get journeyFeaturedDishesEmpty =>
      'Chưa có dữ liệu món nổi bật cho tỉnh thành này.';

  @override
  String journeyVisitCount(int count) {
    return '$count lần';
  }

  @override
  String get journeyVisitedPlacesEmptyTitle => 'Chưa có quán đã ăn';

  @override
  String journeyVisitedPlacesEmptyMessage(String province) {
    return 'Khi bạn check-in tại $province, các quán đã ghé sẽ hiển thị ở đây.';
  }

  @override
  String get journeyNoRating => 'Chưa có đánh giá';

  @override
  String get journeyUnknownDistance => 'Chưa xác định khoảng cách';

  @override
  String get homeMissionTodayTitle => 'Nhiệm vụ hôm nay';

  @override
  String get homeMissionSeeAll => 'Xem tất cả nhiệm vụ';

  @override
  String get homeMissionCheckinNewPlace => 'Check-in 1 quán mới';

  @override
  String get homeMissionTryVietnameseFood => 'Thử một món Việt';

  @override
  String get homeBadgesTitle => 'Huy hiệu của bạn';

  @override
  String get homeBadgesSeeAll => 'Xem tất cả';

  @override
  String provinceExploreTitle(Object province) {
    return 'Khám phá $province';
  }

  @override
  String provinceHeroSubtitle(Object region) {
    return 'Vùng đất ẩm thực đặc sắc • $region';
  }

  @override
  String get provinceDefaultRegion => 'Việt Nam';

  @override
  String provinceDishMetric(Object count) {
    return '$count món nổi bật';
  }

  @override
  String provinceLegacyMetric(Object count) {
    return '$count địa phương cũ';
  }

  @override
  String get provinceHeroBadge => 'Khám phá tỉnh thành';

  @override
  String get provinceOverviewTitle => 'Tổng quan tỉnh thành';

  @override
  String get provinceOverviewSubtitle =>
      'Điểm nhấn văn hóa, lịch sử và trải nghiệm ẩm thực.';

  @override
  String get provinceOverviewAction => 'Xem thông tin';

  @override
  String get provinceFoodAction => 'Xem món ăn';

  @override
  String get provinceDescriptionUpdating =>
      'Thông tin giới thiệu đang được cập nhật.';

  @override
  String get provinceFeaturedDishesTitle => 'Món ăn nổi bật';

  @override
  String provinceFeaturedDishesSubtitle(Object province) {
    return 'Các món ngon tiêu biểu của $province.';
  }

  @override
  String get provinceAllFilter => 'Tất cả';

  @override
  String get provinceDishLoadError => 'Không tải được danh sách món ăn.';

  @override
  String get provinceDishEmpty => 'Chưa có món ăn nào cho tỉnh này.';

  @override
  String provinceLegacyDishEmpty(Object province) {
    return 'Chưa có món ăn nào thuộc $province.';
  }

  @override
  String get provinceFamousPlacesTitle => 'Địa điểm nổi tiếng';

  @override
  String get provinceLegacySectionTitle => 'Dấu ấn địa phương';

  @override
  String get provinceLegacySectionSubtitle =>
      'Khám phá các tỉnh cũ đang tạo nên bản sắc của tỉnh/thành mới.';

  @override
  String get provinceLegacyActiveHint =>
      'Đang xem nội dung của địa phương này.';

  @override
  String get provinceLegacyInactiveHint => 'Nhấn để xem mô tả, ảnh và món ăn.';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navExplore => 'Khám phá';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navSaved => 'Lưu';

  @override
  String get navProfile => 'Tôi';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonSeeMore => 'Xem thêm';

  @override
  String get commonViewDetail => 'Xem chi tiết';

  @override
  String get commonCollapse => 'Thu gọn';

  @override
  String get commonSend => 'Gửi';

  @override
  String get commonNo => 'Không';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonUpdating => 'Đang cập nhật';

  @override
  String get noticeSuccessTitle => 'Thành công';

  @override
  String get noticePostCreated => 'Bài viết đã được gửi và đang chờ duyệt.';

  @override
  String get noticePostUpdated => 'Chỉnh sửa bài viết thành công.';

  @override
  String get noticePostDeleted => 'Đã xóa bài viết.';

  @override
  String get commentTitle => 'Bình luận';

  @override
  String get commentEmpty => 'Chưa có bình luận nào.';

  @override
  String get commentLoginRequired => 'Vui lòng đăng nhập để bình luận.';

  @override
  String get commentHint => 'Viết bình luận...';

  @override
  String get communityTitle => 'Cộng đồng';

  @override
  String get communitySubtitle => 'Chia sẻ hành trình ẩm thực của bạn';

  @override
  String get communityComposerHint => 'Bạn vừa ăn món gì ngon?';

  @override
  String get communityAddPhoto => 'Đăng ảnh';

  @override
  String get communityCheckInAction => 'Check-in';

  @override
  String get communityReviewAction => 'Review';

  @override
  String get communityTabAll => 'Tất cả';

  @override
  String get communityTabNewest => 'Mới nhất';

  @override
  String get communityTabTrending => 'Đang hot';

  @override
  String get communityTabNear => 'Gần bạn';

  @override
  String get communityTabProvince => 'Theo tỉnh';

  @override
  String get systemGuideTitle => 'Cẩm nang từ hệ thống';

  @override
  String get communityPostButton => 'Tạo bài viết';

  @override
  String get communityLoadError => 'Không thể tải bài viết.';

  @override
  String get communityEmptyNewest => 'Chưa có bài viết nào.';

  @override
  String get communityEmptyTrending => 'Chưa có bài viết nổi bật.';

  @override
  String get communityEnableGps => 'Hãy bật GPS để xem bài viết gần bạn.';

  @override
  String get communityGpsLoading => 'Đang lấy vị trí...';

  @override
  String get communityEnableGpsButton => 'Bật GPS';

  @override
  String get communityEmptyNear => 'Chưa tìm thấy bài viết gần bạn.';

  @override
  String get communitySelectProvince => 'Chọn tỉnh thành';

  @override
  String get communityChangeProvince => 'Đổi';

  @override
  String get communitySelectProvinceHint => 'Tìm tỉnh...';

  @override
  String get communityEmptyProvince => 'Chưa có bài viết cho tỉnh này.';

  @override
  String get communityProvinceListEmpty => 'Chưa có danh sách tỉnh.';

  @override
  String get communityDeleteTitle => 'Xóa bài viết';

  @override
  String get communityDeleteConfirm => 'Bạn chắc chắn muốn xóa bài viết này?';

  @override
  String get communityMyPostsTitle => 'Bài viết của tôi';

  @override
  String get communityMyPostsLoginRequired =>
      'Vui lòng đăng nhập để xem bài viết của bạn.';

  @override
  String get communityMyPostsLoadError => 'Không thể tải bài viết của bạn.';

  @override
  String get communityMyPostsEmpty => 'Bạn chưa đăng bài viết nào.';

  @override
  String get communityMyPostsNoMatches => 'Không có bài viết phù hợp';

  @override
  String get communityCreateNow => 'Tạo bài viết ngay';

  @override
  String get communityMyPostsOverview => 'Tổng quan bài viết';

  @override
  String get communityMyPostsTotal => 'Tổng bài viết';

  @override
  String get communityMyPostsSearchHint => 'Tìm bài viết của bạn...';

  @override
  String get communityStatusPublished => 'Đã xuất bản';

  @override
  String get communityStatusPending => 'Chờ duyệt';

  @override
  String get communityStatusHidden => 'Đã ẩn';

  @override
  String get communityStatusHiddenShort => 'Bị ẩn';

  @override
  String get communityStatusRejected => 'Từ chối';

  @override
  String get communityNewPostTitle => 'Bài viết mới';

  @override
  String get communityFoodExperienceSubtitle => 'Chia sẻ trải nghiệm ẩm thực';

  @override
  String get communityExplorerLevel => 'Nhà khám phá Lv.5';

  @override
  String get communityPostEmptyContent => 'Nội dung bài viết đang trống.';

  @override
  String get postPickFromGallery => 'Chọn từ thư viện';

  @override
  String get postPickFromCamera => 'Chụp ảnh';

  @override
  String get postPickVideoFromGallery => 'Chọn video từ thư viện';

  @override
  String get postRecordVideo => 'Quay video';

  @override
  String get postCreateTitle => 'Tạo bài viết';

  @override
  String get postEditTitle => 'Sửa bài viết';

  @override
  String get postPublish => 'Đăng';

  @override
  String get postTextHint => 'Chia sẻ trải nghiệm của bạn...';

  @override
  String get postUploading => 'Đang tải...';

  @override
  String get postAddPlace => 'Thêm địa điểm';

  @override
  String get postAddMediaTitle => 'Thêm hình ảnh';

  @override
  String get postAttachPlaceTitle => 'Gắn địa điểm';

  @override
  String get postAddPhotoOrVideo => 'Thêm ảnh\nhoặc video';

  @override
  String get postChoosePlaceTitle => 'Chọn quán ăn hoặc địa điểm';

  @override
  String postNearYouDistanceMeters(int meters) {
    return 'Gần bạn (${meters}m)';
  }

  @override
  String postNearYouDistanceKm(String distance) {
    return 'Gần bạn (${distance}km)';
  }

  @override
  String get postPlaceSearchHint => 'Tìm địa điểm...';

  @override
  String get postPlaceSearchPrompt => 'Nhập tên để tìm kiếm.';

  @override
  String get postPlaceSearchEmpty => 'Không tìm thấy địa điểm.';

  @override
  String get postPlaceSearchError => 'Tìm kiếm thất bại. Thử lại.';

  @override
  String get postPlaceFallbackTitle => 'Địa điểm gần đây';

  @override
  String get postPlaceFallbackAddress => 'Địa chỉ đang cập nhật';

  @override
  String postSubmitFailed(Object error) {
    return 'Đăng bài thất bại: $error';
  }

  @override
  String reviewSectionTitle(Object count) {
    return 'Đánh giá ($count)';
  }

  @override
  String get reviewWriteTitle => 'Viết đánh giá';

  @override
  String get reviewEmpty => 'Chưa có bài đánh giá.';

  @override
  String get reviewDeleteTitle => 'Xóa đánh giá';

  @override
  String get reviewDeleteConfirm => 'Bạn chắc chắn muốn xóa đánh giá này?';

  @override
  String get reviewDinedHere => 'Đã ăn ở quán này';

  @override
  String reviewDinedHereWithDate(Object date) {
    return '$date - Đã ăn ở quán này';
  }

  @override
  String reviewFromUserWithDate(Object date) {
    return '$date - Đánh giá từ người dùng';
  }

  @override
  String get favoritesLoginRequired => 'Vui lòng đăng nhập để xem mục đã lưu.';

  @override
  String get favoritesTitle => 'Lưu yêu thích';

  @override
  String get favoritesSubtitle => 'Món ngon và quán bạn muốn thử';

  @override
  String get favoritesTabDishes => 'Món ăn';

  @override
  String get favoritesTabPlaces => 'Quán ăn';

  @override
  String get favoritesSearchHint => 'Tìm món ăn, quán đã lưu...';

  @override
  String get favoritesStatSavedDishes => 'món đã lưu';

  @override
  String get favoritesStatSavedPlaces => 'quán yêu thích';

  @override
  String get favoritesStatTodaySuggestions => 'gợi ý hôm nay';

  @override
  String get favoritesFilterCentral => 'Miền Trung';

  @override
  String get favoritesFilterSpicy => 'Cay';

  @override
  String get favoritesFilterBudget => 'Giá rẻ';

  @override
  String get favoritesFilterBreakfast => 'Bữa sáng';

  @override
  String get favoritesLoadError => 'Không thể tải danh sách yêu thích.';

  @override
  String get favoritePlacesLoadError => 'Không thể tải danh sách quán đã lưu.';

  @override
  String get favoritePlacesEmpty => 'Chưa có quán đã lưu.';

  @override
  String get favoritePlaceCategoryFallback => 'Ẩm thực địa phương';

  @override
  String get favoritePlaceNoRating => 'Chưa có đánh giá';

  @override
  String get favoritePlaceAddressFallback => 'Địa chỉ đang cập nhật';

  @override
  String get favoriteDishesLoadError => 'Không thể tải danh sách món đã lưu.';

  @override
  String get favoriteDishesEmpty => 'Chưa có món đã lưu.';

  @override
  String get favoriteSpicyNone => 'Không cay';

  @override
  String favoriteSpicyLevel(Object count) {
    return 'Độ cay $count';
  }

  @override
  String get favoriteProvinceUpdating => 'Đang cập nhật tỉnh...';

  @override
  String get regionNorth => 'Miền Bắc';

  @override
  String get regionCentral => 'Miền Trung';

  @override
  String get regionSouth => 'Miền Nam';

  @override
  String get placeNameFallback => 'Quán';

  @override
  String get placeAddressUpdating => 'Địa chỉ đang cập nhật';

  @override
  String get placeNoPhone => 'Chưa có số điện thoại';

  @override
  String get placeCallNow => 'Gọi ngay';

  @override
  String get placeCallAction => 'Gọi';

  @override
  String get placeReserve => 'Đặt bàn';

  @override
  String get placeInvite => 'Mời bạn';

  @override
  String get placeSchedule => 'Lên lịch';

  @override
  String get placePricePerPerson => '/người';

  @override
  String get placeDistanceUpdating => 'Khoảng cách đang cập nhật';

  @override
  String placeDistanceAway(Object distance) {
    return 'Cách đây $distance';
  }

  @override
  String get placeOpenHoursUpdating => 'Đang cập nhật giờ mở cửa';

  @override
  String placeClosesAt(Object time) {
    return 'Đóng lúc $time';
  }

  @override
  String get placeCategoryFallback => 'Ẩm thực địa phương';

  @override
  String get placeNoRating => 'Chưa có đánh giá';

  @override
  String get placeMenuMustTry => 'Món nên thử';

  @override
  String get placeMenuFull => 'Menu đầy đủ';

  @override
  String get placeMenuUpdating => 'Đang cập nhật món nên thử.';

  @override
  String get placeInfoTitle => 'Thông tin quán';

  @override
  String get placeOpenHoursLabel => 'Giờ mở cửa';

  @override
  String get amenityAirConditioner => 'Máy lạnh';

  @override
  String get amenityBankTransfer => 'Chuyển khoản';

  @override
  String get amenityFreeParking => 'Đỗ xe miễn phí';

  @override
  String get mapSearchHint => 'Tìm tên quán gần bạn...';

  @override
  String get mapCategoryRestaurants => 'Quán ăn';

  @override
  String get mapCategoryCafe => 'Cà phê';

  @override
  String get mapCategorySnack => 'Ăn vặt';

  @override
  String get mapCategoryFastFood => 'Đồ ăn nhanh';

  @override
  String get mapCategorySeafood => 'Hải sản';

  @override
  String get mapStyleNormal => 'Thường';

  @override
  String get mapStyleHighlight => 'Nổi bật';

  @override
  String get mapStyleSatellite => 'Vệ tinh';

  @override
  String get mapEnableLocation => 'Vui lòng bật vị trí.';

  @override
  String get mapLocationUnavailable => 'Chưa có vị trí.';

  @override
  String get mapPlaceNotFound => 'Không tìm thấy địa điểm.';

  @override
  String get mapEnableGpsToSearch => 'Hãy bật GPS để tìm quán.';

  @override
  String get mapPermissionDenied => 'Chưa có quyền vị trí.';

  @override
  String get mapGpsInvalid => 'Vị trí GPS không hợp lệ.';

  @override
  String get mapNearbyNotFound => 'Không tìm thấy quán gần đây.';

  @override
  String get mapLocationTimeout => 'Quá thời gian lấy vị trí.';

  @override
  String mapSearchError(Object error) {
    return 'Lỗi tìm kiếm: $error';
  }

  @override
  String get mapDirectionsError => 'Không lấy được chỉ đường.';

  @override
  String get mapOpenNow => 'Đang mở';

  @override
  String get mapClosed => 'Đang đóng';

  @override
  String get mapDirections => 'Chỉ đường';

  @override
  String mapNearbyPlacesTitle(Object count) {
    return 'Quán gần đây ($count)';
  }

  @override
  String mapEtaMinutes(Object minutes) {
    return '~$minutes phút';
  }

  @override
  String get mapSortDistance => 'Khoảng cách';

  @override
  String get mapOpenMap => 'Mở bản đồ';

  @override
  String get mapNoCoordinates => 'Không có tọa độ';

  @override
  String get mapPlaceFallbackName => 'Quán gần đây';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get genderOther => 'Khác';

  @override
  String get genderUnknown => 'Không xác định';

  @override
  String get profileEditTitle => 'Chỉnh sửa thông tin';

  @override
  String get profileNameLabel => 'Họ tên';

  @override
  String get profileNameRequired => 'Vui lòng nhập tên';

  @override
  String get profileGenderLabel => 'Giới tính';

  @override
  String get profileGenderHint => 'Chọn giới tính';

  @override
  String get profileDobLabel => 'Ngày sinh';

  @override
  String get profilePhoneLabel => 'Số điện thoại';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileAvatarTitle => 'Hình đại diện';

  @override
  String get profileAvatarUploadFailed => 'Tải ảnh thất bại';

  @override
  String get personalLocation => 'Vị trí';

  @override
  String get logoutTitle => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get logoutAction => 'Đăng xuất';

  @override
  String get themeSettingsTitle => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeLightDesc => 'Giao diện nền sáng, dễ nhìn ban ngày';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeDarkDesc => 'Giao diện nền tối, dịu mắt ban đêm';

  @override
  String get themeSystem => 'Tự động';

  @override
  String get themeSystemDesc => 'Tự đổi theo cài đặt thiết bị';

  @override
  String get themeAppearanceSection => 'Giao diện';

  @override
  String get themeDisplayMode => 'Chế độ hiển thị';

  @override
  String get themePreviewTitle => 'Xem trước giao diện';

  @override
  String get themePreviewNote =>
      'Khi bật theo hệ thống, ứng dụng sẽ tự đổi màu theo cài đặt thiết bị.';

  @override
  String get locationSettingsTitle => 'Vị trí';

  @override
  String get locationSettingsDescription =>
      'Bật/tắt vị trí để hiển thị trên bản đồ.';

  @override
  String get locationEnable => 'Bật vị trí';

  @override
  String get locationOpenSettings => 'Mở cài đặt GPS';

  @override
  String get locationOpenAppSettings => 'Mở cài đặt ứng dụng';

  @override
  String get locationError => 'Lỗi vị trí.';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordSuccess => 'Đổi mật khẩu thành công.';

  @override
  String get changePasswordCurrentLabel => 'Mật khẩu hiện tại';

  @override
  String get changePasswordNewLabel => 'Mật khẩu mới';

  @override
  String get changePasswordConfirmLabel => 'Xác nhận mật khẩu mới';

  @override
  String get changePasswordCurrentRequired => 'Vui lòng nhập mật khẩu hiện tại';

  @override
  String get changePasswordNewRequired => 'Vui lòng nhập mật khẩu mới';

  @override
  String get changePasswordNewTooShort => 'Mật khẩu mới ít nhất 6 ký tự';

  @override
  String get changePasswordConfirmRequired => 'Vui lòng xác nhận mật khẩu mới';

  @override
  String get changePasswordMismatch => 'Mật khẩu mới không khớp';

  @override
  String get changePasswordErrorMissingFields =>
      'Vui lòng nhập đầy đủ thông tin.';

  @override
  String get changePasswordErrorMismatch => 'Mật khẩu mới không khớp.';

  @override
  String get changePasswordErrorTooShort => 'Mật khẩu mới ít nhất 6 ký tự.';

  @override
  String get changePasswordErrorWrongCurrent => 'Mật khẩu hiện tại không đúng.';

  @override
  String get changePasswordErrorWeak => 'Mật khẩu mới quá yếu.';

  @override
  String get changePasswordErrorRequiresLogin =>
      'Vui lòng đăng nhập lại rồi thử lại.';

  @override
  String get changePasswordErrorNoUser => 'Chưa đăng nhập.';

  @override
  String get changePasswordErrorNoEmail =>
      'Không tìm thấy email cho tài khoản này.';

  @override
  String get changePasswordErrorNoPasswordProvider =>
      'Tài khoản đăng nhập bằng Google, không đổi được mật khẩu.';

  @override
  String get changePasswordErrorUnknown => 'Đổi mật khẩu thất bại.';

  @override
  String get changePasswordBannerTitle => 'Bảo vệ tài khoản của bạn';

  @override
  String get changePasswordBannerSubtitle =>
      'Hãy dùng mật khẩu mạnh để giữ an toàn cho hành trình ẩm thực của bạn';

  @override
  String get changePasswordBannerBadge => 'FoodS Security';

  @override
  String get changePasswordStrengthTitle => 'Độ mạnh mật khẩu';

  @override
  String get changePasswordStrengthWeak => 'Yếu';

  @override
  String get changePasswordStrengthMedium => 'Trung bình';

  @override
  String get changePasswordStrengthStrong => 'Mạnh';

  @override
  String get changePasswordStrengthVeryStrong => 'Rất mạnh';

  @override
  String get changePasswordTipsTitle => 'Gợi ý mật khẩu an toàn';

  @override
  String get changePasswordTipLength => 'Ít nhất 8 ký tự';

  @override
  String get changePasswordTipUpperLower => 'Có chữ hoa và chữ thường';

  @override
  String get changePasswordTipNumber => 'Có số';

  @override
  String get changePasswordTipSpecial => 'Có ký tự đặc biệt';

  @override
  String get changePasswordTipNoReuse => 'Không trùng mật khẩu cũ';

  @override
  String get changePasswordForgotPrompt => 'Bạn quên mật khẩu hiện tại?';

  @override
  String get changePasswordResetAction => 'Đặt lại mật khẩu';

  @override
  String get changePasswordResetSuccess => 'Đã gửi email đặt lại mật khẩu.';

  @override
  String get changePasswordResetNoEmail =>
      'Không tìm thấy email cho tài khoản này.';

  @override
  String get changePasswordResetFailed =>
      'Không thể gửi email đặt lại mật khẩu.';

  @override
  String get changePasswordInfoText =>
      'Sau khi đổi mật khẩu, bạn nên đăng nhập lại trên các thiết bị khác để đảm bảo an toàn.';

  @override
  String get changePasswordCancel => 'Hủy';

  @override
  String get changePasswordUpdate => 'Cập nhật mật khẩu';

  @override
  String get authLoginTitle => 'Chào mừng trở lại!';

  @override
  String get authLoginSubtitle => 'Đăng nhập tài khoản món ăn';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Vui lòng nhập email';

  @override
  String get authEmailInvalid => 'Email không hợp lệ';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get authLoginAction => 'Đăng nhập';

  @override
  String get authOr => 'hoặc';

  @override
  String get authContinueGoogle => 'Tiếp tục với Google';

  @override
  String get authContinueApple => 'Tiếp tục với Apple';

  @override
  String get authForgotPassword => 'Quên mật khẩu?';

  @override
  String get authResetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get authResetPasswordDescription =>
      'Nhập email của bạn để nhận đường dẫn đặt lại mật khẩu.';

  @override
  String get authResetPasswordSend => 'Gửi hướng dẫn';

  @override
  String get authResetPasswordCancel => 'Hủy';

  @override
  String get authResetPasswordSuccess =>
      'Nếu email đã được đăng ký, hướng dẫn đặt lại mật khẩu sẽ được gửi đến email đó.';

  @override
  String get authResetPasswordTooManyRequests =>
      'Bạn đã gửi quá nhiều yêu cầu. Vui lòng đợi một lúc rồi thử lại.';

  @override
  String get authResetPasswordNetworkError =>
      'Không có kết nối mạng. Vui lòng kiểm tra Internet.';

  @override
  String get authResetPasswordFailed =>
      'Không thể gửi hướng dẫn lúc này. Vui lòng thử lại sau.';

  @override
  String get authNoAccount => 'Chưa có tài khoản? ';

  @override
  String get authRegisterAction => 'Đăng ký';

  @override
  String get authLoginFailed => 'Đăng nhập thất bại';

  @override
  String get authLoginUserNotFound => 'Tài khoản không tồn tại';

  @override
  String get authLoginWrongPassword => 'Mật khẩu không đúng';

  @override
  String get authGoogleFailed => 'Đăng nhập Google thất bại';

  @override
  String get authGoogleAccountExists =>
      'Tài khoản đã tồn tại với cách đăng nhập khác';

  @override
  String get authGoogleInvalidCredential => 'Thông tin Google không hợp lệ';

  @override
  String authError(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get authRegisterTitle => 'Tạo tài khoản';

  @override
  String get authRegisterSubtitle =>
      'Tham gia và khám phá quán ngon quanh bạn.';

  @override
  String get authFullNameLabel => 'Họ tên';

  @override
  String get authFullNameRequired => 'Vui lòng nhập họ tên';

  @override
  String get authPhoneOptionalLabel => 'Số điện thoại (tùy chọn)';

  @override
  String get authConfirmPasswordLabel => 'Nhập lại mật khẩu';

  @override
  String get authConfirmPasswordRequired => 'Vui lòng nhập lại mật khẩu';

  @override
  String get authPasswordTooShort => 'Mật khẩu tối thiểu 6 ký tự';

  @override
  String get authPasswordMismatch => 'Mật khẩu không trùng khớp';

  @override
  String get authPasswordTooWeak => 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';

  @override
  String get authRegisterSuccess => 'Đăng ký thành công';

  @override
  String get authAgreePrefix => 'Tôi đồng ý với ';

  @override
  String get authTerms => 'Điều khoản';

  @override
  String get authAnd => ' và ';

  @override
  String get authPrivacy => 'Chính sách bảo mật';

  @override
  String get authDot => '.';

  @override
  String get authRegisterFailed => 'Đăng ký thất bại';

  @override
  String get authRegisterEmailInUse => 'Email đã được sử dụng';

  @override
  String get authRegisterUserMissing => 'Không lấy được tài khoản vừa tạo';

  @override
  String get provinceLoadError => 'Không thể tải tỉnh thành.';

  @override
  String get provinceNotFound => 'Không tìm thấy tỉnh.';

  @override
  String get provinceIntroTitle => 'Giới thiệu';

  @override
  String get provinceNoDescription => 'Chưa có mô tả.';

  @override
  String get provinceSpecialtiesTitle => 'Đặc sản tiêu biểu';

  @override
  String get provinceDishesLoadError => 'Không thể tải món ăn.';

  @override
  String get provinceNoDishes => 'Chưa có món ăn cho tỉnh này.';

  @override
  String get dishNotFound => 'Không tìm thấy món ăn.';

  @override
  String get dishLoginToSave => 'Vui lòng đăng nhập để lưu.';

  @override
  String get dishShareTodo => 'Chia sẻ sắp có.';

  @override
  String get dishSpecialtyFallback => 'Món ăn đặc sản';

  @override
  String get dishSpicyLabel => 'Độ cay';

  @override
  String get dishSatietyLabel => 'Độ no';

  @override
  String get dishBestSeasonTitle => 'Mùa ngon nhất';

  @override
  String get dishBestTimeTitle => 'Thời điểm ăn';

  @override
  String get dishNotUpdated => 'Chưa cập nhật';

  @override
  String get dishIntroductionTitle => 'Giới thiệu';

  @override
  String get dishNoDescription => 'Chưa có mô tả cho món ăn này.';

  @override
  String get dishReadMore => 'Đọc thêm';

  @override
  String get dishCollapse => 'Thu gọn';

  @override
  String get dishIngredientsTitle => 'Nguyên liệu';

  @override
  String get dishPreparationTitle => 'Cách chế biến';

  @override
  String get dishNoInstructions => 'Chưa có hướng dẫn chế biến.';

  @override
  String get dishPriceRangeTitle => 'Khoảng giá';

  @override
  String get dishFindNearby => 'Tìm quán gần đây';

  @override
  String get routeMissingProvinceId => 'Thiếu id tỉnh';

  @override
  String get routeMissingDishId => 'Thiếu id món ăn';

  @override
  String get routeNotFound => 'Không tìm thấy đường dẫn';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get reviewAlreadyTitle => 'Bạn đã đánh giá';

  @override
  String get reviewAlreadyMessage =>
      'Bạn đã đánh giá địa điểm này. Sửa đánh giá?';

  @override
  String get reviewEditConfirm => 'Sửa đánh giá';

  @override
  String get reviewHint => 'Chia sẻ cảm nhận của bạn...';

  @override
  String get searchDishTab => 'Món ăn';

  @override
  String get searchPlaceTab => 'Quán ăn';

  @override
  String get searchResultHint => 'Tìm món ăn, nguyên liệu, quán ngon...';

  @override
  String get searchDishLoadErrorTitle => 'Không thể tìm món ăn';

  @override
  String get searchDishLoadErrorSubtitle =>
      'Dữ liệu tìm kiếm đang gặp lỗi. Vui lòng thử lại sau.';

  @override
  String get searchDishEmptyTitle => 'Chưa tìm thấy món phù hợp';

  @override
  String get searchDishEmptyStart =>
      'Nhập tên món, nguyên liệu hoặc đặc sản để bắt đầu tìm.';

  @override
  String get searchDishEmptyTryAgain =>
      'Thử đổi từ khóa ngắn hơn hoặc tìm theo tỉnh thành khác.';

  @override
  String get searchMatchingDishes => 'món ăn phù hợp';

  @override
  String get searchProvincePriority => 'Ưu tiên đặc sản tại';

  @override
  String get searchRelevanceSorted => 'Kết quả được sắp xếp theo độ liên quan';

  @override
  String get searchPlaceLoadErrorTitle => 'Không thể tìm quán ăn';

  @override
  String get searchPlaceLoadErrorSubtitle =>
      'Dịch vụ tìm địa điểm đang tạm thời gián đoạn.';

  @override
  String get searchPlaceEmptyTitle => 'Không tìm thấy quán ăn';

  @override
  String get searchPlaceEmptyStart =>
      'Nhập tên quán hoặc khu vực để hiển thị kết quả.';

  @override
  String get searchPlaceEmptyTryAgain =>
      'Thử thêm tên đường, khu vực hoặc một từ khóa cụ thể hơn.';

  @override
  String get searchRelevantPlaces => 'quán ăn liên quan';

  @override
  String get searchNearbySorted =>
      'Đã ưu tiên sắp xếp theo khoảng cách gần bạn';

  @override
  String get searchPlaceRelevance =>
      'Kết quả địa điểm phù hợp với từ khóa của bạn';

  @override
  String get searchSpicy => 'Cay';

  @override
  String get searchOpenNow => 'Đang mở cửa';

  @override
  String get searchTemporarilyClosed => 'Tạm đóng';
}
