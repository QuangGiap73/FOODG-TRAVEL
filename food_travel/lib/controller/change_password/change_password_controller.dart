import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ChangePasswordController extends ChangeNotifier {
    ChangePasswordController({AuthService? authService})
        : _authService = authService ?? AuthService();

    final AuthService _authService; // xu ly firebbase
    bool _isLoading = false;
    String? _errorMessage;
    bool _success = false;

    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;
    bool get success => _success;

    // ham khi usser bam doi mk
    Future<bool> submit({
        required String currentPassword,
        required String newPassword,
        required String confirmPassword,
    }) async {
        // reset trang thai cu
        _errorMessage = null;
        _success = false;
    // Kiểm tra nhập đủ thông tin chưa
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      _errorMessage = 'Vui long nhap day du thong tin.';
      notifyListeners(); // báo UI cập nhật
      return false;
    }
    // Kiểm tra mật khẩu mới có khớp không
    if (newPassword != confirmPassword) {
      _errorMessage = 'Mat khau moi khong trung khop.';
      notifyListeners();
      return false;
    }

    // Firebase yêu cầu mật khẩu ít nhất 6 ký tự
    if (newPassword.length < 6) {
      _errorMessage = 'Mat khau moi it nhat 6 ky tu.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try{
        // Goi Authservice de doi mk
        await _authService.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,

        );
        _success = true;
        return true;
    }
    // Bắt lỗi Firebase (sai mật khẩu, login quá lâu, Google login, ...)
    on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      return false;
    }
    // Bắt lỗi không xác định
    catch (_) {
      _errorMessage = 'Doi mat khau that bai. Thu lai sau.';
      return false;
    }
    finally {
      _isLoading = false;
      notifyListeners(); // UI cập nhật lại
    }
}
/// Chuyển mã lỗi Firebase → thông báo dễ hiểu cho người dùng
  String _mapError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mat khau hien tai khong dung.';

      case 'weak-password':
        return 'Mat khau moi qua yeu.';

      case 'requires-recent-login':
        return 'Vui long dang nhap lai roi thu lai.';

      case 'no-user':
        return 'Chua dang nhap.';

      case 'no-password-provider':
        return 'Tai khoan dang nhap bang Google, khong doi duoc mat khau.';

      default:
        return 'Doi mat khau that bai.';
    }
  }
}