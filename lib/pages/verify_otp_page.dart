import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';

enum VerifyPurpose { register, reset }

class VerifyOtpPage extends StatefulWidget {
  final String identifier;
  final VerifyPurpose purpose;

  const VerifyOtpPage({
    super.key,
    required this.identifier,
    this.purpose = VerifyPurpose.register,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  String? _status;
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool v) => setState(() => _loading = v);
  void _setStatus(String? s) => setState(() => _status = s);

  Color _getStatusColor() {
    if (_status == null) return Colors.transparent;
    if (_status!.contains('thành công')) return Colors.green.shade700;
    if (_status!.contains('thất bại') || _status!.contains('Lỗi') || _status!.contains('hết hạn')) return Colors.red.shade700;
    return Colors.blue.shade700;
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final otp = _otpCtrl.text.trim();

    _setLoading(true);
    _setStatus(null);
    final auth = Provider.of<AuthService>(context, listen: false);

    bool ok = false;
    if (widget.purpose == VerifyPurpose.register) {
      ok = await auth.confirmRegisterOtp(username: widget.identifier, otp: otp);
      _setLoading(false);
      if (ok) {
        _setStatus('Xác thực thành công. Tài khoản đã được tạo.');
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        _setStatus('Xác thực thất bại hoặc OTP đã hết hạn.');
      }
    } else {
      final newPass = _newPassCtrl.text;
      if (newPass.isEmpty || newPass.length < 6) {
        _setLoading(false);
        _setStatus('Mật khẩu mới tối thiểu 6 ký tự');
        return;
      }

      ok = await auth.confirmResetOtp(username: widget.identifier, otp: otp, newPassword: newPass);
      _setLoading(false);
      if (ok) {
        _setStatus('Đổi mật khẩu thành công. Bạn có thể đăng nhập bằng mật khẩu mới.');
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        _setStatus('Xác thực OTP thất bại hoặc OTP đã hết hạn.');
      }
    }
  }

  Future<void> _resendOtp() async {
    _setLoading(true);
    _setStatus(null);
    final emailSvc = Provider.of<EmailService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    bool sent = false;
    if (widget.purpose == VerifyPurpose.register) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thực hiện lại bước đăng ký để nhận OTP mới.')),
      );
      return;
    } else {
      sent = await auth.requestResetOtp(usernameOrEmail: widget.identifier, emailService: emailSvc);
    }

    _setLoading(false);
    if (sent) {
      _setStatus('OTP đã được gửi lại. Kiểm tra email (bao gồm mục spam).');
    } else {
      _setStatus('Không thể gửi lại OTP. Kiểm tra cấu hình SMTP hoặc thông tin tài khoản.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReset = widget.purpose == VerifyPurpose.reset;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(isReset ? 'Đổi mật khẩu' : 'Đăng ký tài khoản')),
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
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isReset ? 'Xác thực OTP - Đổi mật khẩu' : 'Xác thực OTP - Đăng ký',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isReset
                              ? 'Nhập mã OTP gửi tới email của bạn để đổi mật khẩu.'
                              : 'Nhập mã OTP vừa được gửi tới email của bạn để hoàn tất đăng ký.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Mã OTP (6 số)',
                            prefixIcon: Icon(Icons.vpn_key),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.length != 6) ? 'Mã OTP phải có 6 chữ số' : null,
                        ),

                        if (isReset) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPassCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                              prefixIcon: const Icon(Icons.lock_reset),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu mới tối thiểu 6 ký tự' : null,
                          ),
                        ],

                        const SizedBox(height: 20),

                        if (_status != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(_status!,
                                style: TextStyle(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.w600
                                )
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: _loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.verified_user),
                            onPressed: _loading ? null : _confirm,
                            label: Text(isReset ? 'XÁC NHẬN VÀ ĐỔI MẬT KHẨU' : 'XÁC NHẬN OTP', style: const TextStyle(fontSize: 16)),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loading ? null : _resendOtp,
                          label: const Text('Gửi lại OTP'),
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