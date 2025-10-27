import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EmailService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<String?> _getAppPassword() async {
    final stored = await _secure.read(key: 'SMTP_APP_PASSWORD');
    if (stored != null && stored.isNotEmpty) return stored;
    final env = dotenv.env['SMTP_APP_PASSWORD'];
    if (env != null && env.isNotEmpty) return env;
    return null;
  }

  Future<void> saveAppPassword(String pwd) async => await _secure.write(key: 'SMTP_APP_PASSWORD', value: pwd);
  Future<void> removeAppPassword() async => await _secure.delete(key: 'SMTP_APP_PASSWORD');

  SmtpServer _buildSmtp(String user, String pass) {
    final host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
    final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
    return SmtpServer(host, port: port, username: user, password: pass, ignoreBadCertificate: false, ssl: false);
  }

  Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    try {
      final user = dotenv.env['SMTP_USER'];
      final from = dotenv.env['SMTP_FROM'] ?? user;
      final pass = await _getAppPassword();
      if (user == null || from == null || pass == null) return false;
      final smtp = _buildSmtp(user, pass);
      final msg = Message()
        ..from = Address(from)
        ..recipients.add(toEmail)
        ..subject = subject
        ..text = body;
      await send(msg, smtp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendOtpMail({required String toEmail, required String otp, int ttlMinutes = 5}) {
    final subject = 'Mã OTP xác nhận';
    final body = 'Mã OTP của bạn là: $otp\nMã có hiệu lực $ttlMinutes phút.';
    return sendEmail(toEmail: toEmail, subject: subject, body: body);
  }
}
