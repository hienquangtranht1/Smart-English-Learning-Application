import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _stageVerifyOld = true;
  bool _stageNewPass = false;
  bool _stageOtp = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  String? _status;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool v) => setState(() => _loading = v);
  void _setStatus(String? s) => setState(() => _status = s);

  Future<void> _verifyOldPassword() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final username = auth.currentUsername;
    final oldPass = _oldPassCtrl.text;
    if (username == null) {
      _setStatus('Lỗi: không có tài khoản đăng nhập.');
      return;
    }
    if (oldPass.isEmpty) {
      _setStatus('Nhập mật khẩu cũ');
      return;
    }

    _setLoading(true);
    _setStatus(null);

    final ok = await auth.login(username, oldPass);
    _setLoading(false);

    if (ok) {
      setState(() {
        _stageVerifyOld = false;
        _stageNewPass = true;
        _setStatus('Xác thực mật khẩu cũ thành công. Nhập mật khẩu mới.');
        _oldPassCtrl.clear();
      });
    } else {
      _setStatus('Mật khẩu cũ không đúng.');
    }
  }

  Future<void> _sendOtpForChange() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final emailSvc = Provider.of<EmailService>(context, listen: false);
    final username = auth.currentUsername;
    final newPass = _newPassCtrl.text;

    if (username == null) {
      _setStatus('Lỗi: không có tài khoản.');
      return;
    }
    if (newPass.isEmpty || newPass.length < 6) {
      _setStatus('Mật khẩu mới tối thiểu 6 ký tự.');
      return;
    }

    _setLoading(true);
    _setStatus(null);

    final sent = await auth.requestResetOtp(usernameOrEmail: username, emailService: emailSvc);
    _setLoading(false);

    if (sent) {
      setState(() {
        _stageNewPass = false;
        _stageOtp = true;
        _setStatus('OTP đã được gửi tới email liên kết. Nhập OTP để hoàn tất.');
      });
    } else {
      _setStatus('Không gửi được OTP. Kiểm tra cấu hình email hoặc tài khoản có email hay không.');
    }
  }

  Future<void> _confirmOtpAndChange() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final username = auth.currentUsername;
    final otp = _otpCtrl.text.trim();
    final newPass = _newPassCtrl.text;

    if (username == null) {
      _setStatus('Lỗi: không có tài khoản.');
      return;
    }
    if (otp.isEmpty) {
      _setStatus('Nhập OTP.');
      return;
    }
    if (newPass.isEmpty || newPass.length < 6) {
      _setStatus('Mật khẩu mới tối thiểu 6 ký tự.');
      return;
    }

    _setLoading(true);
    _setStatus(null);

    final ok = await auth.confirmResetOtp(username: username, otp: otp, newPassword: newPass);
    _setLoading(false);

    if (ok) {
      await auth.logout();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Thành công'),
          content: const Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    } else {
      _setStatus('Xác thực OTP thất bại hoặc OTP đã hết hạn.');
    }
  }

  Widget _buildVerifyOld() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Xác thực mật khẩu hiện tại', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _oldPassCtrl,
          obscureText: _obscureOld,
          decoration: InputDecoration(
            labelText: 'Mật khẩu hiện tại',
            suffixIcon: IconButton(
              icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureOld = !_obscureOld),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _verifyOldPassword,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Xác thực mật khẩu'),
        ),
      ],
    );
  }

  Widget _buildNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nhập mật khẩu mới', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: 'Tối thiểu 6 ký tự',
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _sendOtpForChange,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Gửi OTP để xác nhận'),
        ),
      ],
    );
  }

  Widget _buildOtpConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nhập mã OTP', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpCtrl,
          decoration: const InputDecoration(labelText: 'OTP'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _confirmOtpAndChange,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Xác nhận và đổi mật khẩu'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu an toàn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_stageVerifyOld) _buildVerifyOld(),
              if (_stageNewPass) _buildNewPassword(),
              if (_stageOtp) _buildOtpConfirm(),
              const SizedBox(height: 12),
              if (_status != null) Text(_status!, style: const TextStyle(color: Colors.blue)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                  setState(() {
                    _stageVerifyOld = true;
                    _stageNewPass = false;
                    _stageOtp = false;
                    _oldPassCtrl.clear();
                    _newPassCtrl.clear();
                    _otpCtrl.clear();
                    _setStatus(null);
                  });
                },
                child: const Text('Quay lại/Đặt lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
