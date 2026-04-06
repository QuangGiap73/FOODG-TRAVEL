import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agree = false;

  final _authService = AuthService();
  final _userService = UserService();

  String _mapRegisterError(AppLocalizations t, FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return t.authRegisterEmailInUse;
      case 'weak-password':
        return t.authPasswordTooWeak;
      case 'invalid-email':
        return t.authEmailInvalid;
      default:
        return t.authRegisterFailed;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context)!;
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý điều khoản.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.authPasswordMismatch)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential cred = await _authService.registerWithEmail(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception(t.authRegisterUserMissing);
      }

      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        phone: phone.isEmpty ? null : phone,
        role: 'user',
      );
      await _userService.createUser(userModel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.authRegisterSuccess)),
      );

      // Sau khi đăng ký xong, quay về màn đăng nhập
      Navigator.pushReplacementNamed(context, RouteNames.login);
    } on FirebaseAuthException catch (e) {
      final message = _mapRegisterError(t, e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authError(e.toString()))));
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
    final scaffoldBg = isDark ? const Color(0xFF0F131A) : const Color(0xFFFAFAF9);
    final cardColor = isDark ? const Color(0xFF161B24) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final fieldFill = isDark ? const Color(0xFF1E2633) : const Color(0xFFF8FAFC);
    final headerGradTop = isDark ? const Color(0xFF1B2432) : const Color(0xFFFFF1E6);
    final headerGradBottom = isDark ? const Color(0xFF111827) : const Color(0xFFFFE0CC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [headerGradTop, headerGradBottom],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/patterns/leaf.png'),
                            fit: BoxFit.cover,
                            opacity: 0.05,
                          ),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.pushReplacementNamed(
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
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Icon(Icons.restaurant_menu,
                            color: Color(0xFFFF6A00), size: 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.authRegisterTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.authRegisterSubtitle,
                      style: TextStyle(color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 6,
                                    color: Color(0x11000000),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Số điện thoại',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  blurRadius: 16,
                                  color: Color(0x14000000),
                                  offset: Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _Field(
                              label: t.authFullNameLabel,
                              icon: Icons.person_outline,
                              controller: _nameController,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? t.authFullNameRequired
                                      : null,
                              fillColor: fieldFill,
                              textColor: textPrimary,
                              hintColor: textSecondary,
                              borderColor: borderColor,
                              focusedColor: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              label: t.authEmailLabel,
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return t.authEmailRequired;
                                }
                                if (!v.contains('@')) {
                                  return t.authEmailInvalid;
                                }
                                return null;
                              },
                              fillColor: fieldFill,
                              textColor: textPrimary,
                              hintColor: textSecondary,
                              borderColor: borderColor,
                              focusedColor: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              label: t.authPhoneOptionalLabel,
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              fillColor: fieldFill,
                              textColor: textPrimary,
                              hintColor: textSecondary,
                              borderColor: borderColor,
                              focusedColor: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              label: t.authPasswordLabel,
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscure: _obscurePassword,
                              onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return t.authPasswordRequired;
                                }
                                if (v.trim().length < 6) {
                                  return t.authPasswordTooShort;
                                }
                                return null;
                              },
                              fillColor: fieldFill,
                              textColor: textPrimary,
                              hintColor: textSecondary,
                              borderColor: borderColor,
                              focusedColor: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              label: t.authConfirmPasswordLabel,
                              icon: Icons.lock_outline,
                              controller: _confirmPasswordController,
                              obscure: _obscureConfirmPassword,
                              onToggle: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
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
                              fillColor: fieldFill,
                              textColor: textPrimary,
                              hintColor: textSecondary,
                              borderColor: borderColor,
                              focusedColor: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _agree,
                                  activeColor: const Color(0xFFFF6A00),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity:
                                      const VisualDensity(horizontal: -2, vertical: -2),
                                  onChanged: (v) =>
                                      setState(() => _agree = v ?? false),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Tôi đồng ý với ',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'Điều khoản',
                                            style: TextStyle(
                                              color: Color(0xFFFF6A00),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' và '),
                                          TextSpan(
                                            text: 'Chính sách bảo mật',
                                            style: TextStyle(
                                              color: Color(0xFFFF6A00),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A00),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          shadowColor: Colors.orange.shade200,
                          elevation: 10,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                t.authRegisterAction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: Divider(color: dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Hoặc đăng ký với',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: dividerColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.g_mobiledata,
                                    color: Colors.red, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Đăng ký với Google',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.onToggle,
    this.validator,
    this.keyboardType,
    required this.fillColor,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.focusedColor,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Color fillColor;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final Color focusedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            prefixIcon: Icon(icon, color: hintColor),
            suffixIcon: onToggle == null
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
            hintStyle: TextStyle(color: hintColor),
          ),
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}
