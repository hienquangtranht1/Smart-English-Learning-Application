import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class DeletedPage extends StatefulWidget {
  const DeletedPage({super.key});
  @override
  State<DeletedPage> createState() => _DeletedPageState();
}

class _DeletedPageState extends State<DeletedPage> {
  final StorageService _storage = StorageService();
  List<String> _deletedIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ids = await _storage.loadDeletedIds();
      if (!mounted) return;
      setState(() {
        _deletedIds = ids;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deletedIds = [];
        _loading = false;
      });
    }
  }

  Future<void> _restore(String id) async {
    final ids = await _storage.loadDeletedIds();
    ids.removeWhere((e) => e == id);
    await _storage.saveDeletedIds(ids);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã khôi phục id')));
  }

  Future<void> _clearAll() async {
    await _storage.saveDeletedIds([]);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh sách id đã xóa')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách id đã xóa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deletedIds.isEmpty
                ? null
                : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Xóa toàn bộ danh sách id đã xóa?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
                    ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
                  ],
                ),
              );
              if (ok == true) await _clearAll();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deletedIds.isEmpty
          ? const Center(child: Text('Không có id đã xóa'))
          : ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _deletedIds.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, idx) {
          final id = _deletedIds[idx];
          return ListTile(
            title: Text(id),
            trailing: TextButton(
              onPressed: () => _restore(id),
              child: const Text('Khôi phục'),
            ),
          );
        },
      ),
    );
  }
}
