import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_service.dart';

class EditPersonalPage extends StatefulWidget {
  const EditPersonalPage({super.key});

  @override
  State<EditPersonalPage> createState() => _EditPersonalPageState();
}

class _EditPersonalPageState extends State<EditPersonalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() { // khi mở trang thì tự động load dữ liệu
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser; // lấy dữ liệu khi đã nhớ đăng nhập
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await UserService().getUserById(user.uid);
    _nameController.text =
        (profile?.fullName ?? user.displayName ?? '').trim();
    _phoneController.text = (profile?.phone ?? '').trim();
    _emailController.text = (profile?.email ?? user.email ?? '').trim();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  // lưu dữ liệu 
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true); // bật trạng thái lưu
    // lấy dữ liệu từ input
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    // lưu dữ liệu trong firestore
    await UserService().updateUserProfile(
      uid: user.uid,
      fullName: fullName,
      phone: phone.isEmpty ? null : phone,
    );
    // cập nhật fire auth
    if (fullName.isNotEmpty && user.displayName != fullName) {
      await user.updateDisplayName(fullName);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }
  // dọn dẹp bộ nhớ
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  // build giao diện
  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinh sua thong tin'),
        actions: [
          TextButton(
            onPressed: _isSaving || _isLoading ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Luu'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _AvatarRow(photoUrl: photoUrl),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui long nhap ten';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'So dien thoai',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // chỉ đọc , không được sửa
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
// hiển thị ảnh 
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: const Text('Hinh dai dien'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: hook up avatar change.
      },
    );
  }
}