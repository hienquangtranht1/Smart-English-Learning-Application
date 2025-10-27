import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/email_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ctrl = TextEditingController();
  String? _status;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) { setState(() => _status = 'Nhập App Password'); return; }
    setState(() { _saving = true; _status = null; });
    final svc = Provider.of<EmailService>(context, listen: false);
    await svc.saveAppPassword(v);
    setState(() { _saving = false; _status = 'Lưu thành công'; _ctrl.clear(); });
  }

  Future<void> _remove() async {
    final svc = Provider.of<EmailService>(context, listen: false);
    await svc.removeAppPassword();
    setState(() => _status = 'Đã xóa mật khẩu ứng dụng');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt SMTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextFormField(controller: _ctrl, decoration: const InputDecoration(labelText: 'SMTP App Password'), obscureText: true),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Lưu'))),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _remove, child: const Text('Xóa mật khẩu đã lưu')),
          const SizedBox(height: 12),
          if (_status != null) Text(_status!, style: const TextStyle(color: Colors.green)),
          const SizedBox(height: 8),
          const Text('Lưu ý: dùng Gmail App Password; không commit vào repo.', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
