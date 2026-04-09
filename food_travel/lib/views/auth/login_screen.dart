import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _authService = AuthService();
  final _userService = UserService();

  Future<void> _ensureUserProfile(User user, String fallbackEmail) async {
    final existing = await _userService.getUserById(user.uid);
    if (existing == null) {
      final displayName = user.displayName?.trim();
      final fullName = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (user.email ?? fallbackEmail);
      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: user.email ?? fallbackEmail,
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
        role: 'user',
      );
      await _userService.createUser(userModel);
    } else {
      if (existing.role.isEmpty) {
        await _userService.ensureUserRole(uid: user.uid, role: 'user');
      }
      final photoUrl = user.photoURL;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          existing.photoUrl != photoUrl) {
        await _userService.updateUserPhotoUrl(
          uid: user.uid,
          photoUrl: photoUrl,
        );
      }
    }
  }

  String _mapLoginError(AppLocalizations t, FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return t.authLoginUserNotFound;
      case 'wrong-password':
        return t.authLoginWrongPassword;
      case 'invalid-email':
        return t.authEmailInvalid;
      default:
        return t.authLoginFailed;
    }
  }

  String _mapGoogleError(AppLocalizations t, FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return t.authGoogleAccountExists;
      case 'invalid-credential':
        return t.authGoogleInvalidCredential;
      default:
        return t.authGoogleFailed;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final cred = await _authService
          .loginWithEmail(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final user = cred.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-missing',
          message: 'No user after login.',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.authGate);

      unawaited(
        _ensureUserProfile(user, email)
            .timeout(const Duration(seconds: 12))
            .catchError((e, _) {
          debugPrint('ensureUserProfile failed: $e');
        }),
      );
    } on TimeoutException {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.authError(
              'Dang nhap qua lau. Kiem tra mang/Google Play Services.',
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final t = AppLocalizations.of(context)!;
      final message = _mapLoginError(t, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authError(e.toString()))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService
          .signInWithGoogle()
          .timeout(const Duration(seconds: 20));
      final user = cred.user;
      if (user != null) {
        unawaited(
          _ensureUserProfile(user, user.email ?? "")
              .timeout(const Duration(seconds: 12))
              .catchError((e, _) {
            debugPrint('ensureUserProfile failed: $e');
          }),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.authGate);
    } on TimeoutException {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.authError(
              'Dang nhap Google qua lau. Kiem tra mang/Google Play Services.',
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return;
      }
      final t = AppLocalizations.of(context)!;
      final message = _mapGoogleError(t, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authError(e.toString()))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                height: 180,
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
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Color(0xFFFF6A00),
                          size: 42,
                        ),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  blurRadius: 20,
                                  color: Color(0x11000000),
                                  offset: Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            t.authLoginTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Social buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _handleGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                                      const SizedBox(width: 8),
                                      Text(t.authContinueGoogle, style: TextStyle(color: textPrimary)),
                                    ],
                                  ),
                                ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                          const SizedBox(height: 14),
                          Row(
                              children: [
                              Expanded(child: Divider(color: dividerColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  t.authOr,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: dividerColor)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _TextFieldCard(
                                  label: t.authEmailLabel,
                                  icon: Icons.person_outline,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return t.authEmailRequired;
                                    }
                                    if (!value.contains('@')) {
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
                                _TextFieldCard(
                                  label: t.authPasswordLabel,
                                  icon: Icons.lock_outline,
                                  controller: _passwordController,
                                  obscure: _obscurePassword,
                                  onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty) ? t.authPasswordRequired : null,
                                  fillColor: fieldFill,
                                  textColor: textPrimary,
                                  hintColor: textSecondary,
                                  borderColor: borderColor,
                                  focusedColor: const Color(0xFFFF6A00),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                onPressed: () {
                                  // TODO: Forgot password flow
                                },
                                child: Text(
                                  t.authForgotPassword,
                                  style: const TextStyle(
                                    color: Color(0xFFFF6A00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                t.authLoginAction,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: '${t.authNoAccount} ',
                        style: TextStyle(color: textSecondary),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, RouteNames.register),
                              child: Text(
                                t.authRegisterAction,
                                style: const TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
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

class _TextFieldCard extends StatelessWidget {
  const _TextFieldCard({
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.onSuffixTap,
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
  final VoidCallback? onSuffixTap;
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
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            prefixIcon: Icon(icon, color: hintColor),
            suffixIcon: onSuffixTap == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: hintColor,
                    ),
                    onPressed: onSuffixTap,
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
