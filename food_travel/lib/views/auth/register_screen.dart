import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/user_model.dart';
import '../../router/route_names.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'widgets/auth_error_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agree = false;
  String? _formError;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  Future<void> _ensureUserProfile(
    User user,
    String fallbackEmail,
    String fullName,
    String phone,
  ) async {
    final existing = await _userService.getUserById(user.uid);
    if (existing == null) {
      await _userService.createUser(
        UserModel(
          id: user.uid,
          fullName: fullName,
          email: user.email ?? fallbackEmail,
          phone: phone.isEmpty ? null : phone,
          photoUrl: user.photoURL,
          role: 'user',
        ),
      );
      return;
    }

    if (existing.role.isEmpty) {
      await _userService.ensureUserRole(uid: user.uid, role: 'user');
    }
  }

  String _mapRegisterError(AppLocalizations t, FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return t.authRegisterEmailInUse;
      case 'weak-password':
        return t.authPasswordTooWeak;
      case 'invalid-email':
        return t.authEmailInvalid;
      case 'operation-not-allowed':
        return _isVi
            ? 'Đăng ký bằng email hiện chưa được hỗ trợ.'
            : 'Email registration is currently unavailable.';
      case 'too-many-requests':
        return _isVi
            ? 'Bạn đã thử quá nhiều lần. Vui lòng đợi một lúc rồi thử lại.'
            : 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return _isVi
            ? 'Không có kết nối mạng. Vui lòng kiểm tra Internet.'
            : 'No network connection. Please check your Internet.';
      default:
        return t.authRegisterFailed;
    }
  }

  Future<void> _handleRegister() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) {
      setState(
        () =>
            _formError =
                _isVi
                    ? 'Vui lòng kiểm tra lại các thông tin được đánh dấu.'
                    : 'Please check the highlighted information.',
      );
      return;
    }

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (!_agree) {
      setState(
        () =>
            _formError =
                _isVi
                    ? 'Bạn cần đồng ý với Điều khoản và Chính sách bảo mật.'
                    : 'You must agree to the Terms and Privacy Policy.',
      );
      return;
    }

    if (password != confirm) {
      setState(() => _formError = t.authPasswordMismatch);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await _authService
          .registerWithEmail(email: email, password: password)
          .timeout(const Duration(seconds: 20));

      final user = cred.user;
      if (user == null) {
        throw Exception(t.authRegisterUserMissing);
      }

      unawaited(
        _ensureUserProfile(
          user,
          email,
          fullName,
          phone,
        ).timeout(const Duration(seconds: 12)).catchError((error, _) {
          debugPrint('ensureUserProfile failed: $error');
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.authRegisterSuccess)));
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.login);
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () =>
            _formError =
                _isVi
                    ? 'Kết nối mất quá nhiều thời gian. Vui lòng kiểm tra mạng.'
                    : 'The connection timed out. Please check your network.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _formError = _mapRegisterError(t, e));
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _formError =
                _isVi
                    ? 'Không thể tạo tài khoản lúc này. Vui lòng thử lại.'
                    : 'Unable to create an account right now. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1218) : const Color(0xFFFFF7F0);
    final cardBg = isDark ? const Color(0xFF171B22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF2A303A) : const Color(0xFFE9E5DF);
    final accent = const Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/login/login_banner.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    Positioned(
                      left: 16,
                      top: MediaQuery.of(context).padding.top + 8,
                      child: InkWell(
                        onTap:
                            () => Navigator.pushReplacementNamed(
                              context,
                              RouteNames.login,
                            ),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(21),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                color: Color(0x22000000),
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -46),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: borderColor),
                      boxShadow:
                          isDark
                              ? null
                              : const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.authRegisterTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.authRegisterSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _AuthField(
                                label: t.authFullNameLabel,
                                hintText: t.authFullNameLabel,
                                icon: Icons.person_outline,
                                controller: _nameController,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF8FAFC),
                                textColor: textPrimary,
                                hintColor: textSecondary,
                                borderColor: borderColor,
                                focusedColor: accent,
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? t.authFullNameRequired
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              _AuthField(
                                label: t.authEmailLabel,
                                hintText: 'Email',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF8FAFC),
                                textColor: textPrimary,
                                hintColor: textSecondary,
                                borderColor: borderColor,
                                focusedColor: accent,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return t.authEmailRequired;
                                  }
                                  if (!RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(v.trim())) {
                                    return t.authEmailInvalid;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _AuthField(
                                label: t.authPhoneOptionalLabel,
                                hintText: t.authPhoneOptionalLabel,
                                icon: Icons.phone_outlined,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF8FAFC),
                                textColor: textPrimary,
                                hintColor: textSecondary,
                                borderColor: borderColor,
                                focusedColor: accent,
                                validator: (v) {
                                  final phone = v?.trim() ?? '';
                                  if (phone.isEmpty) {
                                    return null;
                                  }
                                  final normalized = phone.replaceAll(
                                    RegExp(r'[\s.()-]'),
                                    '',
                                  );
                                  if (!RegExp(
                                    r'^\+?[0-9]{9,15}$',
                                  ).hasMatch(normalized)) {
                                    return _isVi
                                        ? 'Số điện thoại không hợp lệ'
                                        : 'Invalid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _AuthField(
                                label: t.authPasswordLabel,
                                hintText: t.authPasswordLabel,
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                obscure: _obscurePassword,
                                onToggle:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF8FAFC),
                                textColor: textPrimary,
                                hintColor: textSecondary,
                                borderColor: borderColor,
                                focusedColor: accent,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return t.authPasswordRequired;
                                  }
                                  if (v.trim().length < 6) {
                                    return t.authPasswordTooShort;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _AuthField(
                                label: t.authConfirmPasswordLabel,
                                hintText: t.authConfirmPasswordLabel,
                                icon: Icons.lock_outline,
                                controller: _confirmPasswordController,
                                obscure: _obscureConfirmPassword,
                                onToggle:
                                    () => setState(
                                      () =>
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                    ),
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF8FAFC),
                                textColor: textPrimary,
                                hintColor: textSecondary,
                                borderColor: borderColor,
                                focusedColor: accent,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return t.authConfirmPasswordRequired;
                                  }
                                  if (v.trim() !=
                                      _passwordController.text.trim()) {
                                    return t.authPasswordMismatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agree,
                                    onChanged:
                                        (value) => setState(
                                          () => _agree = value ?? false,
                                        ),
                                    activeColor: accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${t.authAgreePrefix}${t.authTerms}${t.authAnd}${t.authPrivacy}${t.authDot}',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_formError != null) ...[
                          AuthErrorBanner(
                            message: _formError!,
                            onDismiss: () => setState(() => _formError = null),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      t.authRegisterAction,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: Divider(color: borderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '${t.authOr} ${t.authRegisterAction.toLowerCase()}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: borderColor)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF171B22)
                                      : Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4285F4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t.authContinueGoogle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  RouteNames.login,
                                ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  const TextSpan(text: 'Đã có tài khoản? '),
                                  TextSpan(
                                    text: t.authLoginAction,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.fillColor,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.focusedColor,
    this.obscure = false,
    this.onToggle,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final Color fillColor;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final Color focusedColor;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hintColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(icon, color: hintColor),
            suffixIcon:
                onToggle == null
                    ? null
                    : IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: hintColor,
                      ),
                      onPressed: onToggle,
                    ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusedColor),
            ),
          ),
        ),
      ],
    );
  }
}
