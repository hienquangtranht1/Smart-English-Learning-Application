import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import 'verify_otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập tên đăng nhập';
    if (v.trim().length < 3) return 'Tên đăng nhập tối thiểu 3 ký tự';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập email';
    final s = v.trim();
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (!emailRegex.hasMatch(s)) return 'Email không hợp lệ';
    return null;
  }

  void _setLoading(bool v) => setState(() => _loading = v);
  void _setError(String? m) => setState(() => _error = m);

  Future<void> _submit() async {
    _setError(null);
    if (!(_form.currentState?.validate() ?? false)) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final email = _emailCtrl.text.trim();

    _setLoading(true);

    try {
      final emailSvc = Provider.of<EmailService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);

      final ok = await auth.requestRegisterOtp(username: username, password: password, email: email, emailService: emailSvc);
      _setLoading(false);

      if (!ok) {
        _setError('Không thể tạo yêu cầu đăng ký. Tên đăng nhập có thể đã tồn tại hoặc email đã tồn tại.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VerifyOtpPage(identifier: username, purpose: VerifyPurpose.register)));
    } catch (e) {
      _setLoading(false);
      _setError('Lỗi khi gửi OTP. Vui lòng kiểm tra cài đặt SMTP và thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký Tài khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FOUR ROCK',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Học từ vựng, Vững kiến thức.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên đăng nhập (Tối thiểu 3 ký tự)',
                              prefixIcon: Icon(Icons.person_add),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateUsername
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu (Tối thiểu 6 ký tự)',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure)
                            ),
                          ),
                          obscureText: _obscure,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email (Cần thiết để nhận OTP)',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail
                        ),

                        const SizedBox(height: 20),

                        if (_error != null) ...[
                          Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                            onPressed: _loading ? null : _submit,
                            label: Text(_loading ? 'Đang gửi...' : 'GỬI MÃ XÁC THỰC (OTP)', style: const TextStyle(fontSize: 16)),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _loading ? null : () => Navigator.of(context).pop(),
                            label: const Text('Quay lại Đăng nhập')
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Mã OTP có hiệu lực trong 5 phút. Vui lòng kiểm tra cả hộp thư chính và mục Spam.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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