import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class PersonalViewData { // dữ liệu đã sử dụng để UI sử dụng
  const PersonalViewData({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
  });

  final String name;
  final String subtitle;
  final String? photoUrl;

  factory PersonalViewData.from(User? authUser, UserModel? profile) { // ưu tiên sửa đổi tên theo thứ tự như dưới
    final profileName = profile?.fullName.trim() ?? '';
    final authName = authUser?.displayName?.trim() ?? '';
    final name = profileName.isNotEmpty
        ? profileName
        : authName.isNotEmpty
            ? authName
            : 'FoodG User';

    final profileEmail = profile?.email.trim() ?? '';
    final authEmail = authUser?.email?.trim() ?? '';
    final subtitle = profileEmail.isNotEmpty
        ? profileEmail
        : authEmail.isNotEmpty
            ? authEmail
            : 'ID: chua thiet lap';

    final profilePhoto = profile?.photoUrl?.trim() ?? '';
    final photoUrl =
        profilePhoto.isNotEmpty ? profile!.photoUrl : authUser?.photoURL;

    return PersonalViewData( // trả về 1 object duy nhất 
      name: name,
      subtitle: subtitle,
      photoUrl: photoUrl,
    );
  }
}

class PersonalController extends ChangeNotifier {
  PersonalController({FirebaseAuth? auth, UserService? userService})
      : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  bool _isLoading = true;
  User? _authUser;
  UserModel? _profile;

  bool get isLoading => _isLoading;
  User? get authUser => _authUser;
  PersonalViewData get viewData => PersonalViewData.from(_authUser, _profile);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _authUser = _auth.currentUser;
    if (_authUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _profile = await _userService.getUserById(_authUser!.uid);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();
}