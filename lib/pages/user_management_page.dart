import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> _users = [];
  bool _loading = true;
  String? _currentUsername;
  bool _currentIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final list = await auth.listUsers();

    final me = auth.currentUser;

    if (!mounted) return;
    list.sort((a, b) {
      if (a.isAdmin && !b.isAdmin) return -1;
      if (!a.isAdmin && b.isAdmin) return 1;
      return a.username.compareTo(b.username);
    });
    setState(() {
      _users = list;
      _loading = false;
      _currentUsername = me?.username;
      _currentIsAdmin = me?.isAdmin ?? false;
    });
  }

  Future<void> _toggleAdmin(User user) async {
    final auth = Provider.of<AuthService>(context, listen: false);

    if (user.username == _currentUsername) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Không thể thay đổi chính mình'),
          content: const Text('Bạn không thể thay đổi quyền của chính tài khoản đang đăng nhập.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng'))],
        ),
      );
      return;
    }

    if (!_currentIsAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không có quyền quản trị để thực hiện hành động này.')));
      return;
    }

    final action = user.isAdmin ? 'Thu hồi quyền Admin' : 'Đặt làm Admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: Text('Bạn có chắc chắn muốn $action cho tài khoản "${user.username}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(user.isAdmin ? 'Thu hồi' : 'Xác nhận')),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await auth.toggleAdmin(user.username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cập nhật quyền thành công' : 'Không thể cập nhật quyền')));
    }
    await _load();
  }

  Future<void> _removeUser(User user) async {
    if (user.username == _currentUsername) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Không thể xóa chính mình'),
          content: const Text('Bạn không thể xóa tài khoản đang đăng nhập.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng'))],
        ),
      );
      return;
    }

    if (!_currentIsAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không có quyền quản trị để thực hiện hành động này.')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận Xóa Tài khoản', style: TextStyle(color: Colors.red)),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn tài khoản "${user.username}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.removeUser(user.username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Đã xóa tài khoản' : 'Không thể xóa (Có thể là admin duy nhất)')));
    }
    await _load();
  }

  Widget _buildRoleChip(bool isAdmin) {
    return Chip(
      label: Text(isAdmin ? 'ADMIN' : 'USER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: isAdmin ? Colors.red.shade100 : Colors.green.shade100,
      labelStyle: TextStyle(color: isAdmin ? Colors.red.shade800 : Colors.green.shade800),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildUserTile(User u) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: u.isAdmin ? Colors.red.shade400 : Colors.blueGrey.shade400,
        child: Icon(u.isAdmin ? Icons.shield_sharp : Icons.person, color: Colors.white),
      ),
      title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: _buildRoleChip(u.isAdmin),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(u.isAdmin ? Icons.star : Icons.star_border, color: u.isAdmin ? Colors.orange : Colors.grey),
            tooltip: u.isAdmin ? 'Thu hồi quyền Admin' : 'Đặt làm Admin',
            onPressed: () => _toggleAdmin(u),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa tài khoản',
            onPressed: () => _removeUser(u),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Tải lại danh sách'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _users.isEmpty
            ? const Center(child: Text('Không có tài khoản nào được tạo.'))
            : ListView.separated(
          itemCount: _users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, i) {
            final u = _users[i];
            return _buildUserTile(u);
          },
        ),
      ),
    );
  }
}
