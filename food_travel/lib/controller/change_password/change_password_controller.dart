import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController({AuthService? authService})
      : _authService = authService ?? AuthService();

  static const errorMissingFields = 'missing_fields';
  static const errorPasswordMismatch = 'password_mismatch';
  static const errorPasswordTooShort = 'password_too_short';
  static const errorWrongPassword = 'wrong_password';
  static const errorWeakPassword = 'weak_password';
  static const errorRequiresRecentLogin = 'requires_recent_login';
  static const errorNoUser = 'no_user';
  static const errorNoPasswordProvider = 'no_password_provider';
  static const errorUnknown = 'unknown';

  final AuthService _authService;
  bool _isLoading = false;
  String? _errorCode;
  bool _success = false;

  bool get isLoading => _isLoading;
  String? get errorCode => _errorCode;
  bool get success => _success;

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _errorCode = null;
    _success = false;

    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      _errorCode = errorMissingFields;
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _errorCode = errorPasswordMismatch;
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _errorCode = errorPasswordTooShort;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _success = true;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = _mapErrorCode(e.code);
      return false;
    } catch (_) {
      _errorCode = errorUnknown;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return errorWrongPassword;
      case 'weak-password':
        return errorWeakPassword;
      case 'requires-recent-login':
        return errorRequiresRecentLogin;
      case 'no-user':
        return errorNoUser;
      case 'no-password-provider':
        return errorNoPasswordProvider;
      default:
        return errorUnknown;
    }
  }
}
