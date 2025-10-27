import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _status;
  Color _statusColor = Colors.green;
  bool _revealEmail = false;

  Future<void> _openResetPasswordPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công qua OTP. Vui lòng đăng nhập lại.')));
      await _logout(silent: true);
    }
  }

  Future<void> _logout({bool silent = false}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();
    if (!mounted) return;

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất thành công.')));
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];

    String maskedLocal;
    if (local.length <= 1) {
      maskedLocal = '*' ;
    } else if (local.length == 2) {
      maskedLocal = local[0] + '*';
    } else if (local.length <= 4) {
      final stars = List.filled(local.length - 1, '*').join();
      maskedLocal = local[0] + stars;
    } else {
      final stars = List.filled(local.length - 3, '*').join();
      maskedLocal = local.substring(0,2) + stars + local.substring(local.length - 1);
    }

    final domainParts = domain.split('.');
    if (domainParts.length >= 2) {
      final name = domainParts.first;
      final tld = domainParts.sublist(1).join('.');
      String maskedName;
      if (name.length <= 2) {
        maskedName = name[0] + '*';
      } else {
        final stars = List.filled((name.length - 2).clamp(1, name.length), '*').join();
        maskedName = name[0] + stars + name.substring(name.length - 1);
      }
      return '$maskedLocal@${maskedName}.$tld';
    }

    return '$maskedLocal@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final username = auth.currentUsername ?? 'Khách (Chưa đăng nhập)';
    final isAdmin = auth.isAdmin;
    final theme = Theme.of(context);
    final rawEmail = auth.currentUser?.email ?? '';
    final displayEmail = _revealEmail ? rawEmail : _maskEmail(rawEmail);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tài khoản hiện tại', style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor)),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueGrey),
                  title: const Text('Tên đăng nhập'),
                  subtitle: Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blueGrey),
                  title: const Text('Email đã đăng ký'),
                  subtitle: Text(displayEmail.isEmpty ? 'Chưa có email' : displayEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: rawEmail.isEmpty
                      ? null
                      : IconButton(
                    icon: Icon(_revealEmail ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
                    onPressed: () => setState(() => _revealEmail = !_revealEmail),
                    tooltip: _revealEmail ? 'Ẩn email' : 'Hiện email',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blueGrey),
                  title: const Text('Vai trò'),
                  trailing: Chip(
                    label: Text(isAdmin ? "ADMIN" : "USER"),
                    backgroundColor: isAdmin ? Colors.red.shade100 : Colors.green.shade100,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.red.shade800 : Colors.green.shade800),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Đổi mật khẩu', style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor)),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Sử dụng email/OTP để đặt lại mật khẩu nếu bạn quên mật khẩu hoặc muốn thay đổi an toàn.'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openResetPasswordPage,
                    icon: const Icon(Icons.email, color: Colors.blue),
                    label: const Text('Đổi mật khẩu qua Email/OTP', style: TextStyle(color: Colors.blue)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: Colors.blue.shade100)),
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.deepOrange),
              label: const Text('Đăng xuất khỏi thiết bị', style: TextStyle(color: Colors.deepOrange)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.deepOrange.shade200),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
