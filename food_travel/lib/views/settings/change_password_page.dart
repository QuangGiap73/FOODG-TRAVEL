import 'package:flutter/material.dart';
import '../../controller/change_password/change_password_controller.dart';

class ChangePasswordPage extends StatefulWidget {
    const ChangePasswordPage({super.key});

    @override
    State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
    final _controller = ChangePasswordController(); // controller xu ly logic doi mk
    final _formKey = GlobalKey<FormState>(); // tao key form
    // controller cho nhap 3 o mk
    final _currentController = TextEditingController();
    final _newController = TextEditingController();
    final _confirmController = TextEditingController();
    // bien an hien thi mk
    bool _obscureCurrent = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    // giai phong bo nho
    @override
    void dispose() {
        _controller.dispose();
        _currentController.dispose();
        _newController.dispose();
        _confirmController.dispose();
        super.dispose();
    }

    // ham tao inputDecoration dung chung
    InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
        return InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: suffixIcon,
        );
    }

    // ham xu ly khi bam luu
    Future<void> _submit() async {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        // goi controller xu ly logic
        final ok = await _controller.submit(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            confirmPassword: _confirmController.text,
        );
        if (!mounted) return;

        if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Doi mat khau thanh cong.')),
            );

            // Quay ve man truoc
            Navigator.pop(context, true);
        }
    }

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        // lang nghe
        return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
                return Scaffold(
                    appBar: AppBar(title: const Text('Doi mat khau')),
                    body: SafeArea(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Form(
                                    key: _formKey,
                                    child: Column(
                                        children: [
                                            // mk hien tai
                                            TextFormField(
                                                controller: _currentController,
                                                obscureText: _obscureCurrent,
                                                decoration: _inputDecoration(
                                                    'Mat khau hien tai',
                                                    suffixIcon: IconButton(
                                                        icon: Icon(
                                                            _obscureCurrent
                                                                ? Icons.visibility_off
                                                                : Icons.visibility,
                                                        ),
                                                        onPressed: () {
                                                            setState(() {
                                                                _obscureCurrent = !_obscureCurrent;
                                                            });
                                                        },
                                                    ),
                                                ),
                                                validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                        return 'Vui long nhap mat khau hien tai';
                                                    }
                                                    return null;
                                                },
                                            ),
                                            const SizedBox(height: 16),
                                            // mk moi
                                            TextFormField(
                                                controller: _newController,
                                                obscureText: _obscureNew,
                                                decoration: _inputDecoration(
                                                    'Mat khau moi',
                                                    suffixIcon: IconButton(
                                                        icon: Icon(
                                                            _obscureNew
                                                                ? Icons.visibility_off
                                                                : Icons.visibility,
                                                        ),
                                                        onPressed: () {
                                                            setState(() {
                                                                _obscureNew = !_obscureNew;
                                                            });
                                                        },
                                                    ),
                                                ),
                                                validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                        return 'Vui long nhap mat khau moi';
                                                    }
                                                    if (value.length < 6) {
                                                        return 'Mat khau moi it nhat 6 ky tu';
                                                    }
                                                    return null;
                                                },
                                            ),
                                            const SizedBox(height: 16),

                                            // nhap lai mat khau moi
                                            TextFormField(
                                                controller: _confirmController,
                                                obscureText: _obscureConfirm,
                                                decoration: _inputDecoration(
                                                    'Nhap lai mat khau moi',
                                                    suffixIcon: IconButton(
                                                        icon: Icon(
                                                            _obscureConfirm
                                                                ? Icons.visibility_off
                                                                : Icons.visibility,
                                                        ),
                                                        onPressed: () {
                                                            setState(() {
                                                                _obscureConfirm = !_obscureConfirm;
                                                            });
                                                        },
                                                    ),
                                                ),
                                                validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                        return 'Vui long nhap lai mat khau moi';
                                                    }
                                                    if (value != _newController.text) {
                                                        return 'Mat khau moi khong trung khop';
                                                    }
                                                    return null;
                                                },
                                            ),
                                            // hien thi loi
                                            if (_controller.errorMessage != null) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                    _controller.errorMessage!,
                                                    style: TextStyle(color: theme.colorScheme.error),
                                                ),
                                            ],

                                            const SizedBox(height: 20),

                                            // nut luu
                                            SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                    onPressed:
                                                        _controller.isLoading ? null : _submit,
                                                    child: _controller.isLoading
                                                        ? const SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                            ),
                                                        )
                                                        : const Text('Luu'),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ),
                );
            },
        );
    }
}
