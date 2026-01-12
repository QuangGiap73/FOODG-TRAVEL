import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithEmail(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _ensureUserProfile(user, email);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } on FirebaseAuthException catch (e) {
      String message = 'ÄÄƒng nháº­p tháº¥t báº¡i';
      if (e.code == 'user-not-found') {
        message = 'TÃ i khoáº£n khÃ´ng tá»“n táº¡i';
      } else if (e.code == 'wrong-password') {
        message = 'Máº­t kháº©u khÃ´ng Ä‘Ãºng';
      } else if (e.code == 'invalid-email') {
        message = 'Email khÃ´ng há»£p lá»‡';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lá»—i: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user;
      if (user != null) {
        await _ensureUserProfile(user, user.email ?? "");
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == "sign_in_canceled") {
        return;
      }
      String message = "Google sign-in failed";
      if (e.code == "account-exists-with-different-credential") {
        message = "Account exists with a different sign-in method";
      } else if (e.code == "invalid-credential") {
        message = "Invalid Google credential";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // áº¢nh mÃ³n Äƒn
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login to your food account',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui long dang nhap email';
                          }
                          if (!value.contains('@')) {
                            return 'Email khong hop le';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui long nhap mat khau khac';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("or"),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text("Continue with Google"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                RouteNames.register,
                              );
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
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
