import 'package:flutter/material.dart';
import '../models/vocab.dart';
import '../services/storage_service.dart';
import 'deleted_page.dart';
import 'edited_page.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final StorageService _storage = StorageService();
  List<Vocab> _userVocab = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await _storage.loadUserVocab();
      if (!mounted) return;
      setState(() {
        _userVocab = user;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userVocab = [];
        _loading = false;
      });
    }
  }

  Future<void> _clearUserVocab() async {
    await _storage.saveUserVocab([]);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ từ do người dùng thêm')));
  }

  Widget _buildItem(Vocab v) {
    return ListTile(
      title: Text(v.en),
      subtitle: Text(v.vi),
      trailing: Text(v.userAdded ? 'user' : 'base', style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý dữ liệu'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Từ do người dùng thêm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: _userVocab.isEmpty
                  ? const Center(child: Text('Chưa có từ do người dùng thêm'))
                  : ListView.separated(
                itemCount: _userVocab.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _buildItem(_userVocab[i]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _userVocab.isEmpty ? null : _clearUserVocab,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Xóa tất cả từ người dùng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeletedPage())),
                    icon: const Icon(Icons.delete),
                    label: const Text('Deleted ids'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditedPage())),
              icon: const Icon(Icons.edit),
              label: const Text('Edited log'),
            ),
          ],
        ),
      ),
    );
  }
}
